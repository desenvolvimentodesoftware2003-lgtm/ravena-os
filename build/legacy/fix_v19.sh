#!/bin/bash
# fix_v19.sh - CORRECOES v19: (1) sudoers cobre .xinitrc, (2) chrony rtcfile/rtcsync
set -e
R=/root/ravv2/rootfs

# --- FIX 1: sudoers - ln/chmod usados pelo .xinitrc no boot (sem senha, args fixos) ---
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

# FIX v19: .xinitrc no boot usa estes (ln timezone + chmod electron) - args fixos
ravena ALL=(root) NOPASSWD: /usr/bin/ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
ravena ALL=(root) NOPASSWD: /usr/bin/chmod +x /opt/edex-ui/node_modules/electron/dist/electron, /usr/bin/chmod +x /opt/edex-ui/node_modules/electron/cli.js, /usr/bin/chmod +x /opt/edex-ui/node_modules/.bin/electron

# Tudo mais (pacman, etc.): pede senha
ravena ALL=(ALL) ALL
EOF

# --- FIX 2: chrony - rtcfile INCOMPATIVEL com rtcsync (fatal). Manter rtcsync (sincroniza RTC) ---
sed -i '/^rtcfile \/var\/lib\/chrony\/rtc$/d' "$R/etc/chrony.conf"
grep -nE 'rtcfile|rtcsync' "$R/etc/chrony.conf"

echo "=== sudoers final ==="
cat "$R/etc/sudoers.d/ravena"
echo "FIX OK"