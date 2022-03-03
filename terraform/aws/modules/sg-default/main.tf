# /terraform/aws/modules/sg-default
# ------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.4"
}

# ------------------------------------------------------------------------------------------------
# SECURITY GROUP
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# ------------------------------------------------------------------------------------------------

# Effective Default, not literal. "Default Security Group" is a specific thing, that this is not.
resource "aws_security_group" "default" {
  name_prefix = "default_access-${var.environment}_"
  description = "Default Access (${var.environment})"
  vpc_id      = var.vpc_id
  tags = {
    Name = "default_access-${var.environment}"
  }
}

# ------------------------------------------------------------------------------------------------
# SECURITY GROUP RULES
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# ------------------------------------------------------------------------------------------------

#
# Admin Access
#
resource "aws_security_group_rule" "ssh" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.admin_ssh_port
  to_port           = var.admin_ssh_port
  prefix_list_ids = [
    aws_ec2_managed_prefix_list.internal_v4.id,
  ]
}

#
# Wide Allows
#
resource "aws_security_group_rule" "outbound_allow_all" {
  security_group_id = aws_security_group.default.id
  type              = "egress"
  protocol          = "-1"
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "rabbitmq_amqp_ingress" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.rabbitmq_amqp_port
  to_port           = var.rabbitmq_amqp_port
  cidr_blocks = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]
}

resource "aws_security_group_rule" "rabbitmq_ui_ingress" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.rabbitmq_ui_port
  to_port           = var.rabbitmq_ui_port
  cidr_blocks = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]
}

resource "aws_security_group_rule" "rabbitmq_epmd_self" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.rabbitmq_epmd_port
  to_port           = var.rabbitmq_epmd_port
  self              = true
}

resource "aws_security_group_rule" "rabbitmq_internode_self" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.rabbitmq_internode_port
  to_port           = var.rabbitmq_internode_port
  self              = true
}

# https://blog.jwr.io/terraform/icmp/ping/security/groups/2018/02/02/terraform-icmp-rules.html
resource "aws_security_group_rule" "icmp_any" {
  security_group_id = aws_security_group.default.id
  type              = "ingress"
  protocol          = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_blocks = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16"
  ]
}
