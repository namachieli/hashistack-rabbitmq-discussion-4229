# /terraform/aws/modules/https-alb
# ------------------------------------------------------------------------------------------------
# OUTPUTS
# https://www.terraform.io/language/values/outputs
# ------------------------------------------------------------------------------------------------

output "alb_arn" {
  description = "The ARN of the ALB"
  sensitive   = false
  value       = aws_lb.this.arn
}

output "target_group_arn" {
  description = "The ARN of the target group for the created ALB"
  sensitive   = false
  value       = aws_lb_target_group.this.arn
}

output "alb_dns_record" {
  description = "The DNS Record of the created ALB"
  sensitive   = false
  value       = aws_lb.this.dns_name
}

output "member_sg_arn" {
  description = "The ARN of the security group for ALB Pool members"
  sensitive   = false
  value       = aws_security_group.this.arn
}

output "member_sg_id" {
  description = "The ID of the security group for ALB Pool members"
  sensitive   = false
  value       = aws_security_group.this.id
}

output "https_listener_arn" {
  description = "The ARN of the HTTPS Listener for the ALB (for additional Listener Rules)"
  sensitive   = false
  value       = aws_lb_listener.HTTPS.arn
}

output "https_listener_id" {
  description = "The ID of the HTTPS Listener for the ALB (for additional Listener Rules)"
  sensitive   = false
  value       = aws_lb_listener.HTTPS.id
}
