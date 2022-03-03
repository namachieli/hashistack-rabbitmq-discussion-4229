# /terraform/aws
# ------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------
variable "environment" {
  description = "The environment that this module is being deployed for"
  type        = string
}

variable "vpc_ids" {
  description = "A map of k:v representing VPC ids per region and Environment. Formatted {region.env: vpc_id}"
  type        = map(any)
}

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

variable "r53_zone_id" {
  description = "The Route53 Zone ID for the domain/zone that should be used for DNS records"
  type        = string
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

variable "runtime_server_asg_name" {
  description = "The name of the ASG created for runtime servers"
  type        = string
  default     = "runtime-server"
}

variable "runtime_client_asg_name" {
  description = "The name of the ASG created for runtime clients"
  type        = string
  default     = "runtime-client"
}

variable "runtime_server_instance_type" {
  description = "The type of instance (ex: t2.micro) that should be launched for runtime (Server)"
  type        = string
  default     = "t2.small"
}


variable "runtime_client_instance_type" {
  description = "The type of instance (ex: t2.micro) that should be launched for runtime (Client)"
  type        = string
  default     = "t2.medium"
}

# ------------------------------------------------------------------------------------------------
# MVP ONLY PARAMETERS
# If you still need these after MVP, you missed something.
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------

# The subnet IDs to be used to spread resources across the region
locals {
  vpc_subnet_ids = data.aws_subnet_ids.selected.ids
}

# Lookup the VPC ID according to the combination of Region and Env
locals {
  vpc_id = lookup(var.vpc_ids, "${data.aws_region.current.name}.${var.environment}")
}

# Make DNS locals easier to read
locals {
  dns_env_base    = "${var.environment}.${data.aws_route53_zone.selected.name}"
  dns_region_base = "${data.aws_region.current.name}.${local.dns_env_base}"
}

# Referenced by the regional.env certificate
locals {
  region_cert_name = local.dns_region_base
  region_cert_san_list = [
    local.dns_env_base, # So you can access this region by environment in DNS LB Logic
    local.dns_region_base,
    local.nomad_ui_dns_name, # So we can reuse the same cert for the Nomad UI ALB
    local.consul_ui_dns_name # So we can reuse the same cert for the Consul UI ALB
  ]
}

# Names for the "regional" DNS records for this region.env
locals {
  region_dns_name    = local.dns_region_base
  nomad_ui_dns_name  = "nomad.${local.region_dns_name}"
  consul_ui_dns_name = "consul.${local.region_dns_name}"
}
