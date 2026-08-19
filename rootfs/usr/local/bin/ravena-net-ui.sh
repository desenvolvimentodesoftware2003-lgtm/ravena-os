#!/bin/bash
# RAVENA NET UI - painel de rede pos-OS (estilo Windows)
# Roda em background apos o eDEX-UI abrir. Se nao houver internet,
# abre o painel 'rede' numa janela tmux do OS (nao-bloqueante).
# Nada configura nem trava durante o boot - so depois do OS abrir.

# aguarda o tmux do OS subir (eDEX terminal 1)
for i in $(seq 1 45); do
    tmux has-session -t ravena 2>/dev/null && break
    sleep 2
done

# da mais um tempo pro eDEX terminar de carregar
sleep 10

# ja tem internet? nao incomoda
if ping -c1 -W3 1.1.1.1 >/dev/null 2>&1; then
    exit 0
fi

# sem internet: abre o painel de rede numa janela do tmux do OS
tmux new-window -t ravena -n REDE 'sudo /usr/local/bin/ravena-rede.sh' 2>/dev/null || true
exit 0