#!/usr/bin/env bash

set -o errexit
set -o pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <.efi file> [another file]"
  exit 1
fi

efi_file=$1
another_file=$2

if [[ ! -f $efi_file ]]; then
  echo "No such file: $efi_file"
  exit 1
fi

image_file=./disk.img
mount_point=./mnt
devenv_dir=./mikanos-build/devenv

# make image

rm -f $image_file
qemu-img create -f raw $image_file 200M
mkfs.fat -n 'MIKAN OS' -s 2 -f 2 -R 32 -F 32 $image_file

mkdir -p $mount_point
sudo mount -o loop $image_file $mount_point

sudo mkdir -p $mount_point/EFI/BOOT
sudo cp "$efi_file" $mount_point/EFI/BOOT/BOOTX64.EFI

if [[ "$another_file" != "" ]]; then
  sudo cp "$another_file" $mount_point/
fi

sleep 0.5

sudo umount $mount_point

qemu-system-x86_64 \
  -m 1G \
  -drive if=pflash,format=raw,readonly,file=$devenv_dir/OVMF_CODE.fd \
  -drive if=pflash,format=raw,file=$devenv_dir/OVMF_VARS.fd \
  -drive if=ide,index=0,media=disk,format=raw,file=$image_file \
  -device nec-usb-xhci,id=xhci \
  -device usb-mouse -device usb-kbd \
  -monitor stdio

