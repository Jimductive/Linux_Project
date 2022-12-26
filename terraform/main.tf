# -- Generate keypair per site
resource "openstack_compute_keypair_v2" "generate-keypair" {
    count      = length(var.region)
    provider   = openstack.ovh
    name       = "sshkey_eductive09"
    public_key = file("~/.ssh/id_rsa.pub")
    region     = var.region[count.index]
}

# -- Spawn Front instance at GRA11
resource "openstack_compute_instance_v2" "front_instance" {
    name        = var.instance_name_front
    provider    = openstack.ovh
    image_name  = var.image_name
    flavor_name = var.flavor_name
    region      = var.region[0]
    key_pair    = openstack_compute_keypair_v2.generate-keypair.0.name
    network {
        name      = "Ext-Net"
    }
    network {
        name = ovh_cloud_project_network_private.private_network.name
        fixed_ip_v4 = "192.168.${var.vlan_id}.254"
    }
    depends_on = [ovh_cloud_project_network_private_subnet.private_subnet]
}

# -- Back instance(s) at GRA11
resource "openstack_compute_instance_v2" "gra_backends" {
    count       = 3
    name        = "${var.instance_name_back}_gra_${count.index + 1}"
    provider    = openstack.ovh
    image_name  = var.image_name
    flavor_name = var.flavor_name
    region      = var.region[0]
    key_pair    = openstack_compute_keypair_v2.generate-keypair.0.name
    network {
        name      = "Ext-Net"
    }
    network {
        name = ovh_cloud_project_network_private.private_network.name
    }
    depends_on = [ovh_cloud_project_network_private_subnet.private_subnet]
}

# -- Spawn Back instance(s) at SBG5
resource "openstack_compute_instance_v2" "sbg_backends" {
    count       = 3
    name        = "${var.instance_name_back}_sbg_${1 + count.index}"
    provider    = openstack.ovh
    image_name  = var.image_name
    flavor_name = var.flavor_name
    region      = var.region[1]
    key_pair    = openstack_compute_keypair_v2.generate-keypair.0.name
    network {
        name      = "Ext-Net"
    }
    network {
        name = ovh_cloud_project_network_private.private_network.name
    }
    depends_on = [ovh_cloud_project_network_private_subnet.private_subnet]
}

# -- Private network
 resource "ovh_cloud_project_network_private" "private_network" {
    service_name = var.service_name
    name         = "private_network_eductive09"
    regions      = var.region
    provider     = ovh.ovh
    vlan_id      = var.vlan_id
 }

# -- Private subnet
 resource "ovh_cloud_project_network_private_subnet" "private_subnet" {
    count        = length(var.region)
    service_name = var.service_name
    network_id   = ovh_cloud_project_network_private.private_network.id
    start        = var.vlan_dhcp_start
    end          = var.vlan_dhcp_end
    network      = var.vlan_dhcp_network
    dhcp         = true
    region       = var.region[count.index]
    provider     = ovh.ovh 
    no_gateway   = true
 }

# -- Spawn database
resource "ovh_cloud_project_database" "db_eductive09" {
  service_name = var.service_name
  engine       = "mysql"
  version      = "8"
  plan         = "essential"
  nodes {
    region = "GRA"
  }
  flavor = "db1-4"
}

resource "ovh_cloud_project_database_user" "eductive09" {
  service_name = ovh_cloud_project_database.db_eductive09.service_name
  engine       = ovh_cloud_project_database.db_eductive09.engine
  cluster_id   = ovh_cloud_project_database.db_eductive09.id
  name         = "eductive09"
}

resource "ovh_cloud_project_database_database" "database" {
  service_name  = ovh_cloud_project_database.db_eductive09.service_name
  engine        = ovh_cloud_project_database.db_eductive09.engine
  cluster_id    = ovh_cloud_project_database.db_eductive09.id
  name          = "linux_project_database"
}

resource "ovh_cloud_project_database_ip_restriction" "iprestriction_sbg" {
  count       = length(openstack_compute_instance_v2.sbg_backends)
  service_name = ovh_cloud_project_database.db_eductive09.service_name
  engine       = ovh_cloud_project_database.db_eductive09.engine
  cluster_id   = ovh_cloud_project_database.db_eductive09.id
  ip           = "${element(openstack_compute_instance_v2.sbg_backends[*].access_ip_v4, count.index)}/32"
}

resource "ovh_cloud_project_database_ip_restriction" "iprestriction_gra" {
  count       = length(openstack_compute_instance_v2.gra_backends)
  service_name = ovh_cloud_project_database.db_eductive09.service_name
  engine       = ovh_cloud_project_database.db_eductive09.engine
  cluster_id   = ovh_cloud_project_database.db_eductive09.id
  ip           = "${element(openstack_compute_instance_v2.gra_backends[*].access_ip_v4, count.index)}/32"
}

# -- Inventory set
resource "local_file" "inventory" {
  filename = "../ansible/inventory.yml"
  content  = templatefile("../templates/inventory.tmpl",
    {
      sbg_backends = [for k, p in openstack_compute_instance_v2.sbg_backends: p.access_ip_v4],
      gra_backends = [for k, p in openstack_compute_instance_v2.gra_backends: p.access_ip_v4],
      front = openstack_compute_instance_v2.front_instance.access_ip_v4
    }
  )
}

# -- IPTable file set
resource "local_file" "iptable" {
  filename = "../ansible/iptable_config.yml"
  content  = templatefile("../templates/iptable_config.tmpl",
    {
      front = openstack_compute_instance_v2.front_instance.access_ip_v4
    }
  )
}

# -- NFS file set
resource "local_file" "nfs" {
  filename = "../ansible/nfs_config.yml"
  content  = templatefile("../templates/nfs_config.tmpl",
    {
      front = openstack_compute_instance_v2.front_instance.network.1.fixed_ip_v4
    }
  )
}

# -- Print informations of instances
output "cluster_uri" {
  value = ovh_cloud_project_database.db_eductive09.endpoints.0.uri
}
output "user_name" {
  value = ovh_cloud_project_database_user.eductive09.name
}
output "user_password" {
  value     = ovh_cloud_project_database_user.eductive09.password
  sensitive = true
}

output "front_ip" {
    value = [openstack_compute_instance_v2.front_instance.name,openstack_compute_instance_v2.front_instance.network.0.fixed_ip_v4,openstack_compute_instance_v2.front_instance.network.1.fixed_ip_v4]
}
output "gra_backends_ips" {
    value = [openstack_compute_instance_v2.gra_backends.*.name,openstack_compute_instance_v2.gra_backends.*.network.0.fixed_ip_v4,openstack_compute_instance_v2.gra_backends.*.network.1.fixed_ip_v4]
}
output "sbg_backends_ips" {
    value = [openstack_compute_instance_v2.sbg_backends.*.name,openstack_compute_instance_v2.sbg_backends.*.network.0.fixed_ip_v4,openstack_compute_instance_v2.sbg_backends.*.network.1.fixed_ip_v4]
}
