###################################
# Get image ID
###################################
data "openstack_images_image_v2" "image_app" {
  most_recent = true
  visibility  = var.image_visibility_type
  tag         = "app-consul"
}

###################################
# Create port
###################################
resource "openstack_networking_port_v2" "port_app" {
  name       = "app-${count.index + 1}-eth0"
  count      = var.app_count
  network_id = openstack_networking_network_v2.network_1.id

  fixed_ip {
    subnet_id = openstack_networking_subnet_v2.subnet_1.id
  }
}

###################################
# Create Volume/Disk
###################################
resource "openstack_blockstorage_volume_v3" "volume_app" {
  name                 = "volume-for-app-server-${count.index + 1}"
  count                = var.app_count
  size                 = var.hdd_size
  image_id             = data.openstack_images_image_v2.image_app.id
  volume_type          = var.volume_type
  availability_zone    = var.az_zone
  enable_online_resize = true

  lifecycle {
    ignore_changes = [image_id]
  }
}
resource "openstack_compute_instance_v2" "app" {
  name              = "app-${count.index + 1}"
  count             = var.app_count
  flavor_id         = openstack_compute_flavor_v2.flavor_1.id
  key_pair          = openstack_compute_keypair_v2.terraform_key.id
  availability_zone = var.az_zone

  network {
    port = openstack_networking_port_v2.port_app[count.index].id
  }

  block_device {
    uuid             = openstack_blockstorage_volume_v3.volume_app[count.index].id
    source_type      = "volume"
    destination_type = "volume"
    boot_index       = 0
  }

  vendor_options {
    ignore_resize_confirmation = true
  }

  provisioner "file" {
    content = <<-EOT
      retry_join = ["provider=os tag_key=consul tag_value=server auth_url=https://api.selvpc.ru/identity/v3 password=${var.user_password} user_name=${var.user_name} project_id=${var.project_id}  domain_name=${var.domain_name} region=${var.region}"]

      node_name = "app-${count.index}"

      service = {
        id = "app-${count.index}"
        name = "app-${count.index}"
        port = 80
        tags = ["urlprefix-:80"]
        checks= [{
          id = "check-app"
          http = "http://127.0.0.1"
          interval = "15s"
        }]
      }

    EOT
#"
    destination = "/etc/consul.d/join.hcl"
    connection {
      type  = "ssh"
      // host  = "${openstack_networking_floatingip_v2.floatingip_app.address}"
      host  = self.access_ip_v4
      user  = "root"
      private_key = file("~/.ssh/id_rsa")
      # agent = true
      bastion_host = openstack_networking_floatingip_v2.floatingip_db.address
      bastion_user = "root"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "systemctl restart consul",
    ]

    connection {
      type = "ssh"
      host  = self.access_ip_v4
      user  = "root"
      private_key = file("~/.ssh/id_rsa")
      # agent = true
      bastion_host = openstack_networking_floatingip_v2.floatingip_db.address
      bastion_user = "root"
    }
  }
}

