variable "team_name" {
  type = string
}

variable "image_id" {
  description = "Rocky 9 image ID"
  type        = string
}

variable "external_network_id" {
  type = string
}

variable "keypair_name" {
  type = string
}

variable "volume_type" {
  type    = string
  default = "NVMe"
}

variable "hosts" {
  type = map(object({
    flavor_id    = string
    root_disk_gb = number
    network      = string # "mgmt" or "k8s"
    ip           = string # fixed private IP inside that network's CIDR
  }))
}

variable "external_network_name" {
  description = "Name of the external network, used as the floating IP pool"
  type        = string
}

variable "mgmt_cidr" {
  type = string
}

variable "k8s_cidr" {
  type = string
}

variable "admin_ssh_cidr" {
  description = "Your workstation public IP as a /32, for temporary bootstrap SSH"
  type        = string
}

variable "vpn_cidr" {
  description = "WireGuard VPN overlay CIDR (edge-01 and admin clients)"
  type        = string

  validation {
    condition     = can(cidrnetmask(var.vpn_cidr))
    error_message = "vpn_cidr must be a valid IPv4 CIDR, e.g. 10.200.0.0/24."
  }
}
