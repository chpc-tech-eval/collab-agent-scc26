variable "team_name" { type = string }
variable "mgmt_cidr" { type = string }
variable "k8s_cidr" { type = string }
variable "admin_ssh_cidr" { type = string }

variable "vpn_cidr" {
  description = "WireGuard VPN overlay CIDR"
  type        = string
}
