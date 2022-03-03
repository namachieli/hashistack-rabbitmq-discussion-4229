# /terraform/aws/modules/certificate-tls-public
# ------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------

variable "cert_cn" {
  description = "The primary name the cert is for"
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
variable "cert_san_list" {
  description = "A List of strings to include in the SAN list of the HTTPS Certificate created for this LB"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------
