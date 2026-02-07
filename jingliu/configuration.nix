# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./applications/gitea.nix
    ./applications/jellyfin.nix
    ./proxmox.nix
    ./auth.nix
    ./incus.nix
    ./router.nix
    ./applications/vikunja.nix
    ./applications/actual.nix
    ./applications/paperless.nix
    ../lib/base.nix
  ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda";

  networking.hostName = "jingliu"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  # time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  nixpkgs.config.allowUnfree = true;
  nix.trustedUsers = [
    "root"
    "@wheel"
  ];

  # I should really move the ddns and jellyfin stuff into their own files.
  environment.persistence."/persist" = {
    enable = true;
    hideMounts = true;
    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      {
        directory = "/var/lib/caddy";
        user = "caddy";
        group = "caddy";
      }
      "/etc/nixos"
      {
        directory = "/etc/ssh";
        user = "root";
        group = "root";
        mode = "0755";
      }
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  services.caddy = {
    enable = true;
    package = pkgs.caddy;
    # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    globalConfig = ''
      debug
    '';
    #   virtualHosts."testing.arvinderd.com".extraConfig = ''
    #     	# define forward auth for any path under `/`, if not more specific defined
    #     	forward_auth / http://127.0.0.1:8098 {
    #     		uri /oauth2/auth
    #     		copy_headers Authorization X-Auth-Request-User X-Auth-Request-Email
    #     		@error status 401
    #     		handle_response @error {
    #     			redir https://oauth2proxy.arvinderd.com/oauth2/sign_in?rd={http.request.scheme}://{http.request.host}/{http.request.uri}
    #     		}
    #     	}

    #     	# define `/oauth2/*` as specific endpoint, to avoid forward auth protection to be able to use service
    #     	reverse_proxy /oauth2/* http://127.0.0.1:8098 {
    #     	}

    #       root * /var/www/html
    #       file_server browse
    #   '';
  };

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # hardware.pulseaudio.enable = true;
  # OR
  # services.pipewire = {
  #   enable = true;
  #   pulse.enable = true;
  # };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.bender = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "jellyfin"
    ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      helix
    ];
    hashedPassword = "$2b$05$yD7fJ/khkd/SwvlxilTLYuHCTOhWFqZuV6aDSdlTccO0q9I2YxT6O";
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  #   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #   wget
  # ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
    5800
  ];
  networking.firewall.allowedUDPPorts = [ 443 ];
  # networking.firewall.interfaces."podman-+".allowedUDPPorts = [ 53 ];
  # networking.tempAddresses = "disabled";

  # networking.interfaces.eno1.ipv4.addresses = [
  #   {
  #     address = "10.120.1.101";
  #     prefixLength = 24;
  #   }
  # ];
  # networking.interfaces.eno1.useDHCP = true;
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
