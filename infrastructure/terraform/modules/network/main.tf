locals {
  cidrs = {
    mgmt = var.mgmt_cidr
    k8s  = var.k8s_cidr
  }
}

# A Neutron network is just a layer-2 segment; it has no addresses until a subnet is attached.
resource "openstack_networking_network_v2" "this" {
  for_each       = local.cidrs
  name           = "${var.team_name}-${each.key}-net"
  admin_state_up = true
}

# The subnet gives the network an IP range. Neutron reserves the first
# address (.1) as the gateway by default, so its skipped. 
resource "openstack_networking_subnet_v2" "this" {
  for_each        = local.cidrs
  name            = "${var.team_name}-${each.key}-subnet"
  network_id      = openstack_networking_network_v2.this[each.key].id
  cidr            = each.value
  ip_version      = 4
  enable_dhcp     = true
  dns_nameservers = ["1.1.1.1", "8.8.8.8"]
}

# The router has an external gateway (so private hosts can reach the
# internet via SNAT and so floating IPs work) and an interface on each subnet.
resource "openstack_networking_router_v2" "this" {
  name                = "${var.team_name}-router"
  admin_state_up      = true
  external_network_id = var.external_network_id
}

resource "openstack_networking_router_interface_v2" "this" {
  for_each  = local.cidrs
  router_id = openstack_networking_router_v2.this.id
  subnet_id = openstack_networking_subnet_v2.this[each.key].id
}

# Return path for VPN clients: replies to vpn_cidr go to edge-01 (the WireGuard gateway).
# The next hop must sit on a subnet the router is attached to, so wait for the interfaces.
resource "openstack_networking_router_route_v2" "vpn" {
  router_id        = openstack_networking_router_v2.this.id
  destination_cidr = var.vpn_cidr
  next_hop         = var.vpn_next_hop

  depends_on = [openstack_networking_router_interface_v2.this]
}
