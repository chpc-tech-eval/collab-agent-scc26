variable "team_name" { type = string }
variable "image_id" { type = string }
variable "keypair_name" { type = string }
variable "volume_type" { type = string }
variable "external_network_name" { type = string }

variable "hosts" {
  type = map(object({
    flavor_id    = string
    root_disk_gb = number
    network      = string
    ip           = string
  }))
}

variable "network_ids" { type = map(string) }
variable "subnet_ids" { type = map(string) }
variable "sg_ids" { type = map(string) }
