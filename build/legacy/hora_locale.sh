#!/bin/bash
# hora_locale.sh - H1: adjtime LOCAL + chrony reforcado; L1: LANG pt_BR no shell
set -e
R=/root/ravv2/rootfs

# --- H1a: adjtime com LOCAL (RTC = hora local, igual Windows -> zero desvio 3h) ---
cat > "$R/etc/adjtime" << 'EOF'
0.0 0 0.0
0
LOCAL
EOF

# --- H1b: chrony reforcado (step rapido no boot, log de mudancas, rtc local) ---
cat > "$R/etc/chrony.conf" << 'EOF'
# RAVENA OS - NTP (H1)
# Sincroniza rapido no boot: aceita passo de ate 10s nas primeiras 10 medidas
pool 2.arch.pool.ntp.org iburst

# passo grande permitido somente no inicio (boot), depois so slew suave
makestep 10 10

# regista mudancas de tempo >= 0.5s no log
logchange 0.5

# salva estado do RTC (hora local)
rtcfile /var/lib/chrony/rtc
rtcsync

driftfile /var/lib/chrony/drift
leapseclist /usr/share/zoneinfo/leap-seconds.list
EOF

# --- H1c: chronyd so inicia apos a rede estar on-line ---
if ! grep -q 'network-online' "$R/usr/lib/systemd/system/chronyd.service"; then
    sed -i 's/^After=ntpdate.service sntp.service ntpd.service/After=ntpdate.service sntp.service ntpd.service network-online.target/' "$R/usr/lib/systemd/system/chronyd.service"
    sed -i 's/^\[Install\]/Wants=network-online.target\n\n[Install]/' "$R/usr/lib/systemd/system/chronyd.service"
fi
grep -nE 'After|Wants' "$R/usr/lib/systemd/system/chronyd.service"

# --- L1: locale pt_BR ativo no shell (hoje o shell ativo e POSIX) ---
# .bash_profile: exporta LANG antes de tudo
sed -i '1i # RAVENA L1 - locale pt_BR ativo no shell\nexport LANG=pt_BR.UTF-8\nexport LC_ALL=pt_BR.UTF-8\nexport LANGUAGE=pt_BR' "$R/home/ravena/.bash_profile"

# .bashrc: fallback caso a sessao nao passe pelo .bash_profile (tmux/ssh)
if ! grep -q 'pt_BR.UTF-8' "$R/home/ravena/.bashrc"; then
    sed -i '1i # RAVENA L1 - locale pt_BR\n[ -z "$LANG" ] && export LANG=pt_BR.UTF-8 LC_ALL=pt_BR.UTF-8 LANGUAGE=pt_BR' "$R/home/ravena/.bashrc"
fi

echo "=== adjtime ==="
cat "$R/etc/adjtime"
echo "=== chrony.conf ==="
grep -vE '^\s*$' "$R/etc/chrony.conf"
echo "=== .bash_profile (head) ==="
head -5 "$R/home/ravena/.bash_profile"
echo "H1+L1 OK"