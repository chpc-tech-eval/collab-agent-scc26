# A port is a virtual NIC with a fixed IP and a security group.
# Creating it separately from the instance lets us pin the IP and attach the floating IP to it.
resource "openstack_networking_port_v2" "this" {
  for_each           = var.hosts
  name               = "${var.team_name}-${each.key}-port"
  network_id         = var.network_ids[each.value.network]
  admin_state_up     = true
  security_group_ids = [var.sg_ids[each.key]]

  fixed_ip {
    subnet_id  = var.subnet_ids[each.value.network]
    ip_address = each.value.ip
  }
}

resource "openstack_compute_instance_v2" "this" {
  for_each    = var.hosts
  name        = each.key
  flavor_id   = each.value.flavor_id
  key_pair    = var.keypair_name

  # Boot from a Cinder volume built from the Rocky image, instead of the flavor's local disk.
  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    destination_type      = "volume"
    volume_size           = each.value.root_disk_gb
    volume_type           = var.volume_type
    boot_index            = 0
    delete_on_termination = true
  }

  # Attach by port, so do NOT set security_groups on the instance.
  network {
    port = openstack_networking_port_v2.this[each.key].id
  }
}

# The floating IP is its own resource, so replacing edge-01 keeps the same public IP.
resource "openstack_networking_floatingip_v2" "edge" {
  pool = var.external_network_name
}

resource "openstack_networking_floatingip_associate_v2" "edge" {
  floating_ip = openstack_networking_floatingip_v2.edge.address
  port_id     = openstack_networking_port_v2.this["edge-01"].id
}
