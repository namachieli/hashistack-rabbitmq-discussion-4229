# /terraform/aws
# ------------------------------------------------------------------------------------------------
# OUTPUTS
# https://www.terraform.io/language/values/outputs
# ------------------------------------------------------------------------------------------------

output "regional_dns" {
  description = "The DNS Record created to represent the region"
  sensitive   = false
  value       = aws_route53_record.region.name
}

output "nomad_ui_dns" {
  description = "The DNS Record created to access nomad"
  sensitive   = false
  value       = aws_route53_record.region.name
}
