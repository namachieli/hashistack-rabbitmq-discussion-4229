# /terraform
# ------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# ------------------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.4"
}

# ------------------------------------------------------------------------------------------------
# AWS
# ------------------------------------------------------------------------------------------------

module "us-west-2" {
  source    = "./aws"
  providers = { aws = aws.us-west-2 }

  # Module Input Variables
  environment                  = var.environment
  runtime_server_ami_id        = var.runtime_server_ami_id
  runtime_server_instance_type = var.runtime_server_instance_type
  runtime_client_ami_id        = var.runtime_client_ami_id
  runtime_client_instance_type = var.runtime_client_instance_type
  vpc_ids                      = var.vpc_ids
  ssh_key_name                 = var.ssh_key_name
  r53_zone_id                  = var.r53_zone_id
}
