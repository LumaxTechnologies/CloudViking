###############################################################################
# SECURITY GROUPS (Placeholders – modify ingress rules as needed)
###############################################################################
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "${local.common_prefix_dash}-bastion-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Add other rules similarly
}

resource "azurerm_network_security_group" "jumpbox_nsg" {
  name                = "${local.common_prefix_dash}-jumpbox-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "backend_nsg" {
  name                = "${local.common_prefix_dash}-proxy-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 103
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

###############################################################################
# NETWORK INTERFACES
###############################################################################
resource "azurerm_public_ip" "bastion" {
  name                = "${local.common_prefix_dash}-bastion-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard" # Optional, depends on your needs
  tags                = local.common_labels
}

resource "azurerm_network_interface" "bastion_nic" {
  name                = "${local.common_prefix_dash}-bastion-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.bastion.id
  }

}

resource "azurerm_network_interface" "jumpbox_nic" {
  name                = "${local.common_prefix_dash}-jumpbox-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
  }

}

resource "azurerm_network_interface" "backend_nic" {
  for_each = { for vm in var.medium_vms: vm.name => vm}
  name                = "${local.common_prefix_dash}-${each.key}-nic"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-%s", var.customer, var.environment, each.value.name)
    },
    {
      Type = each.value.name
    }
  )

}

###############################################################################
# SECURITY GROUPS ASSOCIATION
###############################################################################
resource "azurerm_network_interface_security_group_association" "bastion_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.bastion_nic.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

resource "azurerm_network_interface_security_group_association" "jumpbox_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.jumpbox_nic.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

resource "azurerm_network_interface_security_group_association" "backend_nic_nsg_assoc" {
  for_each = { for vm in var.medium_vms: vm.name => vm}
  network_interface_id      = azurerm_network_interface.backend_nic[each.key].id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

###############################################################################
# VMS
###############################################################################
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = "${local.common_prefix_dash}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  network_interface_ids = [
    azurerm_network_interface.bastion_nic.id
  ]

  size = var.bastion_type

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(format("%s/id_%s.pub", var.ssh_keys_folder, var.customer))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${local.common_prefix_dash}-bastion-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  disable_password_authentication = true

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-bastion", var.customer, var.environment)
    },
    {
      Type = "bastion"
    }
  )
}

resource "azurerm_linux_virtual_machine" "jumpbox" {
  name                = "${local.common_prefix_dash}-jumpbox"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  network_interface_ids = [
    azurerm_network_interface.jumpbox_nic.id
  ]

  size = var.jumpbox_type

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(format("%s/id_%s.pub", var.ssh_keys_folder, var.customer))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "${local.common_prefix_dash}-jumpbox-osdisk"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  disable_password_authentication = true

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-jumpbox", var.customer, var.environment)
    },
    {
      Type = "jumpbox"
    }
  )
}

resource "azurerm_linux_virtual_machine" "backend" {
  for_each = { for vm in var.medium_vms: vm.name => vm}
  name                = "${local.common_prefix_dash}-${each.value.name}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  network_interface_ids = [
    azurerm_network_interface.backend_nic[each.key].id
  ]

  size = each.value.instance_type


  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file(format("%s/id_%s.pub", var.ssh_keys_folder, var.customer))
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = each.value.volume_type
    name                 = "${local.common_prefix_dash}-${each.value.name}-osdisk"
    disk_size_gb = each.value.volume_size
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  disable_password_authentication = true

  tags = merge(
    local.common_labels,
    {
      Name = format("%s-%s-%s", var.customer, var.environment, each.value.name)
    },
    {
      Type = each.value.name
    }
  )
}
