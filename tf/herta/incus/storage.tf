resource "incus_storage_pool" "default" {
  name = "default"
  driver = "btrfs"
  config = {
    "btrfs.mount_options" = "compress=zstd"
    size = "100GiB"
  }
}
