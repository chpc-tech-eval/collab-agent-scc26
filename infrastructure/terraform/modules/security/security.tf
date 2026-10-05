locals {
  host_names = ["edge-01", "api-lb-01", "k8s-cp-01", "k8s-worker-01", "k8s-worker-02"]

  internal_cidrs = {
    mgmt = var.mgmt_cidr
    k8s  = var.k8s_cidr
  }

  # One rule per (host, internal CIDR): allow all traffic from either private network.
  # nftables tightens this in later weeks.
  internal_rules = {
    for pair in setproduct(local.host_names, keys(local.internal_cidrs)) :
    "${pair[0]}-from-${pair[1]}" => {
      host = pair[0]
      cidr = local.internal_cidrs[pair[1]]
    }
  }
}

# One security group per host. Neutron adds allow-all egress rules automatically.
resource "openstack_networking_secgroup_v2" "this" {
  for_each             = toset(local.host_names)
  name                 = "${var.team_name}-${each.key}-sg"
  description          = "Security group for ${each.key}"
  delete_default_rules = false
}

resource "openstack_networking_secgroup_rule_v2" "internal" {
  for_each          = local.internal_rules
  security_group_id = openstack_networking_secgroup_v2.this[each.value.host].id
  direction         = "ingress"
  ethertype         = "IPv4"
  remote_ip_prefix  = each.value.cidr
  # protocol omitted = any protocol
}

# Temporary bootstrap SSH: edge-01 only, only from your admin IP.
resource "openstack_networking_secgroup_rule_v2" "edge_ssh" {
  security_group_id = openstack_networking_secgroup_v2.this["edge-01"].id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = var.admin_ssh_cidr
}
