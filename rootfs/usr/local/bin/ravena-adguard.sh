#!/bin/bash
# RAVENA ADGUARD HOME - DNS com filtro, opt-in (Bloco I plan §6.7 / doc2#060)
#
# SEGURANCA DA REDE (por que e opt-in):
#   O ISO roda com systemd-resolved (stub 127.0.0.53) e DNSOverTLS=no.
#   Este wrapper SOBE o AdGuard em 127.0.0.1:53 -- endereco DIFERENTE do
#   stub do resolved, entao nunca briga com a resolucao padrao. NADA aponta
#   para 127.0.0.1:53 automaticamente: ativar e decisao de operador
#   (resolvectl dns <iface> 127.0.0.1 ou DNS=127.0.0.1 no networkd).
#   Binario ausente = exit 0: servico fica inerte, sem loop de reinicio
#   (Restart=on-failure do ravena-adguard.service).
set -e
CONF=/etc/ravena/adguardhome.yaml
WORK=/var/lib/adguardhome
BIN=""
for c in /usr/local/bin/AdGuardHome /opt/AdGuardHome/AdGuardHome /usr/bin/AdGuardHome; do
    [ -x "$c" ] && { BIN="$c"; break; }
done
if [ -z "$BIN" ]; then
    echo "ravena-adguard: binario AdGuardHome ausente (doc2#060); DNS continua no systemd-resolved"
    exit 0
fi
mkdir -p "$WORK"
echo "ravena-adguard: iniciando $(basename "$BIN") -- DNS 127.0.0.1:53, painel 127.0.0.1:3000"
exec "$BIN" --config "$CONF" --work-dir "$WORK"
