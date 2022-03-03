# /terraform/aws/modules/sg-http-https
# ------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------

# MVP: Can this be restricted to an enumerated list?
variable "environment" {
  description = "The environment that this module is being deployed for"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC resources should be deployed in to"
  type        = string
}

# MVP: TODO: Rework this to be generic. "The PL" not "The Internal PL"
variable "internal_v4_pl_id" {
  description = "The ID of the Prefix List for 'Internal' IPv4"
  type        = string
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

variable "access_http_port" {
  description = "The port used to access HTTP" # Redirected to HTTPS via NGINX Reverse Proxy
  type        = number
  default     = 80
}

variable "access_https_port" {
  description = "The port used to access HTTPS"
  type        = number
  default     = 443
}

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------
