resource "incus_network" "default" {
  name = "default_network"
  # TODO: Instead of a bridge network, we should probably segregate this
  # out, and either BGP or have a static route...
  config = {
    "ipv4.address" = "10.120.3.1/24"
    "ipv4.nat" = "false"
    "ipv4.dhcp" = "true"
    "ipv4.dhcp.gateway" = "10.120.3.1"
    "ipv6.address" = "2a11:6c7:2001:cc01::/64"
    "ipv6.nat" = "false"
    "ipv6.dhcp" = "false"
    "bgp.peers.jingliu.address" = "2a11:6c7:2001:cc00::1"
    "bgp.peers.jingliu.asn" = "4261420343"
  }
}
