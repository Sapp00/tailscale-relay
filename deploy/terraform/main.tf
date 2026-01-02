terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.82.1"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.7"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.4"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4"
    }
  }
}

# Read SOPS encrypted secrets
data "sops_file" "secrets" {
  source_file = "secrets.sops.json"
}

provider "proxmox" {
  endpoint = "${data.sops_file.secrets.data["url"]}:${data.sops_file.secrets.data["port"]}"
  api_token = "${data.sops_file.secrets.data["id"]}=${data.sops_file.secrets.data["token"]}"
  insecure = var.proxmox_tls_insecure
}

# Use system default SSH key
resource "tls_private_key" "deployment" {
  algorithm = "ED25519"
}


# VM configuration is in vm.tf
