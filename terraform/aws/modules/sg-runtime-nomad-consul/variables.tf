# /terraform/aws/modules/sg-runtime-nomad-consul
# ------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------------------------

# MVP: Can this be restricted to an enumerated list?
variable "environment" {
  description = "The environment that this module is being deployed for"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC resources should be deployed in to"
  type        = string
}

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

# ------------------------------------------------------------------------------------------------
# OPTIONAL PARAMETERS (Ports)
# These parameters have reasonable defaults.
# ------------------------------------------------------------------------------------------------

variable "consul_rpc_port" {
  description = "The port used by Consul agents to handle incoming requests from other agents."
  type        = number
  default     = 8300
}

# variable "consul_cli_rpc_port" {
#   description = "The port used by all Consul agents to handle RPC from the CLI."
#   type        = number
#   default     = 8400
# }

variable "consul_serf_lan_port" {
  description = "The port used by Consul to handle gossip in the LAN. Required by all agents."
  type        = number
  default     = 8301
}

# variable "consul_serf_wan_port" {
#   description = "The port used by Consul servers to gossip over the WAN to other servers."
#   type        = number
#   default     = 8302
# }

# variable "consul_http_api_port" {
#   description = "The port used by Consul clients to talk to the HTTP API"
#   type        = number
#   default     = 8500
# }

# variable "consul_dns_port" {
#   description = "The port used to resolve DNS queries."
#   type        = number
#   default     = 8600
# }

variable "nomad_rpc_port" {
  description = "The port to use for RPC for Nomad"
  type        = number
  default     = 4647
}

variable "nomad_serf_port" {
  description = "The port to use for Serf for Nomad"
  type        = number
  default     = 4648
}

# variable "nomad_http_port" {
#   description = "The port to use for HTTP (and API) for Nomad"
#   type        = number
#   default     = 4646
# }

# ------------------------------------------------------------------------------------------------
# LOCALS
# https://www.terraform.io/language/values/locals
# Don't edit these unless you know what you are doing.
# ------------------------------------------------------------------------------------------------
