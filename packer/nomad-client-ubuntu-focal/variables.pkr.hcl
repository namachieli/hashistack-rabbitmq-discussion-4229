# ------------------------------------------------------------------------------------------------
# REQUIRED GLOBAL PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------
variable "vpc_id" {
  type = string
}

# Just create a SG that allows any/any, pass it as `['sg-1234asdf']`
variable "ec2_sg_id" {
  description = "The id of the Security Group applied to the instance created by packer to build the AMI"
  type        = string
}

# https://learn.hashicorp.com/tutorials/consul/gossip-encryption-secure
variable "gossip_key" {
  type      = string
  sensitive = true
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

variable "ami_prefix" {
  type    = string
  default = "nomad-client-ubuntu-focal"
}

variable "shared_credentials_file" {
  type    = string
  default = "~/.aws/credentials"
}

variable "shared_credentials_profile" {
  type    = string
  default = "saml"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

variable "instance_type" {
  type    = string
  default = "t2.medium"
}

variable "skip_create_ami" {
  type    = bool
  default = false
}

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}
