# Podman com uma rede "apps" para os containers. O host e o gateway 10.89.0.1:
# e por ele que os containers chegam ao Postgres nativo.
{ pkgs, lib, config, ... }:
let
  podman = "${pkgs.podman}/bin/podman";
  containerUnits = map (n: "podman-${n}.service") (
    builtins.attrNames config.virtualisation.oci-containers.containers
  );
in
{
  virtualisation.podman = {
    enable = true;
    autoPrune.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };
  virtualisation.oci-containers.backend = "podman";

  systemd.services.podman-network-apps = {
    description = "Rede podman dos apps";
    wantedBy = [ "multi-user.target" ];
    before = containerUnits;
    requiredBy = containerUnits;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      ${podman} network exists apps || ${podman} network create \
        --subnet 10.89.0.0/24 --gateway 10.89.0.1 --interface-name podman-apps apps
    '';
  };

  # Containers chegam ao Postgres do host pela ponte da rede apps.
  networking.firewall.interfaces.podman-apps.allowedTCPPorts = [ 5432 ];
  networking.firewall.interfaces.podman-apps.allowedUDPPorts = [ 53 ];
}
