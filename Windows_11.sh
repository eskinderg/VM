#!/bin/bash

taskset -c 2,3 qemu-system-x86_64 \
  -enable-kvm \
  \
  -m 10G \
  -mem-path /dev/myqemuhugepages \
  -mem-prealloc \
  \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/ovmf/OVMF.fd \
  -drive if=pflash,format=raw,file=/home/esk/Desktop/OV.fd \
  \
  -smp 2,sockets=1,dies=1,cores=2,threads=1 \
  -machine type=q35,accel=kvm,usb=off \
  -cpu host,+invtsc,+kvm_pv_unhalt,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vpindex=on,hv-synic=on,hv-stimer=on,hv-stimer-direct=on,hv-reset=on,hv-frequencies=on,hv-reenlightenment=on,hv-tlbflush=on,hv-ipi=on \
  \
  -drive file=/mnt/a16b6d0c-4275-466e-8378-0356bc49dcc4/Windows_11.qcow2,if=none,id=nvm \
  -device nvme,drive=nvm,serial=qcow2Serial \
  \
  -drive file=/mnt/57C4287151231A2D/ISO/MICRO_WIN11.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
  -device ahci,id=achi0 \
  -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1 \
  -cdrom /mnt/57C4287151231A2D/ISO/virtio-win-0.1.266.iso \
  \
  -object memory-backend-file,id=ivshmem_mem,size=64M,share=on,mem-path=/dev/shm/looking-glass \
  -device ivshmem-plain,memdev=ivshmem_mem \
  \
  -name Windows_11 \
  -rtc base=localtime,clock=host,driftfix=slew \
  -usb \
  -device virtio-balloon-pci \
  -device usb-tablet \
  \
  -vga none \
  -device ramfb,id=ramfb0 \
  -device vfio-pci,host=04:00.0,multifunction=on \
  -device vfio-pci,host=04:00.1 \
  \
  -audiodev pipewire,id=snd0 \
  -device ich9-intel-hda \
  -device hda-duplex,audiodev=snd0 \
  \
  -netdev bridge,id=net0,br=nm-bridge \
  -device virtio-net-pci,netdev=net0,mac=90:94:01:00:00:01 \
  \
  -object thread-context,id=tc1,cpu-affinity=2-3 \
  \
  "$@" &

QEMU_PID=$!

wait $QEMU_PID
