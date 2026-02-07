{
  pkgs,
  config,
  lib,
  ...
}:
{
  boot.kernel.sysctl = {
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "net.ipv6.conf.eno2.accept_ra" = 2;
    "net.ipv6.conf.eno2.autoconf" = 1;
    "net.ipv6.conf.eno2.accept_ra_pinfo" = 1;
  };
  systemd.network.enable = true;

  systemd.network.networks."0-wan" = {
    matchConfig.Name = "eno2";
    networkConfig.DHCP = "ipv4";
    networkConfig.DHCPServer = false;
    networkConfig.IPv6AcceptRA = true;
    networkConfig.IPv6SendRA = false;
    networkConfig.IPMasquerade = true;
    dhcpV6Config = {
      PrefixDelegationHint = "::/60";
    };
  };
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "eno3";
    addresses = [
      { Address = "10.120.0.1/24"; }
      { Address = "fd8c:ac79:8818::/64"; }
    ];
    networkConfig.DHCP = false;
    networkConfig.DHCPServer = true;
    networkConfig.IPv6AcceptRA = false;
    networkConfig.ConfigureWithoutCarrier = true;
    networkConfig.IPv6SendRA = true;
    networkConfig.DHCPPrefixDelegation = true;
    networkConfig.DNS = "10.120.0.1";
    dhcpServerConfig.SendOption = "138:ipv4address:10.120.0.1";
    dhcpServerConfig.EmitDNS = "yes";
    dhcpServerConfig.DNS = "10.120.0.1";
    dhcpPrefixDelegationConfig.SubnetId = 0;
  };
  systemd.network.networks."20-omada" = {
    matchConfig.Name = "eno4";
    addresses = [
      { Address = "10.120.1.1/24"; }
      { Address = "fd8c:ac79:8818:1:/64"; }
    ];
    networkConfig.DHCP = false;
    networkConfig.DHCPServer = true;
    networkConfig.IPv6AcceptRA = false;
    networkConfig.ConfigureWithoutCarrier = true;
    networkConfig.IPv6SendRA = true;
    networkConfig.DHCPPrefixDelegation = true;
    networkConfig.DNS = "10.120.0.1";
    dhcpServerConfig.SendOption = "138:ipv4address:10.120.0.1";
    dhcpServerConfig.EmitDNS = "yes";
    dhcpServerConfig.DNS = "10.120.0.1";
    dhcpPrefixDelegationConfig.SubnetId = 1;
  };
  virtualisation.oci-containers.containers.omada-sdn = {
    image = "mbentley/omada-controller:5.15";
    extraOptions = [
      "--ulimit"
      "nofile=4096:8192"
    ];
    environment = {
      TZ = "America/Chicago";
    };
    ports = [
      "10.120.0.1:8088:8088"
      "10.120.0.1:8043:8043"
      "10.120.0.1:8843:8843"
      "10.120.0.1:19810:19810/udp"
      "10.120.0.1:27001:27001/udp"
      "10.120.0.1:29810:29810/udp"
      "10.120.0.1:29811-29816:29811-29816"
    ];
    volumes = [
      "/persist/omada-controller/data:/opt/tplink/EAPController/data"
      "/persist/omada-controller/logs:/opt/tplink/EAPController/logs"
    ];
  };

  services.caddy.virtualHosts."omada.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy https://10.120.0.1:8043 {
      transport http {
        tls
        tls_insecure_skip_verify
      }
    }
  '';

  systemd.network.netdevs."proxbr0" = {
    netdevConfig = {
      Name = "proxbr0";
      Kind = "bridge";
    };
  };
  systemd.network.networks."40-proxmox" = {
    matchConfig.Name = "proxbr0";
    addresses = [
      { Address = "10.120.110.1/24"; }
      { Address = "fd8c:ac79:8818:2:/64"; }
    ];
    networkConfig.DHCP = false;
    networkConfig.DHCPServer = true;
    networkConfig.IPv6AcceptRA = false;
    networkConfig.ConfigureWithoutCarrier = true;
    networkConfig.IPv6SendRA = true;
    networkConfig.DHCPPrefixDelegation = true;
    dhcpServerConfig.EmitDNS = "yes";
    dhcpServerConfig.DNS = "10.120.0.1";
    dhcpServerConfig.PoolOffset = 0;
    dhcpServerConfig.PoolSize = 100;
    dhcpPrefixDelegationConfig.SubnetId = 3;
  };

  environment.persistence."/persist".directories = [
    {
      directory = "/persist/omada-controller/data";
      mode = "0777";
    }
    {
      directory = "/persist/omada-controller/logs";
      mode = "0777";
    }
    {
      directory = "/var/lib/private/AdGuardHome";
      mode = "0777";
    }
  ];
  networking.useDHCP = false;
  networking.firewall.enable = false;
  networking.nftables.enable = true;
  networking.nftables.checkRuleset = true;
  networking.nftables.ruleset = ''
    define INTERNAL = { "podman0", "eno3", "eno4", "proxbr0"}
    define WORLD = { "eno2" }
    table ip6 FW {
        chain FORWARD {
            type filter hook forward priority filter; policy drop;
            ct state established,related accept
            ct state invalid counter drop
            iifname $INTERNAL oifname $WORLD  counter accept
            iifname $INTERNAL oifname "proxbr0" counter accept
            meta l4proto ipv6-icmp counter accept
        }
        chain INCOMING {
            type filter hook input priority filter; policy accept;
            iifname "lo" accept
            tcp dport 22 accept
            tcp dport { 80, 443 } accept

            # LDAP
            iifname $INTERNAL tcp dport { 6360, 3890 } accept
            tcp dport { 80, 443 } accept

            # DNS
            iifname $INTERNAL tcp dport { 53 } accept
            iifname $INTERNAL udp dport { 53 } accept

            meta l4proto ipv6-icmp accept
            ct state established,related accept
            ct state invalid counter drop
            counter
        }

        chain OUTGOING {
            type filter hook output priority filter; policy accept;
        }
    }

    table ip FW {
    	 chain FORWARD {
            type filter hook forward priority filter; policy drop;
            ct state established,related accept
            ct state invalid counter drop
            iifname $INTERNAL oifname $WORLD counter accept
            iifname $INTERNAL oifname "podman0" counter accept
            iifname $INTERNAL oifname "proxbr0" counter accept
            meta l4proto icmp accept
            counter
    	 }
      chain INCOMING {
          type filter hook input priority filter; policy drop;
          tcp dport 22 accept

          meta iifname "lo" accept

          # LDAP
          iifname $INTERNAL tcp dport { 6360, 3890 } accept
          tcp dport { 80, 443 } accept

          # DNS
          iifname $INTERNAL tcp dport { 53 } accept
          iifname $INTERNAL udp dport { 53 } accept

          udp dport 67 accept
          meta l4proto icmp accept
          ct state established,related accept
          ct state invalid counter drop
          counter
      }
      chain OUTGOING {
          type filter hook output priority filter; policy accept;
      }
    }

  '';
  virtualisation.containers.containersConf.settings.network.network_backend =
    lib.mkDefault "netavark";
  virtualisation.containers.containersConf.settings.network.firewall_driver =
    lib.mkDefault "nftables";
  virtualisation.podman.extraPackages = [ pkgs.nftables ];

  networking.nat = {
    enable = true;
    externalInterface = "eno2";
    internalInterfaces = [
      "eno1"
      "eno3"
      "eno4"
      "proxbr0"
    ];
  };

  services.resolved.enable = true;

  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    allowDHCP = false;
    port = 19234;
    settings = {
      users = [
        {
          name = "admin";
          password = "$2y$10$6ZghUy5DK.0TSFpG/qdJ8.XrJjHcHmtq5q1dUa8NcPzdgSNvbDO.q";
        }
      ];
      dns = {
        bind_hosts = [
          # we block this using the fw, so we all good.
          "10.120.0.1"
        ];
        port = 53;
      };
    };
  };
  services.caddy.virtualHosts."dns.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy http://127.0.0.1:19234 {
      
    }
  '';
}
