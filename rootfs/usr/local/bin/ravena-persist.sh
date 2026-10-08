#!/bin/bash
# RAVENA - mantem o boot persistente (cow_label=ARCH_PERSISTENT) todo boot.
#
# O grub.cfg da ISO e somente-leitura e da persistencia atraves de
# cow_label=ARCH_PERSISTENT, mas SO quando /ravena.nextboot existe na ESP do
# pendrive (o bloco `source (${ravboot})/ravena.nextboot`). Logo apos ler, o
# proprio GRUB esvazia o arquivo - limpeza do one-shot. Sem regravar aqui, o
# boot seguinte volta ao cfg normal, o cowspace volta pro tmpfs de 256M e o
# overlay perde tudo que foi alterado.
#
# Nunca falha: persistencia e conforto, nao motivo para derrubar o boot.
exec 2>/dev/null
[ "$(id -u)" -eq 0 ] || exec sudo -n "$0" "$@"

MP=/mnt/ravboot
LABEL=ARCH_PERSISTENT

find_esp() {
    local p
    p=$(readlink -f "/dev/disk/by-label/ARCHISO_EFI" 2>/dev/null)
    if [ -n "$p" ]; then echo "$p"; return 0; fi
    # Rufus e o unico que da rotulo; senao pega a primeira vfat do disco
    p=$(lsblk -lnpo NAME,FSTYPE 2>/dev/null | awk '$2=="vfat"{print $1; exit}')
    [ -n "$p" ] && { echo "$p"; return 0; }
    return 1
}

# regrava somente se a particao de persistencia EXISTIR - se nao, o proximo
# boot tentaria cow_label= num dispositivo inexistente e cairia no initramfs.
[ -b "/dev/disk/by-label/$LABEL" ] || exit 0

# ...e somente se o overlay atual ja veio dela. Num boot volatil o script
# tambem estaria volatil, mas o teste custa nada e deixa a regra explicita.
case "$(findmnt -no SOURCE /run/archiso/cowspace 2>/dev/null)" in
    *"$LABEL"*) ;;
    *) exit 0 ;;
esac

esp=$(find_esp) || exit 0
mkdir -p "$MP"
mount -o rw "$esp" "$MP" 2>/dev/null || exit 0
cat > "$MP/ravena.nextboot" <<'GRUBEOF'
menuentry "RAVENA OS (persistente)" --id rav_persist {
    set gfxpayload=keep
    linux /arch/boot/x86_64/vmlinuz-linux archisobasedir=arch archisosearchuuid=2026-08-02-16-18-52-00 cow_label=ARCH_PERSISTENT
    initrd /arch/boot/x86_64/initramfs-linux.img
}
set default=rav_persist
GRUBEOF
sync
umount "$MP" 2>/dev/null
echo "RAVENA-PERSIST: /ravena.nextboot regravado na ESP (cow_label=$LABEL)"
exit 0
