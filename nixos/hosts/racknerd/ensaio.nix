# Ensaio local da virada: a config do racknerd numa VM, sem tocar a producao.
# Mesmo disco, boot, rede (IP e MAC) e apps. Desligado aqui o que escreve fora da VM
# ou disputa identidade com o racknerd real.
{ lib, ... }:
{
  # GitOps puxaria o main; o ensaio fica na config local.
  services.comin.enable = lib.mkForce false;

  # Nada de R2: sem WAL arquivado, sem base do wal-g, sem restic.
  services.postgresql.settings.archive_mode = lib.mkForce "off";
  systemd.timers.wal-g-backup.enable = false;
  services.restic.backups = lib.mkForce { };

  # Nada de Telegram nem Healthchecks.
  services.prometheus.alertmanager.enable = lib.mkForce false;

  # O cron do Nextcloud apaga e gera objetos no bucket de producao.
  systemd.timers.nextcloud-cron.enable = false;

  # Bot do Telegram e sessao do WhatsApp sao unicos: so a producao conecta.
  systemd.services.hermes-gateway.wantedBy = lib.mkForce [ ];
  systemd.services.hermes-dashboard.wantedBy = lib.mkForce [ ];
  systemd.services.opencode.wantedBy = lib.mkForce [ ];
  virtualisation.oci-containers.containers.waha.autoStart = false;
  # O worker do Securo consome a fila restaurada do Redis e chama a Pluggy de verdade.
  virtualisation.oci-containers.containers.securo-worker.autoStart = false;
  virtualisation.oci-containers.containers.waha-redis.autoStart = false;

  # Sem a identidade da tailnet: sem Tailscale Services, o Pi-hole escuta na placa da VM e
  # os certificados sao locais.
  systemd.services.tailscale-services.wantedBy = lib.mkForce [ ];
  virtualisation.oci-containers.containers.pihole.environment.FTLCONF_dns_interface = lib.mkForce "ens3";
  systemd.services.podman-pihole.serviceConfig.ExecStartPre = lib.mkForce [ ];
  services.caddy.globalConfig = lib.mkForce ''
    local_certs
    servers {
      metrics
    }
  '';

  users.users.htr.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9zm+7+Y7CRFmkJp07nANtTwz0wyBgsTWxkh7oqPR5U ensaio-racknerd"
  ];
  # So no ensaio: root por chave e kernel na serial, para depurar a VM.
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA9zm+7+Y7CRFmkJp07nANtTwz0wyBgsTWxkh7oqPR5U ensaio-racknerd"
  ];
  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  boot.kernelParams = [ "console=ttyS0,115200" ];
}
