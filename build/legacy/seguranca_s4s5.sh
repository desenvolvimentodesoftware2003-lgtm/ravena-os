#!/bin/bash
# seguranca_s4s5.sh - S4: IA so local (127.0.0.1); S5: LLMNR/mDNS off
set -e
R=/root/ravv2/rootfs

# --- S4: llama-server + airllm bind 127.0.0.1 ---
sed -i 's/--host 0\.0\.0\.0/--host 127.0.0.1/' "$R/usr/local/bin/ravena-llm.sh"
sed -i 's/make_server("0\.0\.0\.0", PORT)/make_server("127.0.0.1", PORT)/' "$R/usr/local/bin/ravena-airllm-server.py"

echo "S4: host corrigido em:"
grep -n "host 127.0.0.1\|127.0.0.1" "$R/usr/local/bin/ravena-llm.sh" "$R/usr/local/bin/ravena-airllm-server.py"

# --- S5: LLMNR/mDNS off no systemd-resolved ---
cat > "$R/etc/systemd/resolved.conf" << 'EOF'
[Resolve]
# RAVENA SEC (S5) - LLMNR/mDNS desligados (porta 5355 fechada)
# Previne envenenamento de nomes (MITM) na rede local
LLMNR=no
MulticastDNS=no
DNSOverTLS=no
DNSSEC=no
EOF

echo "S5: resolved.conf atualizado"
grep -vE '^\s*#|^\s*$' "$R/etc/systemd/resolved.conf"
echo "S4S5 OK"