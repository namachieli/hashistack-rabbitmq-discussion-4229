# /terraform/aws
# ------------------------------------------------------------------------------------------------
# PROVIDER
# https://www.terraform.io/language/providers
# ------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 1.1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.74.0"
    }
  }
}
