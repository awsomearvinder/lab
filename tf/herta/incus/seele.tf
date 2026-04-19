resource "incus_storage_volume" "seele_jellyfin" {
  name = "seele_jellyfin"
  pool = incus_storage_pool.default.name
}
resource "incus_image" "seele" {
  source_file = {
    data_path = "${path.root}/build/nixos-lxc-image-x86_64-linux.seele-build.squashfs"
    metadata_path = "${path.root}/build/nixos-container-img.seele.metadata.tar.xz"
  }

  lifecycle {
    replace_triggered_by = [
      terraform_data.seele
    ]
  }
}
resource "terraform_data" "seele" {
  input = filemd5("${path.root}/build/nixos-lxc-image-x86_64-linux.seele-build.squashfs")
}

resource "incus_instance" "seele" {
  name = "seele"
  image = incus_image.seele.fingerprint
  profiles = [incus_profile.default.name]
  device {
    name = "seele"
    type = "disk"
    properties = {
      path = "/"
      pool = incus_storage_pool.default.name
    }
  }
  device {
    name = "seele_jellyfin"
    type = "disk"
    properties = {
      source = incus_storage_volume.seele_jellyfin.name
      path = "/var/lib/jellyfin"
      pool = incus_storage_pool.default.name
    }
  }
  device {
    name = "jellyfin_gpu"
    type = "gpu"
    properties = {
      vendorid = "1002"
      productid = "13c0"
    }
  }
}
