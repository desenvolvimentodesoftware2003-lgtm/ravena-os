#!/bin/bash
# substitui nmcli device wifi connect por sudo nmcli device wifi connect no ravena-rede.sh
F=/root/ravv2/rootfs/usr/local/bin/ravena-rede.sh
sed -i 's/^        nmcli device wifi connect/        sudo nmcli device wifi connect/' "$F"
echo "--- linha alterada ---"
grep -n "nmcli device wifi connect" "$F"
echo "--- verificacao bash -n ---"
bash -n "$F" && echo "SINTAXE OK" || echo "ERRO DE SINTAXE"