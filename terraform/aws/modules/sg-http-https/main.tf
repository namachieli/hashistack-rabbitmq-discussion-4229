# /terraform/aws/modules/sg-http-https
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

resource "aws_security_group" "consumer_access" {
  name_prefix = "consumer_access-${var.environment}_"
  description = "Consumer Access (${var.environment})"
  vpc_id      = var.vpc_id
  tags = {
    Name = "consumer_access-${var.environment}"
  }
}

# ------------------------------------------------------------------------------------------------
# SECURITY GROUP RULES
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# ------------------------------------------------------------------------------------------------

#
# Consumer Access
#
resource "aws_security_group_rule" "http" {
  security_group_id = aws_security_group.consumer_access.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.access_http_port
  to_port           = var.access_http_port
  prefix_list_ids = [
    var.internal_v4_pl_id,
  ]
}

resource "aws_security_group_rule" "https" {
  security_group_id = aws_security_group.consumer_access.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = var.access_https_port
  to_port           = var.access_https_port
  prefix_list_ids = [
    var.internal_v4_pl_id,
  ]
}
