{
  pkgs,
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
  };
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "eno3";
    addresses = [
      { Address = "10.120.0.1/24"; }
      { Address = "fd8c:ac79:8818::/64"; }
      { Address = "2a11:6c7:f35:b801::1/64"; }
    ];
    routes = [
      {
        Gateway = "10.120.0.101";
        Destination = "10.120.3.0/24";
      }
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
    networkConfig.IPMasquerade = "ipv4";
    # 1-100 is reserved.
    dhcpServerConfig.PoolSize = 99;
    dhcpPrefixDelegationConfig.SubnetId = 0;
  };
  systemd.network.networks."20-omada" = {
    matchConfig.Name = "eno4";
    addresses = [
      { Address = "10.120.1.1/24"; }
      { Address = "fd8c:ac79:8818:1::/64"; }
    ];
    networkConfig.DHCP = false;
    networkConfig.DHCPServer = true;
    networkConfig.IPv6AcceptRA = false;
    networkConfig.ConfigureWithoutCarrier = true;
    networkConfig.IPv6SendRA = true;
    networkConfig.DHCPPrefixDelegation = true;
    networkConfig.DNS = "10.120.0.1";
    networkConfig.IPMasquerade = "ipv4";
    dhcpServerConfig.SendOption = "138:ipv4address:10.120.0.1";
    dhcpServerConfig.EmitDNS = "yes";
    dhcpServerConfig.DNS = "10.120.0.1";
    dhcpPrefixDelegationConfig.SubnetId = 1;
  };
  systemd.network.netdevs."30-6in4" = {
    netdevConfig = {
      Name = "route64";
      Kind = "sit";
      MTUBytes = 1480;
    };
    tunnelConfig = {
      Remote = "23.154.9.27";
      Local = "any";
      TTL = 128;
      Independent = true;
    };
  };
  systemd.network.networks."40-route64" = {
    matchConfig.Name = "route64";
    linkConfig.RequiredForOnline = true;
    addresses = [
      { Address = "2a11:6c7:f35:b8::2/64"; }
    ];
    routes = [
      {
        Gateway = "2a11:6c7:f35:b8::1";
        Destination = "::/0";
      }
    ];
  };
  virtualisation.oci-containers.containers.omada-sdn = {
    image = "mbentley/omada-controller:6";
    extraOptions = [
      "--ulimit"
      "nofile=4096:8192"
      "--network=host"
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

  services.caddy.acmeCA = "https://bronya.arvinderd.com/acme/ACME/directory";
  services.caddy.virtualHosts."omada.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy https://127.0.0.1:8043 {
      transport http {
        tls
        tls_insecure_skip_verify
      }
    }
  '';

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
    define INTERNAL = { "podman0", "eno3", "eno4" }
    define HERTA = "2601:447:ce80:4020:3256:fff:fe20:8f18"
    define WORLD = { "eno2" }

    table ip portforwards {
      chain PREROUTING {
        type nat hook prerouting priority -100;

        iifname $WORLD tcp dport 80 dnat 10.120.0.101:80
        iifname $WORLD tcp dport 443 dnat 10.120.0.101:443
        iifname $WORLD udp dport 443 dnat 10.120.0.101:443
        iifname $WORLD tcp dport 25565 dnat 10.120.0.101:25565
      }
    }

    table ip6 FW {
        chain FORWARD {
            type filter hook forward priority filter; policy drop;
            ct state established,related accept
            ct state invalid counter drop
            iifname $INTERNAL oifname $WORLD  counter accept
            ip6 daddr $HERTA counter accept
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
            ip daddr 10.120.0.101 accept
            ip daddr 10.120.3.0/24 accept
            meta l4proto icmp accept
            counter
    	 }
      chain INCOMING {
          type filter hook input priority filter; policy drop;
          ct state established,related accept
          ct state invalid counter drop
          meta iifname "lo" accept

          # DNS
          iifname $INTERNAL tcp dport { 53 } accept
          iifname $INTERNAL udp dport { 53 } accept
          iifname $INTERNAL tcp dport { 22 } accept
          iifname $INTERNAL tcp dport { 443 } accept
          iifname $INTERNAL udp dport { 443 } accept
          iifname $INTERNAL tcp dport { 80 } accept

          ip protocol 41 ip saddr 23.154.9.27 accept

          iifname $INTERNAL tcp dport { 29810, 29811-29817, 8043, 8843, 8088 } accept
          iifname $INTERNAL udp dport { 19810, 27001, 29810, 29811-29817 } accept
          udp dport 67 accept
          meta l4proto icmp accept
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
