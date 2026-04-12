resource "incus_storage_volume" "step_ca_data" {
  name = "step_ca_data"
  pool = incus_storage_pool.default.name
}

resource "incus_image" "bronya" {
  source_file = {
    data_path = "${path.root}/build/nixos-lxc-image-x86_64-linux.bronya-build.squashfs"
    metadata_path = "${path.root}/build/nixos-container-img.bronya.metadata.tar.xz"
  }

  lifecycle {
    replace_triggered_by = [
      terraform_data.bronya
    ]
  }
}
resource "terraform_data" "bronya" {
  input = filemd5("${path.root}/build/nixos-lxc-image-x86_64-linux.bronya-build.squashfs")
}

resource "incus_instance" "bronya" {
  name = "bronya"
  image = incus_image.bronya.fingerprint
  profiles = [incus_profile.default.name]
  device {
    name = "step_ca_data"
    type = "disk"
    properties = {
      path = "/var/lib/private/step-ca"
      source = incus_storage_volume.step_ca_data.name
      pool = incus_storage_pool.default.name
    }
  }
  device {
    name = "bronya"
    type = "disk"
    properties = {
      path = "/"
      pool = incus_storage_pool.default.name
    }
  }
}
