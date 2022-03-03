# /terraform/aws/modules/sg-runtime-nomad-consul
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

resource "aws_security_group" "this" {
  name_prefix = "runtime-${var.environment}_"
  description = "Runtime Layer (${var.environment})"
  vpc_id      = var.vpc_id
  tags = {
    Name = "runtime-${var.environment}"
  }
}

# ------------------------------------------------------------------------------------------------
# SECURITY GROUP RULES
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# ------------------------------------------------------------------------------------------------

# Consul
resource "aws_security_group_rule" "consul_rpc_port_self_tcp" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.consul_rpc_port
  to_port           = var.consul_rpc_port
  self              = true
}

resource "aws_security_group_rule" "consul_serf_lan_port_self_tcp" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.consul_serf_lan_port
  to_port           = var.consul_serf_lan_port
  self              = true
}

resource "aws_security_group_rule" "consul_serf_lan_port_self_udp" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "udp"
  from_port         = var.consul_serf_lan_port
  to_port           = var.consul_serf_lan_port
  self              = true
}

# Nomad
resource "aws_security_group_rule" "nomad_rpc_port_self_tcp" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.nomad_rpc_port
  to_port           = var.nomad_rpc_port
  self              = true
}

resource "aws_security_group_rule" "nomad_serf_port_self_tcp" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.nomad_serf_port
  to_port           = var.nomad_serf_port
  self              = true
}

resource "aws_security_group_rule" "nomad_serf_port_self_udp" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "udp"
  from_port         = var.nomad_serf_port
  to_port           = var.nomad_serf_port
  self              = true
}
