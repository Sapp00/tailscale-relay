terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
    sops = {
      source  = "carlpett/sops"
      version = "~> 0.7"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
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

# VM configuration is in vm.tf