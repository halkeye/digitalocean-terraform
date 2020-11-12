terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.1.0"
    }
  }
}

provider "digitalocean" {
}

variable "csmm_instances" {
  type    = list(string)
  default = ["halkeye", "cata"]
}

data "digitalocean_sizes" "csmm" {
  filter {
    key    = "slug"
    values = ["s-1vcpu-2gb"]
  }
}


data "digitalocean_ssh_key" "halkeye" {
  name = "halkeye@odin"
}

data "digitalocean_domain" "default" {
  name = "do.g4v.dev"
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
#  ttl    = 60
#}

resource "digitalocean_ssh_key" "cata" {
  name       = "cata"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDyuyGG81lJ1WwmHIiUEA2lhXwaCyaiij7XG4j241fxMqiZ8iIchwpurvf0EQd9JgkF6jdE3BK/y62B3KopRf7IayF7dSqjElOIRrQ88/TvW45s5PS5PckYK7DWz0Dnq35Lepw7yV9MwZ5JHbnaR6ULbUWVJp/pw9IfxogspTFFbGmTW4HabaF+miKHzJle8pfLvVwuMXLkYLnrNFptU33FEpLQS8D0uYj5G/j5Ht4JVsPTHiVbQ6iQVN7xD/3+PVve6RK0JKcVoDIDn8V+KroXu/9NSSzwIsG+GfTFmLz9N0tQ8oZqhHL51PAZHJjo17e6r9PW7bN6sR+wZCqY6OoRdiu01dOih/gNqsU8Rs//Szxo5E8wQ/Kkbl0WMjEBnjvzxUiAW2li5wzCBvFjIHJ42hy812RmIl1YWFKJeQPJYyLMuqXfJNYRUkltgzqhNNIvQrwRsg/p0SQwYDQ26zxkt3QIUKgchOa+qvcapK3FkSReGWTQGj0qp6YktuAYh0zwbQ/HGuxfqTZ9dekWgT0zHUuG0P7klxVMD5JBQsgO42Q+thRruZiTGQwq523vdjBbJw2xVwr/ZXcaaQFAs68fS1uZuA9Uu47TUpjzrGy1y6fK4rPc0qIRf9YaQVurYelFrUt/akXcoyBPyeq7dJRUxOnyQW6c/BoTER2y0Uy4dQ== imported-openssh-key"
}

resource "digitalocean_droplet" "csmm" {
  count              = length(var.csmm_instances)
  image              = data.digitalocean_droplet_snapshot.csmm-snapshot.id
  name               = "csmm-${var.csmm_instances[count.index]}"
  region             = "nyc3"
  size               = element(data.digitalocean_sizes.csmm.sizes, 0).slug
  private_networking = true
  ssh_keys = [
    data.digitalocean_ssh_key.halkeye.id,
    digitalocean_ssh_key.cata.id
  ]
}

resource "digitalocean_loadbalancer" "csmm" {
  count  = length(var.csmm_instances)
  name   = "csmm-lb-${var.csmm_instances[count.index]}"
  region = "nyc3"

  forwarding_rule {
    entry_port     = 80
    entry_protocol = "http"

    target_port     = 80
    target_protocol = "http"
  }

  forwarding_rule {
    entry_port     = 443
    entry_protocol = "tcp"

    target_port     = 443
    target_protocol = "tcp"
  }

  forwarding_rule {
    entry_port     = 4022
    entry_protocol = "tcp"

    target_port     = 22
    target_protocol = "tcp"
  }

  healthcheck {
    port     = 22
    protocol = "tcp"
  }

  droplet_ids = [digitalocean_droplet.csmm[count.index].id]
}

resource "digitalocean_record" "csmm" {
  count  = length(var.csmm_instances)
  domain = data.digitalocean_domain.default.name
  type   = "A"
  name   = "csmm-${var.csmm_instances[count.index]}"
  value  = digitalocean_loadbalancer.csmm[count.index].ip
  ttl    = 60
}
