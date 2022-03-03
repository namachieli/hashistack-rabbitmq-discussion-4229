# /terraform/aws/modules/auto-scaling-group
# ------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.4"
}

#-------------------------------------------------------------------------------------------------
# AUTO SCALING GROUP (ASG)
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group
# ------------------------------------------------------------------------------------------------

resource "aws_autoscaling_group" "this" {
  name_prefix         = "${var.asg_name}-${var.environment}_"
  max_size            = var.asg_max_size
  min_size            = var.asg_min_size
  desired_capacity    = var.asg_desired_size
  vpc_zone_identifier = var.vpc_subnet_ids

  tags = concat(
    [
      {
        key                 = "Name"
        value               = var.asg_name
        propagate_at_launch = true
      },
      {
        key                 = "Environment"
        value               = var.environment
        propagate_at_launch = true
      }
    ],
    var.static_tags,
    var.extra_tags
  )

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes = [
      target_group_arns,
    ]
  }

}

# ------------------------------------------------------------------------------------------------
# LAUNCH TEMPLATE
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template
# ------------------------------------------------------------------------------------------------

resource "aws_launch_template" "this" {
  name_prefix            = "${var.asg_name}-${var.environment}_"
  image_id               = var.ami_id
  description            = "The launch template for configuring instances for the ASG"
  instance_type          = var.instance_type
  vpc_security_group_ids = var.vpc_sg_ids
  key_name               = var.ssh_key_name

  iam_instance_profile {
    arn = var.iam_instance_profile_arn
  }

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required"
    instance_metadata_tags = "enabled"
  }

  lifecycle {
    create_before_destroy = true
  }
}
