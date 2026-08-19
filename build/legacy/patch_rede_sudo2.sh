#!/bin/bash
# adiciona sudo nas chamadas nmcli que exigem privilegio (networking off/on e device connect)
F=/root/ravv2/rootfs/usr/local/bin/ravena-rede.sh
sed -i 's/            4) nmcli networking off/            4) sudo nmcli networking off/' "$F"
sed -i 's/        nmcli device connect "\$dev"/        sudo nmcli device connect "$dev"/' "$F"
echo "--- linhas alteradas ---"
grep -n "sudo nmcli" "$F"
echo "--- verificacao ---"
bash -n "$F" && echo "SINTAXE OK" || echo "ERRO"