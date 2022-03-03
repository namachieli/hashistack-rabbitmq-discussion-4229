# /terraform/aws/modules/https-alb
# ------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.4"
}

# ------------------------------------------------------------------------------------------------
# LOAD BALANCER
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb
# ------------------------------------------------------------------------------------------------

# Main Load Blancer
resource "aws_lb" "this" {
  name               = var.alb_name
  internal           = true
  security_groups    = concat([aws_security_group.this.id], var.alb_sg_ids)
  load_balancer_type = "application"
  subnets            = var.alb_subnet_ids
  tags = {
    Name        = var.alb_name
    Description = var.alb_name
  }
  lifecycle {
    create_before_destroy = true
  }
}

# ------------------------------------------------------------------------------------------------
# LISTENER
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener
# ------------------------------------------------------------------------------------------------

# HTTPS Listener
resource "aws_lb_listener" "HTTPS" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn
  # certificate_arn   = aws_acm_certificate.this.arn
  default_action {
    target_group_arn = aws_lb_target_group.this.arn
    type             = "forward"
  }
}

# Listener to redirect HTTP -> HTTPS
resource "aws_lb_listener" "HTTP-redirect" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = 443
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ------------------------------------------------------------------------------------------------
# TARGET GROUP
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group
# ------------------------------------------------------------------------------------------------


# Target group for load balancer pool
resource "aws_lb_target_group" "this" {
  name_prefix = "${var.target_group_port}-"
  target_type = "instance"
  vpc_id      = var.vpc_id
  port        = var.target_group_port
  protocol    = var.target_group_protocol
  tags = {
    Name        = aws_lb.this.name
    Description = aws_lb.this.name
  }
  health_check {
    enabled             = var.hc_enabled
    healthy_threshold   = var.hc_healthy_threshold
    interval            = var.hc_interval
    matcher             = var.hc_matcher
    path                = var.hc_path
    port                = var.hc_port
    protocol            = var.hc_protocol
    timeout             = var.hc_timeout
    unhealthy_threshold = var.hc_unhealthy_threshold
  }
  lifecycle {
    create_before_destroy = true
  }
}
