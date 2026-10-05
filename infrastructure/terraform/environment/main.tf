module "network" {
  source              = "../modules/network"
  team_name           = var.team_name
  mgmt_cidr           = var.mgmt_cidr
  k8s_cidr            = var.k8s_cidr
  external_network_id = var.external_network_id
}

module "security" {
  source         = "../modules/security"
  team_name      = var.team_name
  mgmt_cidr      = var.mgmt_cidr
  k8s_cidr       = var.k8s_cidr
  admin_ssh_cidr = var.admin_ssh_cidr
}

module "compute" {
  source                = "../modules/compute"
  team_name             = var.team_name
  image_id              = var.image_id
  keypair_name          = var.keypair_name
  volume_type           = var.volume_type
  hosts                 = var.hosts
  external_network_name = var.external_network_name

  network_ids = module.network.network_ids   # map: { mgmt = ..., k8s = ... }
  subnet_ids  = module.network.subnet_ids    # map: { mgmt = ..., k8s = ... }
  sg_ids      = module.security.sg_ids       # map keyed by host name
}
