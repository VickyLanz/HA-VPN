module "vpc-1" {
  source="../module/vpc"

  name       = var.mnetwork_name.vpc-1
  project_id = var.mproject_id.vpc-1
  auto_create_subnetworks = false
  subnets = [
    {
      ip_cidr_range="10.0.0.0/24"
      name="vpc-1-subnet-1"
      region="us-central1"
      secondary_ip_range=null
    },
    {
      ip_cidr_range="10.1.0.0/24"
      name="vpc-1-subnet-2"
      region="europe-west1"
      secondary_ip_range=null
    }
  ]
}
module "vpc-2" {
  source="../module/vpc"

  name       = var.mnetwork_name.vpc-2
  project_id = var.mproject_id.vpc-2
  auto_create_subnetworks = false
  subnets = [
    {
      ip_cidr_range="20.0.0.0/24"
      name="vpc-2-subnet-1"
      region="us-central1"
      secondary_ip_range=null
    }
  ]
}
module "firewall-1" {
  source = "../module/firewall"
  depends_on = [module.vpc-1]
  project_id = var.mproject_id.vpc-1
  network_name = module.vpc-1.self_link
  rules = [{
    name                    = "allow-ssh-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },
    {
    name                    = "allow-icmp-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "icmp"
       ports =[]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },
    {
    name                    = "allow-internal-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["0-65535"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
}
module "firewall-2" {
  source = "../module/firewall"
  depends_on = [module.vpc-2]
  project_id = var.mproject_id.vpc-2
  network_name = module.vpc-2.self_link
  rules = [{
    name                    = "allow-ssh-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["22"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },
    {
    name                    = "allow-icmp-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "icmp"
      ports =[]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  },
    {
    name                    = "allow-internal-ingress"
    description             = null
    direction               = "INGRESS"
    priority                = null
    ranges                  = ["0.0.0.0/0"]
    source_tags             = null
    source_service_accounts = null
    target_tags             = null
    target_service_accounts = null
    allow = [{
      protocol = "tcp"
      ports    = ["0-65535"]
    }]
    deny = []
    log_config = {
      metadata = "INCLUDE_ALL_METADATA"
    }
  }]
}

module "vm-1" {
  source = "../module/vm"
  depends_on = [module.vpc-1]
  name               = "vm-01"
  network_interfaces = [{
      network=module.vpc-1.self_link
      subnetwork =module.vpc-1.subnet_self_links["us-central1/vpc-1-subnet-1"]
      nat= false
      addresses=null
  }]
  project_id         = var.mproject_id.vpc-1
  zone               = var.mzone.vpc-1
}
module "vm-2" {
  source = "../module/vm"
  depends_on = [module.vpc-2]
  name   = "vm-02-on-prem"
  network_interfaces = [{
      network=module.vpc-2.self_link
      subnetwork =module.vpc-2.subnet_self_links["us-central1/vpc-2-subnet-1"]
      nat= false
      addresses=null
  }]
  project_id         = var.mproject_id.vpc-2
  zone               = var.mzone.vpc-2
}
module "vm-3" {
  source = "../module/vm"
  depends_on = [module.vpc-1]
  name               = "vm-03"
  network_interfaces = [{
      network=module.vpc-1.self_link
      subnetwork =module.vpc-1.subnet_self_links["europe-west1/vpc-1-subnet-2"]
      nat= false
      addresses=null
  }]
  project_id         = var.mproject_id.vpc-1
  zone               = "europe-west1-b"
}
module "vpn_ha-1" {
  source           = "../module/ha-vpn"
  depends_on = [module.vpc-1]
  project_id       = var.mproject_id.vpc-1
  region           = "us-central1"
  network          = module.vpc-1.self_link
  name             = "net1-to-net-2"
  peer_gcp_gateway = module.vpn_ha-2.self_link
  router_asn       = 64514
  router_advertise_config = {
    groups = ["ALL_SUBNETS"]
    ip_ranges = {
      "10.0.0.0/8" = "default"
    }
    mode = "CUSTOM"
  }
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = ""
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.1"
        asn     = 64513
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.2/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = ""
      vpn_gateway_interface           = 1
    }
  }
}

module "vpn_ha-2" {
  depends_on = [module.vpc-2]
  source           = "../module/ha-vpn"
  project_id       = var.mproject_id.vpc-2
  region           = "us-central1"
  network          = module.vpc-2.self_link
  name             = "net2-to-net1"
  router_asn       = 64513
  peer_gcp_gateway = module.vpn_ha-1.self_link
  tunnels = {
    remote-0 = {
      bgp_peer = {
        address = "169.254.1.2"
        asn     = 64514
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.1.1/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = module.vpn_ha-1.random_secret
      vpn_gateway_interface           = 0
    }
    remote-1 = {
      bgp_peer = {
        address = "169.254.2.2"
        asn     = 64514
      }
      bgp_peer_options                = null
      bgp_session_range               = "169.254.2.1/30"
      ike_version                     = 2
      peer_external_gateway_interface = null
      router                          = null
      shared_secret                   = module.vpn_ha-1.random_secret
      vpn_gateway_interface           = 1
    }
  }
}
# tftest modules=2 resources=18