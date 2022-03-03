# /terraform/aws/data
# ------------------------------------------------------------------------------------------------
# REGION DATA
# ------------------------------------------------------------------------------------------------

data "aws_vpc" "selected" {
  id = local.vpc_id
}

data "aws_subnet_ids" "selected" {
  vpc_id = data.aws_vpc.selected.id
  filter {
    name   = "tag:Environment"
    values = [var.environment, "test"]
  }
}

data "aws_region" "current" {}

data "aws_route53_zone" "selected" {
  zone_id = var.r53_zone_id
}

# ------------------------------------------------------------------------------------------------
# IAM POLICY DOCUMENTS
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document
# ------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "asg_describe" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
    ]

    resources = ["*"]
  }
}

