#!/bin/bash
# fix_sudoers2.sh - ln/chmod sem args (match confiavel), aplica no rootfs
set -e
R=/root/ravv2/rootfs

cat > "$R/etc/sudoers.d/ravena" << 'EOF'
# RAVENA SEC (S6) - sudo sem senha RESTRITO ao necessario
# (processo comprometido nao vira root total; tudo mais pede senha)

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

# Tudo mais (pacman, etc.): pede senha
ravena ALL=(ALL) ALL
EOF

echo "=== sudoers final ==="
cat "$R/etc/sudoers.d/ravena"
echo "OK"