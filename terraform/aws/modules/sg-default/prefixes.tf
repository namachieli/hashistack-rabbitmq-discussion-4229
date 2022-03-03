# /terraform/aws/modules/sg-default
# ------------------------------------------------------------------------------------------------
# PREFIX LISTS
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_managed_prefix_list_entry
# https://docs.aws.amazon.com/vpc/latest/userguide/managed-prefix-lists.html
# ------------------------------------------------------------------------------------------------

#
# CIDRs considered to be "Internal"
#
resource "aws_ec2_managed_prefix_list" "internal_v4" {
  name           = "internal_v4"
  address_family = "IPv4"
  max_entries    = 20

  entry {
    cidr        = "10.0.0.0/8"
    description = "IPv4 RFC 1918 10.0.0.0/8"
  }

  entry {
    cidr        = "172.16.0.0/12"
    description = "IPv4 RFC 1918 172.16.0.0/12"
  }

  entry {
    cidr        = "192.168.0.0/16"
    description = "IPv4 RFC 1918 192.168.0.0/16"
  }

  lifecycle {
    ignore_changes = [version]
  }
}
