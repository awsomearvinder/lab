resource "incus_network" "default" {
  name = "default_network"
  # TODO: Instead of a bridge network, we should probably segregate this
  # out, and either BGP or have a static route...
  config = {
    "ipv4.address" = "10.120.3.1/24"
    "ipv4.nat" = "false"
    "ipv4.dhcp" = "true"
    "ipv4.dhcp.gateway" = "10.120.3.1"
    "ipv6.address" = "fd8c:ac79:8818:0001::1/64"
    "ipv6.nat" = "false"
    "ipv6.dhcp" = "false"
    "bgp.peers.jingliu.address" = "fd8c:ac79:8818::1"
    "bgp.peers.jingliu.asn" = "4261420343"
  }
}
