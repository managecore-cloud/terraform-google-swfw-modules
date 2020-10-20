terraform {
  required_version = ">= 0.12, < 0.13"
}

provider "google" {
  version = "= 3.30"
}

variable mgmt_sources {
  default = ["0.0.0.0/0"]
}

data "google_compute_zones" "available" {
}

module "vpc" {
  source = "../../modules/vpc/"


  networks = {
    "my-vpc" = {
      name            = "my-vpc"
      subnetwork_name = "my-subnet"
      ip_cidr_range   = "192.168.1.0/24"
      allowed_sources = var.mgmt_sources
    }
  }
}

locals {
  my_vpc    = module.vpc.networks["my-vpc"].self_link
  my_subnet = try(module.vpc.subnetworks["my-subnet"].name, null)
}

#  Google's own health checkers use a set of known address ranges
resource "google_compute_firewall" "builtin_healthchecks" {
  name          = "my-vpc-builtin-healthchecks"
  network       = local.my_vpc
  direction     = "INGRESS"
  source_ranges = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
  # The "169.254.169.254/32" is also used, but it is always allowed anyway.

  allow {
    protocol = "all"
    ports    = []
  }
}
