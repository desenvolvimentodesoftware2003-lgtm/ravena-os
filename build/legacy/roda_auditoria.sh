#!/bin/bash
# roda_auditoria.sh - transfere e roda a auditoria de seguranca na VM
export SSHPASS="Dozinh@12"
HOST=172.18.48.1
PORT=2222

sshpass -e scp -P $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
    /root/auditoria_seg.sh ravena@$HOST:/home/ravena/auditoria_seg.sh
echo "SCP_EXIT=$?"

sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST \
    "bash /home/ravena/auditoria_seg.sh 2>&1 | tail -3"
echo "AUDIT_EXIT=$?"

sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST \
    "cat /home/ravena/auditoria_seg.txt"
echo "CAT_EXIT=$?"