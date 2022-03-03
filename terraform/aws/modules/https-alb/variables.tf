# /terraform/aws/modules/https-alb
# ------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------

variable "alb_name" {
  description = "The name of the ALB, keep it DNS compliant"
  type        = string
}

variable "alb_subnet_ids" {
  description = "The subnet IDs that the ALB should be deployed into"
  type        = list(string)
}

variable "alb_sg_ids" {
  description = "The security group IDs that should be applied to the ALB"
  type        = list(string)
}

variable "vpc_id" {
  description = "The ID of the VPC resources should be deployed in to"
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the certificate to use for TLS"
  type        = string
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------
variable "target_group_port" {
  description = "The port that the ALB Target Group will forward to"
  type        = number
  default     = 443
}

variable "target_group_protocol" {
  description = "The protocol (HTTP or HTTPS) that the ALB Target Group will forward to"
  type        = string
  default     = "HTTPS"
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS (Health Check)
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

variable "hc_enabled" {
  description = "Whether health checks are enabled"
  type        = bool
  default     = true
}

variable "hc_healthy_threshold" {
  description = "Number of consecutive health checks successes required before considering an unhealthy target healthy"
  type        = number
  default     = 3
}

variable "hc_interval" {
  description = "Approximate amount of time, in seconds, between health checks of an individual target"
  type        = number
  default     = 30
}

variable "hc_matcher" {
  description = "Response codes to use when checking for a healthy response from a target"
  type        = string
  default     = "200-299"
}

variable "hc_path" {
  description = "Destination for the health check request"
  type        = string
  default     = "/"
}

variable "hc_port" {
  description = "Port to use to connect with the target. Valid values are either ports 1-65535"
  type        = number
  default     = 443
}

variable "hc_protocol" {
  description = "Protocol to use to connect with the target"
  type        = string
  default     = "HTTPS"
}

variable "hc_timeout" {
  description = "Amount of time, in seconds, during which no response means a failed health check"
  type        = number
  default     = 5
}

variable "hc_unhealthy_threshold" {
  description = "Number of consecutive health check failures required before considering the target unhealthy"
  type        = number
  default     = 3
}

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------
