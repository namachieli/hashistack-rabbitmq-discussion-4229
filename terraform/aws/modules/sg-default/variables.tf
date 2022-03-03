# /terraform/aws/modules/sg-default
# ------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------

variable "environment" {
  description = "The environment that this module is being deployed for"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC resources should be deployed in to"
  type        = string
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS (Ports)
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

variable "admin_ssh_port" {
  description = "The port used by admins to access ssh"
  type        = number
  default     = 22
}

variable "rabbitmq_amqp_port" {
  type    = number
  default = 5672
}

variable "rabbitmq_ui_port" {
  type    = number
  default = 15672
}

variable "rabbitmq_epmd_port" {
  type    = number
  default = 25672
}

variable "rabbitmq_internode_port" {
  type    = number
  default = 4369
}

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------
