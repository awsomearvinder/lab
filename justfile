default:
    just --list

deploy HOST:
    nixos-rebuild switch --flake .#{{ HOST }} --target-host root@{{ HOST }}.arvinderd.com
