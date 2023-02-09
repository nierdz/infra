resource "digitalocean_droplet" "cp" {
  count      = 3
  image      = "126442131"
  name       = "${format("cka-cp-fra1-%02d", count.index + 1)}"
  region     = "fra1"
  size       = "s-4vcpu-8gb"
  monitoring = true
  vpc_uuid   = "ef5c75aa-0e29-4836-bf75-e6eaac1c0172"
  ssh_keys   = [37463333]
}

output "cp_ipv4" {
  value = [digitalocean_droplet.cp.*.name, digitalocean_droplet.cp.*.ipv4_address]
}

resource "digitalocean_droplet" "wk" {
  count      = 3
  image      = "126442131"
  name       = "${format("cka-wk-fra1-%02d", count.index + 1)}"
  region     = "fra1"
  size       = "s-4vcpu-8gb"
  monitoring = true
  vpc_uuid   = "ef5c75aa-0e29-4836-bf75-e6eaac1c0172"
  ssh_keys   = [37463333]
}

output "wk_ipv4" {
  value = [digitalocean_droplet.wk.*.name, digitalocean_droplet.wk.*.ipv4_address]
}
