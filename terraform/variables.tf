variable "region" {
  default = ["GRA11","SBG5"]
  type = list
}

variable "instance_name_front" {
  type = string
  default = "front_eductive09"
}

variable "instance_name_back" {
  type = string
  default = "backend_eductive09"
}

variable "instance_name_db" {
  type = string
  default = "db_eductive09"
}

variable "image_name" {
  type = string
  default = "Debian 11"
}

variable "flavor_name" {
  type = string
  default = "s1-2"
}

variable "service_name" {
  type    = string
}
variable "vlan_id" {
  type    = number
  default = 9
}
variable "vlan_dhcp_start" {
  type = string
  default = "192.168.9.100"
}
variable "vlan_dhcp_end" {
  type = string
  default = "192.168.9.200"
}
variable "vlan_dhcp_network" {
  type = string
  default = "192.168.9.0/24"
}
