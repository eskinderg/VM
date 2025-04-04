#!/bin/bash
qemu-system-x86_64 \
    -enable-kvm \
    -m 2G \
    -smp 2,sockets=1,cores=2,threads=1 \
    -machine type=pc,accel=kvm \
    -cpu qemu32 \
    -drive file=/home/esk/VMware/Windows\ XP/Windows\ XP.qcow2,format=qcow2,if=ide \
    -drive file=/mnt/57C4287151231A2D/ISO/virtio-win-0.1.266.iso,format=raw,if=none,media=cdrom,id=drive-cd1,readonly=on \
    -device ahci,id=achi0 \
    -device ide-cd,bus=achi0.0,drive=drive-cd1,id=cd1,bootindex=1 \
    -name Windows_XP \
    -rtc base=localtime \
    -usb \
    -device usb-tablet \
    -vga std \
    -display gtk,gl=on \
    -audiodev pa,id=snd0,server=unix:${XDG_RUNTIME_DIR}/pulse/native \
    -device ac97,audiodev=snd0 \
    -net nic,model=e1000 \
    -net bridge,br=nm-bridge \
    "$@" &
