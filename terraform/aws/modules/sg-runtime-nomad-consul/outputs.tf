# /terraform/aws/modules/sg-runtime-nomad-consul
# ------------------------------------------------------------------------------------------------
# OUTPUTS
# https://www.terraform.io/language/values/outputs
# ------------------------------------------------------------------------------------------------

output "sg_arn" {
  description = "The ARN of the created security group for the Runtime Layer"
  sensitive   = false
  value       = aws_security_group.this.arn
}

output "sg_id" {
  description = "The ID of the created security group for the Runtime Layer"
  sensitive   = false
  value       = aws_security_group.this.id
}
