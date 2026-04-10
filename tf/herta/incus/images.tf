resource "incus_image" "nixos" {
  source_file = {
    data_path = "${path.root}/build/nixos-lxc-image-x86_64-linux.phainon-build.squashfs"
    metadata_path = "${path.root}/build/nixos-container-img.phainon.metadata.tar.xz"
  }

  lifecycle {
    replace_triggered_by = [
      terraform_data.image
    ]
  }
}
resource "terraform_data" "image" {
  input = filemd5("${path.root}/build/nixos-lxc-image-x86_64-linux.phainon-build.squashfs")
}
