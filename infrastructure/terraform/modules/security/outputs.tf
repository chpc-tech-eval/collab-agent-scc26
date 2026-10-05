output "sg_ids" {
  value = { for name, sg in openstack_networking_secgroup_v2.this : name => sg.id }
}
