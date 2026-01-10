#!/bin/bash
# 1. Get your current User ID (usually 1000)

UUID="6a57a4b4-7e69-4038-98ae-5ca73979db06"

# Create vGPU via sudo helper script
sudo /usr/local/bin/manage-vgpu.sh create

  nice -n -15 taskset -c 2,3 qemu-system-x86_64 \
  -enable-kvm \
  \
  -m 10G \
  -object memory-backend-memfd,id=mem,size=10G,share=on,prealloc=on \
  -numa node,memdev=mem \
  \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/ovmf/OVMF.fd \
  -drive if=pflash,format=raw,file=/home/esk/VM/OV.fd \
  \
  -smp 2,sockets=1,dies=1,cores=2,threads=1 \
  -machine type=q35,accel=kvm,usb=off,hpet=off \
  -cpu host,+kvm_pv_unhalt,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vpindex=on,hv-synic=on,hv-stimer=on,hv-stimer-direct=on,hv-reset=on,hv-frequencies=on,hv-reenlightenment=on,hv-tlbflush=on,hv-ipi=on,hv-runtime=on,hv-passthrough=on \
  \
  -drive file=/mnt/a16b6d0c-4275-466e-8378-0356bc49dcc4/Windows_11.qcow2,if=none,id=nvm,cache=none,aio=native,discard=unmap,detect-zeroes=unmap \
  -device nvme,drive=nvm,serial=qcow2Serial \
  \
  -drive file=/mnt/57C4287151231A2D/ISO/MICRO_WIN11.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
  -device ahci,id=achi0 \
  -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1 \
  -cdrom /mnt/57C4287151231A2D/ISO/virtio-win-0.1.266.iso \
  \
  -name Windows_11 \
  -rtc base=localtime \
  \
  -usb \
  -device usb-tablet \
  \
  -display gtk,gl=on,window-close=off \
  -device vfio-pci,sysfsdev=/sys/devices/pci0000:00/0000:00:02.0/${UUID},x-igd-opregion=on,display=on,ramfb=on,driver=vfio-pci-nohotplug,romfile=/usr/share/vgabios/i915ovmf.rom \
  -vga none \
  \
  -audiodev pipewire,id=snd0,out.frequency=48000,out.buffer-length=50000,timer-period=10000 \
  -device ich9-intel-hda -device hda-duplex,audiodev=snd0 \
  \
  -netdev bridge,id=net0,br=nm-bridge \
  -device virtio-net-pci,netdev=net0,mac=90:94:01:00:00:01,mq=on,vectors=8 \
  -overcommit mem-lock=on \
  \
  -global kvm-pit.lost_tick_policy=delay \
  "$@" &

QEMU_PID=$!

wait $QEMU_PID

# --- Remove vGPU after VM shuts down ---
sudo /usr/local/bin/manage-vgpu.sh remove
