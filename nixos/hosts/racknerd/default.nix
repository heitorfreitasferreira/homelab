# VPS RackNerd: 5 vCPU, 6 GB, 100 GB, KVM com BIOS (sem UEFI), IP estatico.
{ ... }:
{
  imports = [
    ./disk.nix
    ./hardware.nix
    ./network.nix
    ./containers.nix
    ./postgres.nix
    ./caddy.nix
    ./tailscale-services.nix
    ./nextcloud.nix
    ./securo.nix
    ./waha.nix
    ./pihole.nix
    ./audiobooks.nix
    ./homepage.nix
    ./monitoring.nix
    ./agents.nix
    ./backup.nix
  ];

  networking.hostName = "racknerd";
}
