module "ssh_key" {
  source = "github.com/Ujstor/self-hosting-infrastructure-cluster//modules/modules/ssh_key?ref=v0.0.2"

  ssh_key_name = "k3s_ansible_rsa"
  ssh_key_path = "~/.ssh"
}

module "k3d_server" {
  source = "github.com/Ujstor/self-hosting-infrastructure-cluster//modules/modules/worker?ref=v0.0.2"

  hcloud_ssh_key_id = [module.ssh_key.hcloud_ssh_key_id]
  os_type           = "ubuntu-22.04"

  worker_config = {
    master-1 = {
      location     = "fsn1"
      server_type  = "cx22"
      labels       = "k3d-node"
      ipv4_enabled = true
      ipv6_enabled = false
    }
    # master-2 = {
    #   location     = "fsn1"
    #   server_type  = "cx22"
    #   labels       = "k3d-node"
    #   ipv4_enabled = true
    #   ipv6_enabled = false
    # }
    # master-3 = {
    #   location     = "fsn1"
    #   server_type  = "cx22"
    #   labels       = "k3d-node"
    #   ipv4_enabled = true
    #   ipv6_enabled = false
    # }
    # node-1 = {
    #   location     = "fsn1"
    #   server_type  = "cx22"
    #   labels       = "k3d-node"
    #   ipv4_enabled = true
    #   ipv6_enabled = false
    # }
    # node-2 = {
    #   location     = "fsn1"
    #   server_type  = "cx22"
    #   labels       = "k3d-node"
    #   ipv4_enabled = true
    #   ipv6_enabled = false
    # }
    # node-3 = {
    #   location     = "fsn1"
    #   server_type  = "cx22"
    #   labels       = "k3d-node"
    #   ipv4_enabled = true
    #   ipv6_enabled = false
    # }
  }

  depends_on = [module.ssh_key]
}

module "cloudflare_record" {
  source = "github.com/Ujstor/self-hosting-infrastructure-cluster//modules/modules/network/cloudflare_record?ref=v0.0.2"

  cloudflare_record = {
    vpn = {
      zone_id = var.cloudflare_zone_id
      name    = "vpn"
      value   = module.openvpn_server.worker_info.master-1.ip
      type    = "A"
      ttl     = 1
      proxied = true
    }

    depends_on = [module.openvpn_server]
  }
}

output "server_info" {
  value = module.k3d_server.worker_info
}

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.47"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.37"
    }
  }
  required_version = ">= 1.0.0, < 2.0.0"
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

variable "hcloud_token" {
  description = "Hetzner Cloud API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone id"
  type        = string
}
