#!/bin/bash
# testa_ctxmenu_vm.sh - copia o _renderer.js patchado para a VM e relanca o eDEX
export SSHPASS="Dozinh@12"
HOST=172.18.48.1
PORT=2222

sshpass -e scp -P $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    /root/ravv2/rootfs/opt/edex-ui/src/_renderer.js ravena@$HOST:/home/ravena/_renderer.js
echo "SCP_EXIT=$?"

sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST \
    "cp /home/ravena/_renderer.js /opt/edex-ui/src/_renderer.js && node -c /opt/edex-ui/src/_renderer.js && echo VM_SYNTAX_OK"
echo "CP_EXIT=$?"

# Relanca o eDEX: mata o processo atual e relança como no .xinitrc
sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST \
    "pkill -f 'electron.*edex-ui'; sleep 3; setsid /opt/edex-ui/node_modules/.bin/electron /opt/edex-ui --no-sandbox --disable-gpu > /tmp/edex.log 2>&1 &"
echo "RESTART_EXIT=$?"
sleep 15
sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST \
    "pgrep -f 'electron.*edex-ui' | head -3; tail -8 /tmp/edex.log"
echo "CHECK_EXIT=$?"