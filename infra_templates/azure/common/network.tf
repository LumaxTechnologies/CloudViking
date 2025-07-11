resource "azurerm_resource_group" "main" {
  name     = "${local.common_prefix_dash}-rg"
  location = var.region
}

resource "azurerm_virtual_network" "main" {
  name                = "${local.common_prefix_dash}-vnet"
  address_space       = [var.vpc_cidr]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_labels
}

resource "azurerm_subnet" "public" {
  name                 = "${local.common_prefix_dash}-public-subnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnet_cidr]
}

resource "azurerm_public_ip" "nat" {
  name                = "${local.common_prefix_dash}-nat-ip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_labels
}

resource "azurerm_nat_gateway" "nat" {
  name                = "${local.common_prefix_dash}-nat"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"

  tags = local.common_labels
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}
