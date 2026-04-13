default:
    just --list

deploy HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host root@{{ HOST }}.arvinderd.com

add_incus_container HOST:
    #!/usr/bin/env bash

    # Generate keys
    ssh-keygen -t ed25519 -f "./build/{{ HOST }}-ed25519" -q -N ""
    HOST_KEY=$(cat "./build/{{ HOST }}-ed25519")
    HOST_KEY_PUB=$(cat "./build/{{ HOST }}-ed25519.pub")
    trap "cd {{ justfile_directory() }} && rm ./build/{{ HOST }}-ed25519{,.pub}" EXIT

    # Add keys if they don't exist.
    [[ -z "$(dotenvx get {{ uppercase(HOST) }}_SSH_KEY)" ]] && \
      dotenvx set {{ uppercase(HOST) }}_SSH_KEY -- "$HOST_KEY" && \
      dotenvx set {{ uppercase(HOST) }}_SSH_KEY_PUB "$HOST_KEY_PUB" --plain

    HOST_KEY="$(dotenvx get {{ uppercase(HOST)}}_SSH_KEY)"
    HOST_KEY_PUB="$(dotenvx get {{ uppercase(HOST)}}_SSH_KEY_PUB)"

    # Create terraform.
    [ -f "./tf/herta/incus/{{ HOST }}.tf" ] || \
    cat <<EOM > tf/herta/incus/{{ HOST }}.tf
    resource "incus_image" "{{ HOST }}" {
      source_file = {
        data_path = "\${path.root}/build/nixos-lxc-image-x86_64-linux.{{ HOST }}-build.squashfs"
        metadata_path = "\${path.root}/build/nixos-container-img.{{ HOST }}.metadata.tar.xz"
      }

      lifecycle {
        replace_triggered_by = [
          terraform_data.{{ HOST }}
        ]
      }
    }
    resource "terraform_data" "{{ HOST }}" {
      input = filemd5("\${path.root}/build/nixos-lxc-image-x86_64-linux.{{ HOST }}-build.squashfs")
    }

    resource "incus_instance" "{{ HOST }}" {
      name = "{{ HOST }}"
      image = incus_image.{{ HOST }}.fingerprint
      profiles = [incus_profile.default.name]
      device {
        name = "{{ HOST }}"
        type = "disk"
        properties = {
          path = "/"
          pool = incus_storage_pool.default.name
        }
      }
    }
    EOM

    # modify nix files.
    [ -d "./{{ HOST }}" ] || mkdir "{{ HOST }}"
    [ -f "./{{ HOST }}/configuration.nix" ] || echo " { ... }: {}" > "./{{ HOST }}/configuration.nix"

    if ! grep -q "nixosConfigurations.{{ HOST }}" ./flake.nix; then
        awk -i inplace '
            /.*nixosConfigurations.*/ {
                if (count == 0) {
                    print "      nixosConfigurations.{{ HOST }} = nixpkgs.lib.nixosSystem {"
                    print "        system = \"x86_64-linux\";"
                    print "        modules = ["
                    print "          ./lib/base.nix"
                    print "          \"${nixpkgs}/nixos/modules/virtualisation/lxc-container.nix\""
                    print "          ./{{ HOST }}/configuration.nix"
                    print "          agenix.nixosModules.default"
                    print "        ];"
                    print "      };"
                    count++
                }
            }
            { print }
        ' ./flake.nix
    fi

    # add to secrets.nix so ddns works ootb.
    cd secrets/
    if ! grep -q "{{ HOST }}" ./secrets.nix; then
        awk -i inplace '/^in$/ {
            if (count == 0) {
                print "  {{ HOST }} = \"'"$HOST_KEY_PUB"'\";";
                count++
            }
        } 1' ./secrets.nix
        awk -i inplace '/oink.*.age/ {
            print;
            print "    {{ HOST }}";
            next;
        } 1' ./secrets.nix
        agenix -r
    fi

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
