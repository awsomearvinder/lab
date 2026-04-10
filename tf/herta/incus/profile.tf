resource "incus_profile" "default" {
  name = "default_profile"
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "${incus_network.default.name}"
    }
  }
  device {
    name = "root"
    type = "disk"
    properties = {
      pool = incus_storage_pool.default.name
      path = "/"
      size = "50GiB"
    }
  }
}
