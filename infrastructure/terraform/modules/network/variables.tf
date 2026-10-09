variable "team_name" { type = string }
variable "mgmt_cidr" { type = string }
variable "k8s_cidr" { type = string }
variable "external_network_id" { type = string }

variable "vpn_cidr" {
  description = "WireGuard VPN overlay CIDR"
  type        = string
}
