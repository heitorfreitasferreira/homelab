#!/usr/bin/env bash
# Local Debian 13 VM (libvirt, NAT "default") that mirrors the RackNerd box for testing the playbook.
# Same shape: 5 vCPU, 6 GiB RAM. Fresh-install state: only root with the SSH key, like the provider.
# Usage: scripts/lab-vm.sh up|ip|down
set -euo pipefail

NAME=homelab-lab
DIR="${XDG_DATA_HOME:-$HOME/.local/share}/homelab-lab"
IMG_URL=https://cloud.debian.org/images/cloud/trixie/latest/debian-13-genericcloud-amd64.qcow2
URI=qemu:///system
PUBKEY="$(cat "$HOME/.ssh/id_ed25519.pub")"

vm_ip() {
  virsh -c "$URI" domifaddr "$NAME" --source lease 2>/dev/null | awk '/ipv4/ {sub(/\/.*/, "", $4); print $4; exit}'
}

case "${1:-}" in
  up)
    mkdir -p "$DIR"
    [ -f "$DIR/base.qcow2" ] || curl -fL -o "$DIR/base.qcow2" "$IMG_URL"
    rm -f "$DIR/disk.qcow2"
    qemu-img create -q -f qcow2 -F qcow2 -b "$DIR/base.qcow2" "$DIR/disk.qcow2" 40G
    cat > "$DIR/user-data" <<EOF
#cloud-config
disable_root: false
users:
  - name: root
    ssh_authorized_keys: ["$PUBKEY"]
ssh_pwauth: false
EOF
    printf 'instance-id: %s\nlocal-hostname: %s\n' "$NAME-$(date +%s)" "$NAME" > "$DIR/meta-data"
    genisoimage -quiet -output "$DIR/seed.iso" -volid cidata -joliet -rock "$DIR/user-data" "$DIR/meta-data"
    chmod 644 "$DIR/disk.qcow2" "$DIR/seed.iso"
    cat > "$DIR/domain.xml" <<EOF
<domain type='kvm'>
  <name>$NAME</name>
  <memory unit='GiB'>6</memory>
  <vcpu>5</vcpu>
  <os firmware='efi'>
    <type arch='x86_64' machine='q35'>hvm</type>
    <firmware><feature enabled='no' name='secure-boot'/></firmware>
  </os>
  <features><acpi/><apic/></features>
  <cpu mode='host-passthrough'/>
  <devices>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/><source file='$DIR/disk.qcow2'/><target dev='vda' bus='virtio'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/><source file='$DIR/seed.iso'/><target dev='sda' bus='sata'/><readonly/>
    </disk>
    <interface type='network'><source network='default'/><model type='virtio'/></interface>
    <serial type='pty'/><console type='pty'/>
  </devices>
</domain>
EOF
    virsh -c "$URI" define "$DIR/domain.xml" >/dev/null
    virsh -c "$URI" start "$NAME" >/dev/null
    for _ in $(seq 60); do ip=$(vm_ip); [ -n "$ip" ] && break; sleep 3; done
    [ -n "${ip:-}" ] || { echo "VM sem IP apos 180s" >&2; exit 1; }
    ssh-keygen -R "$ip" >/dev/null 2>&1 || true
    for _ in $(seq 40); do ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -o ConnectTimeout=3 "root@$ip" true 2>/dev/null && break; sleep 3; done
    echo "$ip"
    ;;
  ip) vm_ip ;;
  down)
    virsh -c "$URI" destroy "$NAME" >/dev/null 2>&1 || true
    virsh -c "$URI" undefine --nvram "$NAME" >/dev/null 2>&1 || true
    rm -f "$DIR/disk.qcow2" "$DIR/seed.iso"
    ;;
  *) echo "uso: $0 up|ip|down" >&2; exit 2 ;;
esac
