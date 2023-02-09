terraform {
  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "2.26.0"
    }
  }
  required_version = ">= 1.3.7"
}

provider "digitalocean" {
  # Configuration options
}
