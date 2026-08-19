#!/bin/bash
# fix_sudoers3.sh - CORRETO: ultima regra vence; NOPASSWD especificas ficam POR ULTIMO
set -e
R=/root/ravv2/rootfs

cat > "$R/etc/sudoers.d/ravena" << 'EOF'
# RAVENA SEC (S6) - sudo sem senha RESTRITO ao necessario
# ATENCAO: no sudoers, a ULTIMA regra que casa VENCE.
# Regra generica (com senha) vem PRIMEIRO; NOPASSWD especificas DEPOIS.

# Tudo mais (pacman, etc.): pede senha
ravena ALL=(ALL) ALL

# Scripts RAVENA (os unicos que os widgets/aliases chamam sem senha)
ravena ALL=(root) NOPASSWD: /usr/local/bin/ravena-*.sh, /usr/local/bin/ravena-*
ravena ALL=(root) NOPASSWD: /usr/local/bin/ravena-boot-menu.sh, /usr/local/bin/ravena-rede.sh

# Comandos usados pelos scripts/widgets RAVENA
ravena ALL=(root) NOPASSWD: /usr/bin/nmcli, /usr/bin/efibootmgr
ravena ALL=(root) NOPASSWD: /usr/bin/systemctl reboot, /usr/bin/systemctl poweroff, /usr/bin/systemctl cancel-reboot

# Montagem da ESP no boot menu (findmnt/lsblk/mount no ravena-boot-menu)
ravena ALL=(root) NOPASSWD: /usr/bin/mount, /usr/bin/umount, /usr/bin/findmnt, /usr/bin/lsblk

# FIX v19: .xinitrc no boot usa ln (timezone) e chmod (electron)
ravena ALL=(root) NOPASSWD: /usr/bin/ln, /usr/bin/chmod
EOF

echo "=== sudoers final ==="
cat "$R/etc/sudoers.d/ravena"
echo "OK"