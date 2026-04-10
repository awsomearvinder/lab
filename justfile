default:
    just --list

deploy HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host root@{{ HOST }}.arvinderd.com

build_image HOST:
    #!/usr/bin/env -S sudo bash
    mkdir -p build
    img=$(nix build .#nixosConfigurations.{{ HOST }}.config.system.build.squashfs --print-out-paths)
    metadata=$(nix build .#nixosConfigurations.{{ HOST }}.config.system.build.metadata --print-out-paths)
    SSH_KEY=$(dotenvx get {{ uppercase(HOST) }}_SSH_KEY)
    SSH_KEY_PUB=$(dotenvx get {{ uppercase(HOST) }}_SSH_KEY_PUB)

    # To make sure we add a write permission to any previously written build/
    # This way, even if script crashes the next time we run it, we can still overwrite it.
    # If it's a post mod, it could be problematic for the following build.
    chmod -R ug+w "build/"
    cp "$img/nixos-lxc-image-x86_64-linux.squashfs" ./build/nixos-lxc-image-x86_64-linux.{{ HOST }}.squashfs
    cp "$metadata/tarball/"*.xz build/nixos-container-img.{{ HOST }}.metadata.tar.xz

    mkdir -p ./build/tmp/{{ HOST }}
    mv ./build/nixos-lxc-image-x86_64-linux.{{ HOST }}.squashfs ./build/tmp/{{ HOST }}/
    cd ./build/tmp/{{ HOST }}/
    trap "chmod 775 -R squashfs-root && rm -rf squashfs-root" 0
    unsquashfs nixos-lxc-image-x86_64-linux.{{ HOST }}.squashfs

    
    mkdir -p ./squashfs-root/etc/ssh/
    echo "$SSH_KEY" > ./squashfs-root/etc/ssh/ssh_host_ed25519_key
    chmod 0600 ./squashfs-root/etc/ssh/ssh_host_ed25519_key

    echo $SSH_KEY_PUB > ./squashfs-root/etc/ssh/ssh_host_ed25519_key.pub
    chmod 0644 ./squashfs-root/etc/ssh/ssh_host_ed25519_key.pub

    mksquashfs ./squashfs-root nixos-lxc-image-x86_64-linux.{{ HOST }}-build.squashfs -comp xz
    rm nixos-lxc-image-x86_64-linux.{{ HOST }}.squashfs

    mv ./nixos-lxc-image-x86_64-linux.{{ HOST }}-build.squashfs ../..

deploy_tf:
    tofu apply
