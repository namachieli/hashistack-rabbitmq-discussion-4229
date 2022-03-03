# /terraform
# ------------------------------------------------------------------------------------------------
# REQUIRED AWS PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------

variable "runtime_server_ami_id" {
  description = "The ID of the AWS AMI that should be launched for runtime (Server)"
  type        = string
}

variable "runtime_client_ami_id" {
  description = "The ID of the AWS AMI that should be launched for runtime (Client)"
  type        = string
}

variable "ssh_key_name" {
  description = "The name of the SSH Key in AWS that should be applied to EC2 instances created"
  type        = string
}

variable "vpc_ids" {
  description = "A map of k:v representing VPC ids per region and Environment. Formatted {region.env: vpc_id}"
  type        = map(any)
  # referenced by # /terraform/aws/variables.tf locals.vpc_id
  # Either pass it, or just uncomment the default below
  # default = {"us-west-2.test" = "PUT A VPC ID HERE"}
}

variable "r53_zone_id" {
  description = "The Route53 Zone ID for the domain/zone that should be used for DNS records"
  type        = string
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL AWS PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

variable "add_default_aws_tags" {
  description = "Additional tags to include in 'Provider Default Tags'"
  type        = map(any)
  default     = {}
}

variable "runtime_server_instance_type" {
  description = "The type of instance for server nodes"
  type        = string
  default     = "t2.small"
}

variable "runtime_client_instance_type" {
  description = "The type of instance for client nodes"
  type        = string
  default     = "t2.large"
}

# ------------------------------------------------------------------------------------------------
# AWS PROVIDERS
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs
# Refferenced by calling provder.alias (aws.us-west-2)
# ------------------------------------------------------------------------------------------------

provider "aws" {
  alias                   = "us-west-2"
  region                  = "us-west-2"
  shared_credentials_file = "~/.aws/credentials"
  profile                 = "saml"
  default_tags { tags = local.default_aws_tags }
}

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------

# Default tags defined by the provider
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs#default_tags-configuration-block
locals {
  default_aws_tags = merge(
    {
      "Environment" = var.environment
      "Terraform"   = true
    },
    var.add_default_aws_tags
  )
}
