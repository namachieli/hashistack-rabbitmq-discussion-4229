# /terraform/aws/modules/auto-scaling-group
# ------------------------------------------------------------------------------------------------
# OUTPUTS
# https://www.terraform.io/language/values/outputs
# ------------------------------------------------------------------------------------------------

output "asg_id" {
  description = "The ID of the created ASG"
  sensitive   = false
  value       = aws_autoscaling_group.this.id
}
