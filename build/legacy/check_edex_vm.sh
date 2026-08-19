#!/bin/bash
export SSHPASS="Dozinh@12"
HOST=172.18.48.1
PORT=2222
sshpass -e ssh -p $PORT -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ravena@$HOST \
    "pgrep -fa electron | head -5; echo ---LOG---; tail -15 /tmp/edex.log"