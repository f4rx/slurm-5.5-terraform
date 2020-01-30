###################################
# Configure the OpenStack Provider
###################################
provider "openstack" {
  domain_name = "${var.domain_name}"
  tenant_id   = "${var.project_id}"
  user_name   = "${var.user_name}"
  password    = "${var.user_password}"
  auth_url    = "https://api.selvpc.ru/identity/v3"
  region      = "${var.region}"
}

module "app_stand" {
  source = "../modules/create_env"

  region                = "${var.region}"
  public_key            = "${var.public_key}"
  hdd_size              = "${var.hdd_size}"
  volume_type           = "${var.volume_type}"
  az_zone               = "${var.az_zone}"

  domain_name = "${var.domain_name}"
  project_id = "${var.project_id}"
  user_name = "${var.user_name}"
  user_password = "${var.user_password}"

  image_visibility_type = "shared"
  // app_count             = "2"
}

output "server_external_ip" {
  value = "${module.app_stand.server_external_ip}"
}

