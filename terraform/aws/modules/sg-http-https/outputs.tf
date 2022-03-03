# /terraform/aws/modules/sg-http-https
# ------------------------------------------------------------------------------------------------
# OUTPUTS
# https://www.terraform.io/language/values/outputs
# ------------------------------------------------------------------------------------------------

output "access_arn" {
  description = "The ARN of the created security group for Consumer Access"
  sensitive   = false
  value       = aws_security_group.consumer_access.arn
}

output "access_id" {
  description = "The ID of the created security group for Consumer Access"
  sensitive   = false
  value       = aws_security_group.consumer_access.id
}
