#!/bin/bash

UUID="6a57a4b4-7e69-4038-98ae-5ca73979db06"

# Create vGPU via sudo helper script
sudo /usr/local/bin/manage-vgpu.sh create

# echo "0c" | sudo tee "/proc/irq/137/smp_affinity"  # Binary 11 = CPUs 2 and 3
# sudo echo "0c" > /proc/irq/137/smp_affinity  # Binary 11 = CPUs 2 and 3

# CPU isolation using cgroup v2 for QEMU
CGROUP=/sys/fs/cgroup/qemu-vm
CPUS="2-3"

# Create and configure cgroup
sudo mkdir -p "$CGROUP"
echo "$CPUS" | sudo tee "$CGROUP/cpuset.cpus"
echo 0 | sudo tee "$CGROUP/cpuset.mems"

# --- Launch QEMU with vGPU ---
qemu-system-x86_64 \
    -enable-kvm \
    -m 10G \
    -smp 2,sockets=1,dies=1,cores=2,threads=1 \
    -machine type=q35,accel=kvm,usb=off \
    -cpu host,+kvm_pv_unhalt,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vpindex=on,hv-synic=on,hv-stimer=on,hv-stimer-direct=on,hv-reset=on,hv-frequencies=on,hv-reenlightenment=on,hv-tlbflush=on,hv-ipi=on \
    -drive file=/mnt/0ab1d5e2-3585-47a5-b39e-452f73aeac9c/Windows_11.qcow2,format=qcow2,if=virtio,cache=none,discard=unmap \
    -drive file=/mnt/57C4287151231A2D/ISO/virtio-win-0.1.266.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
    -device ahci,id=achi0 \
    -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=1 \
    -name Windows_11 \
    -rtc base=localtime \
    -usb \
    -device virtio-balloon-pci \
    -device usb-tablet \
    -device vfio-pci,sysfsdev=/sys/devices/pci0000:00/0000:00:02.0/$UUID,x-igd-opregion=on,display=on,driver=vfio-pci-nohotplug,ramfb=on \
    -vga none \
    -display gtk,gl=on \
    -audiodev pipewire,id=snd0 \
    -device ich9-intel-hda \
    -device hda-duplex,audiodev=snd0 \
    -netdev bridge,id=net0,br=nm-bridge \
    -device virtio-net-pci,netdev=net0,mac=90:94:01:00:00:01 \
    "$@" &

QEMU_PID=$!
echo "$QEMU_PID" | sudo tee "$CGROUP/cgroup.procs"

# Wait for VM to finish
wait $QEMU_PID

#sudo rmdir "$CGROUP"

# --- Remove vGPU after VM shuts down ---
sudo /usr/local/bin/manage-vgpu.sh remove

# Optional: Set window class for GTK window
# sleep 2
# xprop -id "$(xprop -root 32x '\t$0' _NET_ACTIVE_WINDOW | cut -f 2)" -f WM_CLASS 8s -set WM_CLASS "windowseleven"
