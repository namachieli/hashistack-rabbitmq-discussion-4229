# /terraform
# ------------------------------------------------------------------------------------------------
# REQUIRED GLOBAL PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------
variable "environment" {
  description = "The environment that is being deployed."
  type        = string
  default     = "test"
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------
