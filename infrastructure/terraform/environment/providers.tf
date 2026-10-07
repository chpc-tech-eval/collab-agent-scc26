terraform {
  required_version = ">= 1.9"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "3.4.0"
    }
  }
}

# Auth comes from OS_CLOUD or your sourced RC file; no credentials here.
provider "openstack" {}
