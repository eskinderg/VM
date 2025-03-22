#!/bin/bash

qemu-system-x86_64 \
    -enable-kvm \
    -m 10G \
    -mem-path /dev/myqemuhugepages \
    -mem-prealloc \
    -smp 2,sockets=1,dies=1,cores=2,threads=1 \
    -machine type=q35 \
    -cpu host,+kvm_pv_unhalt,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vpindex=on,hv-synic=on,hv-stimer=on,hv-stimer-direct=on,hv-reset=on,hv-frequencies=on,hv-reenlightenment=on,hv-tlbflush=on,hv-ipi=on \
    -drive file=/mnt/54d34f4b-0246-4c62-ad70-819d091f72db/VD/7050.qcow2,format=qcow2 \
    -name 7050 \
    -usb \
    -device virtio-balloon-pci \
    -display gtk,gl=on \
    -device usb-tablet \
    -device vfio-pci,sysfsdev=/sys/devices/pci0000:00/0000:00:02.0/6a57a4b4-7e69-4038-98ae-5ca73979db06,x-igd-opregion=on,display=on,driver=vfio-pci-nohotplug,ramfb=on \
    -vga none \
    -audiodev pa,id=snd0,server=unix:${XDG_RUNTIME_DIR}/pulse/native \
    -device ich9-intel-hda \
    -device hda-output,audiodev=snd0 \
    # -net nic,model=virtio-net-pci,macaddr=62:54:01:00:00:01 \
    # -net bridge,br=nm-bridge \
    "$@"
