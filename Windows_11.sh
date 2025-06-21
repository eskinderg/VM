#!/bin/bash

UUID="6a57a4b4-7e69-4038-98ae-5ca73979db06"

# Create vGPU via sudo helper script
sudo /usr/local/bin/manage-vgpu.sh create

echo "VGPU Created"

taskset -c 2,3 qemu-system-x86_64 \
  -enable-kvm \
  -m 10G \
  -smp 2,sockets=1,dies=1,cores=2,threads=1 \
  -machine type=q35,accel=kvm,usb=off \
  -cpu host,+invtsc,+kvm_pv_unhalt,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vpindex=on,hv-synic=on,hv-stimer=on,hv-stimer-direct=on,hv-reset=on,hv-frequencies=on,hv-reenlightenment=on,hv-tlbflush=on,hv-ipi=on \
  -object memory-backend-memfd,id=mem,size=10G,share=on \
  -numa node,memdev=mem \
  -object iothread,id=iothread0 \
  -blockdev driver=file,filename=/mnt/0ab1d5e2-3585-47a5-b39e-452f73aeac9c/Windows_11.qcow2,node-name=hd0,cache.direct=on,cache.no-flush=off,aio=threads \
  -blockdev driver=qcow2,file=hd0,node-name=hd1 \
  -device virtio-blk-pci,drive=hd1,iothread=iothread0 \
  -drive file=/mnt/57C4287151231A2D/ISO/virtio-win-0.1.266.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
  -device ahci,id=achi0 \
  -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=1 \
  -name Windows_11 \
  -rtc base=localtime \
  -usb \
  -device virtio-balloon-pci \
  -device usb-tablet \
  -device vfio-pci,sysfsdev=/sys/devices/pci0000:00/0000:00:02.0/${UUID},x-igd-opregion=on,display=on,driver=vfio-pci-nohotplug,ramfb=on \
  -vga none \
  -display gtk,gl=on \
  -audiodev pipewire,id=snd0 \
  -device ich9-intel-hda \
  -device hda-duplex,audiodev=snd0 \
  -netdev bridge,id=net0,br=nm-bridge \
  -device virtio-net-pci,netdev=net0,mac=90:94:01:00:00:01 \
  -object thread-context,id=tc1,cpu-affinity=2-3 \
  "$@" &

QEMU_PID=$!

wait $QEMU_PID
# --- Remove vGPU after VM shuts down ---
sudo /usr/local/bin/manage-vgpu.sh remove
echo "VGPU Removed"
