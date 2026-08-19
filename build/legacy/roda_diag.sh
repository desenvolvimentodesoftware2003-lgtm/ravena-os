#!/bin/bash
# roda_diag.sh - transfere o diag para a VM e executa
export SSHPASS="Dozinh@12"
SRC=/root/diag.sh
HOST=172.18.48.1
PORT=2222

sshpass -e scp -P $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$SRC" ravena@$HOST:/home/ravena/diag.sh
echo "SCP_EXIT=$?"

sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST "wc -c /home/ravena/diag.sh"
echo "WC_EXIT=$?"

sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST "bash /home/ravena/diag.sh"
echo "DIAG_EXIT=$?"

sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST "cat /home/ravena/diag_v19.txt"
echo "CAT_EXIT=$?"