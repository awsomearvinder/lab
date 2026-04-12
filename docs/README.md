So, a couple of my friends have wanted to know how my rhude goldberg machine works.
Here's my attempt at an explanation.

Most all of my homelab is NixOS based. I have a few snippets of terraform, a bit of bash
and there's a few manual steps that have to be done to set it up sadly. With that said,
I'll try to explain everything in terms of the hosts.

# Jingliu
This host is the router for my network. My network is based off of omada APs, and it
has a few key things it runs:

- DNS, from adguard home
- The Omada Controller
- DHCP
- DHv6-PD, so it can get prefixes down for each of it's interfaces.

Currently, it also routes back a static prefix on IPv4 land to herta, so we don't need
to double NAT for herta's containers and VM's. Routing back IPv6 currently is
an unsolved problem. I don't have a really great solution for it as we'd need to
subdelegate an IPv6 prefix from DHCPv6-PD from systemd-networkd down to `herta`,
but currently it seems like that's not a capability `systemd-networkd` supports.
A jank work around in the future might be to give herta a second NIC, put that on
a vlan, and let `systemd-networkd` manage that vlan with it's own `/64`. The containers
could then grab an IPv6 address from `jingliu`'s RA. A bridge network on the herta side
might work for this? But we might have to resort to a macvlan anyways, and it might
make more sense as Incus doesn't really have control over the network in that case
anyways.


# Herta
This host is my physical server. It runs `incus` for it's hypervisor, and provides
SSO through `pocket-id` and `lldap`. There's a bit of manual config needed here
to setup the admin account, as well as connect incus to the oidc provider.

# Incus containers / VMs
These are configured through NixOS. You just import
`${nixpkgs}/nixos/moduels/virtualisation/lxc-container.nix`, and as a result you can
now build an image. For example:

```nix
nixosConfigurations.container = nixpkgs.lib.nixosSystem {
  system = "x86_64-linux";
  modules = [
    "${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
  ];
}
```
combined with:
```bash
nix build .#nixosConfigurations.container.config.system.build.squashfs
nix build .#nixosConfigurations.container.config.system.build.metadata
```
gives you both the metadata and squashfs needed for an LXC container.

Terraform can then push out this image if configured as:
```hcl
resource "incus_image" "container" {
  source_file = {
    # not sure these paths are correct, they're the `.squashfs` and `.tar.xz` in `result/` after
    # the nix build.
    data_path = "${path.root}/result/nixos-lxc-image-x86_64-linux.squashfs"
    metadata_path = "${path.root}/result/nixos-lxc-image-foo.tar.xz"
  }
  # So we rebuild the image when the file above changes.
  lifecycle {
    replace_triggered_by = [
      terraform_data.nixos_image
    ]
  }
}
resource "terraform_data" "image" {
  input = filemd5("${path.root}/result/nixos-lxc-image-x86_64-linux.squashfs")
}
```

Terraform will also automatically replace instances that rely on this image
for you.

The building of the image for this repository is automated by the `justfile`,
so you can just do `just build_image $HOST`, followed by `tofu apply`.

The `justfile` also modifies the image to put the SSH key for the host into
the image, which is useful as we use `agenix` to manage secrets. As a result
`agenix` can use the host SSH keys to decrypt the secrets, and the nix services
that reference them can then read them.

# Other tidbits and moving parts.

You probably want your host to automatically setup DNS. For that, we turn off privacy
addresses for IPv6 and push out addresses to porkbun. This uses oink, and is automatically
configured by `lib/ddns.nix`. In order for it to work, make sure the host can decrypt
the oink secrets in the `secrets/` folder, by modifying `secrets.nix`. You'll also
have to run `nix run github:ryantm/agenix -- -r` after to rekey the files.
