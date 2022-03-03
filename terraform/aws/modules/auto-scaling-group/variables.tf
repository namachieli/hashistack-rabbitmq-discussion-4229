# /terraform/aws/modules/auto-scaling-group
# ------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------

variable "asg_name" {
  description = "The name of the ASG"
  type        = string
}

variable "environment" {
  description = "The environment that this module is being deployed for"
  type        = string
}

variable "ami_id" {
  description = "The ID of the AMI that should be launched and configured"
  type        = string
}

variable "instance_type" {
  description = "The type of instance (ex: t2.micro) that should be launched"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC resources should be deployed in to"
  type        = string
}

variable "ssh_key_name" {
  description = "The name of the SSH Key in AWS that should be applied to EC2 instances created"
  type        = string
}

variable "vpc_subnet_ids" {
  description = "The subnet IDs to be used to spread resources across in the region"
  type        = list(string)
}

variable "vpc_sg_ids" {
  description = "The security group IDs to be applied to instances in the ASG"
  type        = list(string)
}

variable "iam_instance_profile_arn" {
  description = "The IAM Instance Profile ARN to be applied to instances in the ASG"
  type        = string
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

variable "asg_max_size" {
  description = "The maximum number of instances to allow in the ASG"
  type        = number
  default     = 5
}

variable "asg_min_size" {
  description = "The minimum number of instances to allow in the ASG"
  type        = number
  default     = 3
}

variable "asg_desired_size" {
  description = "The desired number of instances to target for the ASG"
  type        = number
  default     = 3
}

variable "static_tags" {
  description = "Additional Static Tags to be added to instances"
  type        = list(any)
  default = [
    {
      key                 = "Description"
      value               = "An ASG instance"
      propagate_at_launch = true
    }
  ]
}

variable "extra_tags" {
  description = "Additional Dynamic Tags to be added to instances"
  type        = list(any)
  default     = []
}

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------
