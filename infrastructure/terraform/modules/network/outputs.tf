output "network_ids" {
  value = { for k, n in openstack_networking_network_v2.this : k => n.id }
}

output "subnet_ids" {
  value = { for k, s in openstack_networking_subnet_v2.this : k => s.id }
}
