#!/bin/bash
# xorriso_v20.sh - completa o build v20 (sfs ja pronto)
set -e
cd /root/ravv2
NAME=ravena-remaster-RV10v20

rm -f $NAME.iso
timeout 1200 xorriso -indev ravena-remaster-RV10-base.iso -outdev $NAME.iso \
  -map $NAME.sfs /arch/x86_64/airootfs.sfs \
  -map $NAME.sfs.sha512 /arch/x86_64/airootfs.sha512 \
  -map /root/ravv2/grub.cfg.rav17 /boot/grub/grub.cfg \
  -boot_image any replay -commit 2>&1 | tail -3
ls -la $NAME.iso
sha512sum $NAME.iso | tee $NAME.iso.sha512
echo DONE_RV10v20