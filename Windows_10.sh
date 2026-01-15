#!/bin/bash

UUID="6a57a4b4-7e69-4038-98ae-5ca73979db06"

# 1. Clear caches to free up "easy" RAM
sync && sudo sysctl -w vm.drop_caches=3

# 2. Force the kernel to compact memory into contiguous blocks
sudo sysctl -w vm.compact_memory=1

# 3. Allocate the HugePages
sudo sysctl -w vm.nr_hugepages=5120

# Create vGPU via sudo helper script
sudo /usr/local/bin/manage-vgpu.sh create

nice -n -15 taskset -c 2,3 qemu-system-x86_64 \
  -enable-kvm \
  \
  -m 10G \
  -object memory-backend-memfd,id=mem,size=10G,share=off,prealloc=on,hugetlb=on \
  -numa node,memdev=mem \
  \
  -smp 2,sockets=1,dies=1,cores=2,threads=1 \
  -machine type=q35,accel=kvm,usb=off,hpet=off \
  -cpu host,+kvm_pv_unhalt,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vpindex=on,hv-synic=on,hv-stimer=on,hv-stimer-direct=on,hv-reset=on,hv-frequencies=on,hv-reenlightenment=on,hv-tlbflush=on,hv-ipi=on,hv-runtime=on,hv-passthrough=on \
  \
  -object iothread,id=iothread0,poll-max-ns=0 \
  -drive file=/home/esk/VMware/Windows_10.qcow2,if=none,id=drive0,cache=none,aio=native,discard=unmap,detect-zeroes=unmap \
  -device virtio-blk-pci,drive=drive0,iothread=iothread0,num-queues=2 \
  \
  -drive file=/mnt/57C4287151231A2D/ISO/virtio-win-0.1.266.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
  -device ahci,id=achi0 \
  -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=1 \
  \
  -name Windows_10 \
  -rtc base=localtime \
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

sudo sysctl -w vm.nr_hugepages=0
