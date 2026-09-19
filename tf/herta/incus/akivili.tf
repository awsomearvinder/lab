resource "incus_storage_volume" "akivili_omada" {
  name = "akivili_omada"
  pool = incus_storage_pool.default.name
}

resource "incus_image" "akivili" {
  source_file = {
    data_path = "${path.root}/build/nixos-lxc-image-x86_64-linux.akivili-build.squashfs"
    metadata_path = "${path.root}/build/nixos-container-img.akivili.metadata.tar.xz"
  }

  lifecycle {
    replace_triggered_by = [
      terraform_data.akivili
    ]
  }
}

resource "terraform_data" "akivili" {
  input = filemd5("${path.root}/build/nixos-lxc-image-x86_64-linux.akivili-build.squashfs")
}

resource "incus_instance" "akivili" {
  name = "akivili"
  image = incus_image.akivili.fingerprint
  profiles = [incus_profile.default.name]
  device {
    name = "akivili"
    type = "disk"
    properties = {
      path = "/"
      pool = incus_storage_pool.default.name
    }
  }
  device {
    name = "akivili_omada"
    type = "disk"
    properties = {
      source = incus_storage_volume.akivili_omada.name
      path = "/var/lib/omada"
      pool = incus_storage_pool.default.name
    }
  }
}
