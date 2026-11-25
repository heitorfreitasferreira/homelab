{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "uhci_hcd"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
    "virtio_net"
    "sr_mod"
  ];

  # O disko aponta o GRUB para o disco que tem a particao EF02.
  boot.loader.grub = {
    enable = true;
    efiSupport = false;
  };

  nixpkgs.hostPlatform = "x86_64-linux";
}
