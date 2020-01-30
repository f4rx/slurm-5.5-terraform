variable "user_name" {}

variable "user_password" {}

variable "domain_name" {}

variable "region" {}

variable "az_zone" {}

variable "volume_type" {}

variable "public_key" {}

variable "project_id" {}

variable "hdd_size" {
  default = "5"
}

variable "app_count" {
  default = 1
}
variable "image_visibility_type" {
  default = "private"
}


