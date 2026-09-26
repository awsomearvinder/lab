{
  config,
  ...
}:
let
  lanAddress = "10.120.0.1/24";
  lanIp = "10.120.0.1";
  webForwardTarget = "10.120.0.101";
  vmSubnet = "10.120.3.0/24";
  vmForwardTarget = "10.120.3.2";
  dhcpOption138Target = "10.120.3.5";
  ulaAddress = "fd8c:ac79:8818::1/64";
  publicIpv6Address = "2a11:6c7:2001:cc00::1/64";
  vmIpv6Subnet = "2a11:6c7:2001:cc01::/64";
  route64Gateway = "2a11:6c7:f03:163::1";
  route64Address = "2a11:6c7:f03:163::2/64";
  bgpPeer = "2a11:6c7:2001:cc00:3256:fff:fe20:8f18";
  bgpAsn = "4261420343";
  wireguardMtu = 1420;
  adguardPort = 19234;
in
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
    networkConfig.IPv6AcceptRA = false;
    networkConfig.IPv6SendRA = false;
    linkConfig.RequiredForOnline = true;
  };
  systemd.network.networks."10-lan" = {
    matchConfig.Name = "eno3";
    linkConfig.RequiredForOnline = true;
    addresses = [
      { Address = lanAddress; }
      { Address = ulaAddress; }
      { Address = publicIpv6Address; }
    ];
    routes = [
      {
        Gateway = route64Gateway;
        Destination = "::/0";
      }
    ];
    networkConfig.DHCP = false;
    networkConfig.DHCPServer = true;
    networkConfig.IPv6AcceptRA = false;
    networkConfig.ConfigureWithoutCarrier = true;
    networkConfig.IPv6SendRA = false;
    networkConfig.DNS = lanIp;
    ipv6SendRAConfig.Managed = false;
    ipv6SendRAConfig.EmitDomains = true;
    ipv6SendRAConfig.Domains = "arvinderd.com";
    ipv6Prefixes = [
      {
        AddressAutoconfiguration = true;
        OnLink = true;
        Prefix = publicIpv6Address;
      }
      {
        AddressAutoconfiguration = true;
        OnLink = true;
        Prefix = ulaAddress;
      }
    ];
    dhcpServerConfig.SendOption = "138:ipv4address:${dhcpOption138Target}";
    dhcpServerConfig.EmitDNS = "yes";
    dhcpServerConfig.DNS = lanIp;
    networkConfig.IPMasquerade = "ipv4";
    # 1-100 is reserved.
    dhcpServerConfig.PoolSize = 99;
    dhcpPrefixDelegationConfig.SubnetId = 0;
  };
  systemd.network.networks."20-eno4" = {
    matchConfig.Name = "eno4";
    linkConfig.RequiredForOnline = false;
  };
  systemd.network.networks."25-eno1" = {
    matchConfig.Name = "eno1";
    linkConfig.RequiredForOnline = false;
  };
  systemd.network.netdevs."30-wireguard-route64" = {
    netdevConfig = {
      Name = "route64";
      Kind = "wireguard";
      MTUBytes = wireguardMtu;
    };
    wireguardConfig = {
      PrivateKeyFile = "${config.age.secrets.wireguardKey.path}";
    };
    wireguardPeers = [
      {
        PublicKey = "j6+IH1aFUqgjQn+pE+3v7WzJSpcqA5KTk3JRcea1TiM=";
        AllowedIPs = "::/0";
        Endpoint = "23.150.41.118:20060";
        PersistentKeepalive = 15;
      }
    ];
  };
  age.secrets.wireguardKey.file = ../secrets/jingliu_wireguard.age;
  age.secrets.wireguardKey.owner = config.users.users.systemd-network.name;
  systemd.network.networks."40-route64" = {
    matchConfig.Name = "route64";
    linkConfig.RequiredForOnline = true;
    addresses = [{ Address = route64Address; }];
    routes = [
      {
        Gateway = route64Gateway;
        Destination = "::/0";
      }
    ];
  };

  services.caddy.acmeCA = "https://bronya.arvinderd.com/acme/ACME/directory";

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
    define HERTA = "${bgpPeer}"
    define HERTA_VMS = { ${vmIpv6Subnet} }
    define WORLD = { "eno2", "route64" }

    table ip portforwards {
      chain PREROUTING {
        type nat hook prerouting priority -100;

        iifname $WORLD tcp dport 80 dnat ${webForwardTarget}:80
        iifname $WORLD tcp dport 443 dnat ${webForwardTarget}:443
        iifname $WORLD udp dport 443 dnat ${webForwardTarget}:443
        iifname $WORLD tcp dport 25565 dnat ${vmForwardTarget}:25565
        iifname $WORLD tcp dport 25567 dnat ${vmForwardTarget}:25567
      }
    }

    table ip6 FW {
      chain FORWARD {
        type filter hook forward priority filter; policy drop;
        ct state established,related accept
        iifname $INTERNAL oifname $INTERNAL counter accept
        ct state invalid counter log prefix "INVALID: " level warn drop
        iifname $INTERNAL oifname $WORLD counter accept
        iifname $INTERNAL ip6 daddr $HERTA_VMS counter accept
        ip6 daddr $HERTA counter accept
        meta l4proto ipv6-icmp counter accept
      }
      chain INCOMING {
        type filter hook input priority filter; policy accept;
        iifname "lo" accept
        tcp dport 22 accept
        tcp dport { 80, 443 } accept
        iifname $INTERNAL tcp dport 179 counter accept
        iifname $INTERNAL tcp dport { 6360, 3890 } accept
        iifname $INTERNAL tcp dport 53 accept
        iifname $INTERNAL udp dport 53 accept
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
        ip daddr ${webForwardTarget} accept
        ip daddr ${vmSubnet} accept
        meta l4proto icmp accept
        counter
      }
      chain INCOMING {
        type filter hook input priority filter; policy drop;
        ct state established,related accept
        ct state invalid counter drop
        meta iifname "lo" accept
        iifname $INTERNAL tcp dport 53 accept
        iifname $INTERNAL udp dport 53 accept
        iifname $INTERNAL tcp dport 22 accept
        iifname $INTERNAL tcp dport 443 accept
        iifname $INTERNAL udp dport 443 accept
        iifname $INTERNAL tcp dport 80 accept
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

    table ip HERTA_NAT {
      chain NAT {
        type nat hook postrouting priority srcnat; policy accept;
        ip saddr ${vmSubnet} oifname $WORLD masquerade
      }
    }
  '';

  services.resolved.enable = true;
  services.frr.bgpd = {
    enable = true;
    options = [
      "--listenon ${publicIpv6Address}"
    ];
  };
  services.frr.config = ''
    interface eno3
      no ipv6 nd suppress-ra
      ipv6 nd prefix ${publicIpv6Address}
      ipv6 nd mtu ${toString wireguardMtu}
    router bgp ${bgpAsn}
      no bgp default ipv4-unicast
      bgp router-id ${lanIp}

      neighbor ${bgpPeer} remote-as ${bgpAsn}
      address-family ipv6 unicast
        neighbor ${bgpPeer} activate
      exit-address-family
      address-family ipv4 unicast
        neighbor ${bgpPeer} activate
      exit-address-family
  '';
  services.adguardhome = {
    enable = true;
    host = "127.0.0.1";
    allowDHCP = false;
    port = adguardPort;
    settings = {
      users = [
        {
          name = "admin";
          password = "$2y$10$6ZghUy5DK.0TSFpG/qdJ8.XrJjHcHmtq5q1dUa8NcPzdgSNvbDO.q";
        }
      ];
      dns = {
        bind_hosts = [ lanIp ];
        port = 53;
      };
    };
  };
  services.caddy.virtualHosts."dns.jingliu.arvinderd.com".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString adguardPort}
  '';
}
