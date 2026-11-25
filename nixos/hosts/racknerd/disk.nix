# Disco unico /dev/vda. BIOS com GPT: o GRUB precisa da particao bios_boot (EF02).
{
  disko.devices.disk.main = {
    type = "disk";
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        swap = {
          size = "4G";
          priority = 2;
          content.type = "swap";
        };
        root = {
          size = "100%";
          priority = 3;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
