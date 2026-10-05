output "edge_floating_ip" {
  value = openstack_networking_floatingip_v2.edge.address
}

output "private_ips" {
  value = { for k, p in openstack_networking_port_v2.this : k => p.all_fixed_ips[0] }
}
