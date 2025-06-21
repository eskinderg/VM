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
    -cpu host,+invtsc,+kvm_pv_unhalt,+kvm_pv_eoi,hv-time,hv-relaxed,hv-vapic,hv-spinlocks=0x1fff,hv-vpindex,hv-synic,hv-stimer,hv-stimer-direct,hv-reset,hv-frequencies,hv-reenlightenment,hv-tlbflush,hv-ipi \
    -global kvm-pit.lost_tick_policy=discard \
    -drive file=/home/esk/VMware/Windows_10.qcow2,if=virtio,format=qcow2,cache=none,discard=unmap \
    -drive file=/mnt/57C4287151231A2D/ISO/virtio-win-0.1.266.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
    -device ahci,id=achi0 \
    -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=2 \
    -name Windows_10 \
    -rtc base=localtime \
    -usb \
    -device usb-tablet \
    -device vfio-pci,sysfsdev=/sys/devices/pci0000:00/0000:00:02.0/6a57a4b4-7e69-4038-98ae-5ca73979db06,x-igd-opregion=on,display=on,driver=vfio-pci-nohotplug,ramfb=on \
    -vga none \
    -display gtk,gl=on \
    -audiodev pipewire,id=snd0 \
    -device ich9-intel-hda \
    -device hda-duplex,audiodev=snd0 \
    -netdev bridge,id=net0,br=nm-bridge \
    -device virtio-net-pci,netdev=net0,mac=82:54:01:00:00:01 \
    -object thread-context,id=tc1,cpu-affinity=2-3 \
    "$@" &

QEMU_PID=$!

wait $QEMU_PID
# --- Remove vGPU after VM shuts down ---
sudo /usr/local/bin/manage-vgpu.sh remove
echo "VGPU Removed"

# sleep 2

# xprop -id $(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2) -f WM_CLASS 8s -set WM_CLASS "windowsten"
    #-d all -D /home/esk/VMware/logs/windows10.log.%d \
    #-cdrom /mnt/57C4287151231A2D/ISO/Windows\ 10\ Pro\ JULY\ 2024\ UPDATE\ 22H2\ build\ 19045.4651/ISO/Win.10.Pro.19045.4651.iso \
    # -d all -D windows10.log.%d \
