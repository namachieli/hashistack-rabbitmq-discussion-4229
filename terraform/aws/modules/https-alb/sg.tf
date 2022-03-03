# /terraform/aws/modules/https-alb
# ------------------------------------------------------------------------------------------------
# SECURITY GROUP
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group
# ------------------------------------------------------------------------------------------------

resource "aws_security_group" "this" {
  name_prefix = "${var.alb_name}_"
  description = "Members of ALB ${var.alb_name}"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.alb_name}"
  }
}

# ------------------------------------------------------------------------------------------------
# SECURITY GROUP RULES
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule
# ------------------------------------------------------------------------------------------------

#
# LB Member Access
#
resource "aws_security_group_rule" "tcp" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "tcp"
  from_port         = 0
  to_port           = 65535
  self              = true
}

resource "aws_security_group_rule" "udp" {
  security_group_id = aws_security_group.this.id
  type              = "ingress"
  protocol          = "udp"
  from_port         = 0
  to_port           = 65535
  self              = true
}
