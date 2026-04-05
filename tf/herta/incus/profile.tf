resource "incus_profile" "default" {
  name = "default_profile"
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "${incus_network.default.name}"
    }
  }
}
