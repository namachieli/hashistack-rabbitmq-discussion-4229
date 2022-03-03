# /terraform/aws/modules/sg-default
# ------------------------------------------------------------------------------------------------
# OUTPUTS
# https://www.terraform.io/language/values/outputs
# ------------------------------------------------------------------------------------------------

#
# Default
#
output "default_arn" {
  description = "The ARN of the Default security group"
  sensitive   = false
  value       = aws_security_group.default.arn
}

output "default_id" {
  description = "The ID of the Default security group"
  sensitive   = false
  value       = aws_security_group.default.id
}

output "internal_v4_pl_arn" {
  description = "The ARN of the IPv4 'Internal' Prefix List"
  sensitive   = false
  value       = aws_ec2_managed_prefix_list.internal_v4.arn
}

output "internal_v4_pl_id" {
  description = "The ID of the IPv4 'Internal' Prefix List"
  sensitive   = false
  value       = aws_ec2_managed_prefix_list.internal_v4.id
}
