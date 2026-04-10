resource "incus_storage_volume" "phainon_root" {
  name = "phainon_root"
  pool = incus_storage_pool.default.name
}

resource "incus_instance" "phainon" {
  name = "phainon"
  image = incus_image.nixos.fingerprint
  profiles = [incus_profile.default.name]
  device {
    name = "phainon"
    type = "disk"
    properties = {
      path = "/"
      # source = incus_storage_volume.phainon_root.name
      pool = incus_storage_pool.default.name
    }
  }
}
