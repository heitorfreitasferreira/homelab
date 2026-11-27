# Entradas publicas com HTTPS automatico (Let's Encrypt por HTTP-01), no lugar de Traefik + cert-manager.
{ config, ... }:
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
      # WAHA so de leitura para o bot Hilbert: GET de conversas e mensagens, com a chave
      # injetada aqui. O perfil dele nao tem a chave inteira, entao nao consegue enviar.
      "http://127.0.0.1:3002".extraConfig = ''
        @leitura {
          method GET
          path /api/heitor/chats*
        }
        handle @leitura {
          reverse_proxy 127.0.0.1:3001 {
            header_up X-Api-Key {env.WAHA_API_KEY}
          }
        }
        handle {
          respond "somente leitura" 403
        }
      '';
    };
  };

  # A chave vai no ambiente do caddy, nunca no Store.
  systemd.services.caddy.serviceConfig.EnvironmentFile = config.sops.templates."waha-readonly.env".path;
  sops.templates."waha-readonly.env".content = ''
    WAHA_API_KEY=${config.sops.placeholder."waha_api_key"}
  '';
}
