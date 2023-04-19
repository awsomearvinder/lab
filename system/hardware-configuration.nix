{modulesPath, ...}: {
  imports = [(modulesPath + "/profiles/qemu-guest.nix")];
  boot.loader.grub.device = "nodev";
  boot.loader.timeout = 10;
  boot.loader.grub.forceInstall = true;
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/" = {
    device = "/dev/sda";
    fsType = "ext4";
  };
  swapDevices = [{device = "/dev/sdb";}];
}
