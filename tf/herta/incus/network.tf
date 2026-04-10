resource "incus_network" "default" {
  name = "default_network"
  # TODO: Instead of a bridge network, we should probably segregate this
  # out, and either BGP or have a static route...
  config = {
    "ipv4.address" = "10.120.3.1/24"
    "ipv4.nat" = "false"
    "ipv4.dhcp" = "true"
    "ipv4.dhcp.gateway" = "10.120.3.1"
  }
}
