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
}
