######################
# SSH Keys
######################

resource "aws_key_pair" "public_key_import" {
  for_each = var.ssh_keys
  key_name   = format("%s-%s-%s-key", var.customer, var.environment, each.key)
  # key_name   = format("%s_key", each.key)
  public_key = file(format("%s/id_%s.pub", var.ssh_keys_folder, each.value.name))
}