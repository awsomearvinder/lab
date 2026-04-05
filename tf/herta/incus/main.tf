terraform {
  required_providers {
    incus = {
      source = "lxc/incus"
      version = "1.0.2"
    }
  }
}
provider  "incus" {
  generate_client_certificates = true
  default_remote = "herta"
}
