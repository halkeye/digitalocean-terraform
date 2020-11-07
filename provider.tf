terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.1.0"
    }
  }
}

provider "digitalocean" {
}

data "digitalocean_ssh_key" "halkeye" {
  name = "halkeye@odin"
}

data "digitalocean_domain" "default" {
  name  = "do.g4v.dev"
}

data "digitalocean_droplet_snapshot" "csmm-snapshot" {
  name_regex  = "^csmm-snapshot-"
  region      = "nyc3"
  most_recent = true
}

#data "digitalocean_record" "default" {
#  domain = data.digitalocean_domain.default.name
#  type   = "A"
#  name   = "*"
#  value  = "167.99.25.174"
#}

resource "digitalocean_droplet" "csmm-1" {
  image = data.digitalocean_droplet_snapshot.csmm-snapshot.id
  name = "csmm-1"
  region = "nyc3"
  size = "s-1vcpu-1gb"
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.halkeye.id
  ]
}

resource "digitalocean_loadbalancer" "csmm-lb" {
  name = "csmm-lb"
  region = "nyc3"

  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"

    target_port = 80
    target_protocol = "http"
  }

  forwarding_rule {
    entry_port = 443
    entry_protocol = "tcp"

    target_port = 443
    target_protocol = "tcp"
  }

  healthcheck {
    port = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.csmm-1.id]
}

resource "digitalocean_record" "csmm-1" {
  domain = data.digitalocean_domain.default.name
  type   = "A"
  name   = "csmm-1"
  value  = digitalocean_droplet.csmm-1.ipv4_address
}
