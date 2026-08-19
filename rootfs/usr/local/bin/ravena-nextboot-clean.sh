#!/bin/bash
# RAVENA NEXTBOOT CLEAN - apaga /ravena.nextboot da ESP apos uso
# Reforco do auto-clean do GRUB: garante que o one-shot nao vire loop.
# O GRUB ja esvazia o arquivo no boot; aqui removemos de vez (montando
# a ESP do pendrive). Seguro rodar sempre: se nao existir, sai rapido.
exec 2>/dev/null
[ "$(id -u)" -eq 0 ] || exec sudo -n "$0" "$@"

find_esp() {
    local bootsrc bootdisk
    bootsrc=$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null)
    [ -n "$bootsrc" ] || return 1
    bootdisk=$(lsblk -no PKNAME "$bootsrc" 2>/dev/null)
    [ -n "$bootdisk" ] || return 1
    lsblk -npo NAME,PARTTYPE,TYPE "/dev/$bootdisk" 2>/dev/null | \
        awk '$3=="part" && $2=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"{print $1; exit}'
}

esp=$(find_esp) || exit 0
mkdir -p /mnt/ravboot
mount -o rw "$esp" /mnt/ravboot 2>/dev/null || exit 0
if [ -f /mnt/ravboot/ravena.nextboot ]; then
    rm -f /mnt/ravboot/ravena.nextboot
    sync
fi
umount /mnt/ravboot 2>/dev/null
exit 0