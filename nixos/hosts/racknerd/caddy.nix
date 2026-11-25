# Entradas publicas com HTTPS automatico (Let's Encrypt por HTTP-01), no lugar de Traefik + cert-manager.
{
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        metrics
      }
    '';
    virtualHosts = {
      "nuvem.htrlab.duckdns.org".extraConfig = ''
        request_body {
          max_size 4GB
        }
        redir /.well-known/carddav /remote.php/dav 301
        redir /.well-known/caldav /remote.php/dav 301
        reverse_proxy 127.0.0.1:8081
      '';
      "audio.htrlab.duckdns.org".extraConfig = ''
        reverse_proxy 127.0.0.1:13378
      '';
      "pedidos.htrlab.duckdns.org".extraConfig = ''
        reverse_proxy 127.0.0.1:3030
      '';
      "securo.htrlab.duckdns.org".extraConfig = ''
        @api path /api /api/*
        handle @api {
          reverse_proxy 127.0.0.1:8000
        }
        handle {
          reverse_proxy 127.0.0.1:8082
        }
      '';
      # Home Assistant no casa, pela tailnet.
      "casa.htrlab.duckdns.org".extraConfig = ''
        reverse_proxy 100.112.62.47:8123
      '';
    };
  };
}
