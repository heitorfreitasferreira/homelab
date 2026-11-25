# Pi-hole: DNS global da tailnet (decisao 18), preso a tailscale0 (100.104.129.86), sem porta 53 publica.
# Web na 8053 do host, publicada na tailnet como svc:pihole.
{ config, pkgs, ... }:
{
  virtualisation.oci-containers.containers.pihole = {
    image = "jacklul/pihole:2026.11.0@sha256:49b9b92527a1675752181a71f966e0f3aecee5b773e94ac2e461e43d8351a74f";
    volumes = [
      "/srv/pihole/etc:/etc/pihole"
      "${../../../apps/pihole/adlists.txt}:/etc/adlists/adlists.txt:ro"
    ];
    environment = {
      TZ = "America/Sao_Paulo";
      FTLCONF_dns_listeningMode = "BIND";
      FTLCONF_dns_interface = "tailscale0";
      FTLCONF_dns_upstreams = "1.1.1.1;9.9.9.9";
      FTLCONF_misc_dnsmasq_lines = "server=/tail76c1c6.ts.net/100.100.100.100";
      FTLCONF_webserver_port = "8053";
      FTLCONF_database_maxDBdays = "30";
      BLOCKLISTS_URL = "/etc/adlists/adlists.txt";
      COMMENT = "Managed by pihole-updatelists";
      CRONTAB_STRING = "25 3 * * 6";
    };
    environmentFiles = [ config.sops.templates."pihole.env".path ];
    extraOptions = [
      "--network=host"
      "--cap-add=NET_ADMIN"
      "--cap-add=SYS_NICE"
    ];
  };

  # So sobe com o IP da tailnet na interface: o modo BIND falha sem ele.
  systemd.services.podman-pihole = {
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    # Espera ate 2 min pelo IP; depois falha e o Restart do servico tenta de novo.
    serviceConfig.ExecStartPre = [
      (pkgs.writeShellScript "pihole-espera-tailscale0" ''
        for _ in $(${pkgs.coreutils}/bin/seq 60); do
          ${pkgs.iproute2}/bin/ip -4 addr show tailscale0 2>/dev/null | ${pkgs.gnugrep}/bin/grep -q 100.104.129.86 && exit 0
          sleep 2
        done
        echo "tailscale0 sem 100.104.129.86" >&2
        exit 1
      '')
    ];
  };

  sops.secrets."pihole_password" = { };
  sops.templates."pihole.env".content = ''
    FTLCONF_webserver_api_password=${config.sops.placeholder."pihole_password"}
  '';

  systemd.tmpfiles.rules = [ "d /srv/pihole/etc 0755 root root -" ];
}
