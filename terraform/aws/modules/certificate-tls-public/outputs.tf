# /terraform/aws/modules/certificate-tls-public
# ------------------------------------------------------------------------------------------------
# OUTPUTS
# https://www.terraform.io/language/values/outputs
# ------------------------------------------------------------------------------------------------

#
# Default
#
output "certificate_arn" {
  description = "The ARN of the Certificate"
  sensitive   = false
  value       = aws_acm_certificate.this.arn
}

output "certificate_id" {
  description = "The ID of the Certificate"
  sensitive   = false
  value       = aws_acm_certificate.this.arn
}

output "certificate_domain" {
  description = "The Domain Name of the Certificate"
  sensitive   = false
  value       = aws_acm_certificate.this.domain_name
}

output "certificate_dvo" {
  description = "The Domain Validation Options of the Certificate"
  sensitive   = false
  value       = aws_acm_certificate.this.domain_validation_options
}
