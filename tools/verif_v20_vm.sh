#!/bin/bash
# verif_v20_vm.sh - bateria de verificacao RV10v20 na VM (mesma lista do PC real)
H=172.18.48.1
P=2222
U=ravena
PASS=Dozinh@12
export SSHPASS="$PASS"
S="sshpass -e ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -p $P $U@$H"

echo "=== 0. aguardando boot + SSH ==="
for i in $(seq 1 24); do
  if $S "echo UP" 2>/dev/null; then break; fi
  echo "tentativa $i..."; sleep 10
done

echo ""
echo "=== 1. eDEX rodando? (o bug da v19 era tela preta = eDEX morto) ==="
$S "ps aux | grep -E 'electron|edex' | grep -v grep | wc -l; ps aux | grep -E 'electron|edex' | grep -v grep | head -4"

echo ""
echo "=== 2. Xorg rodando? ==="
$S "ps aux | grep Xorg | grep -v grep | wc -l"

echo ""
echo "=== 3. HORA: adjtime + chrony ==="
$S "cat /etc/adjtime; echo ---; systemctl is-active chronyd; date"

echo ""
echo "=== 4. LOCALE ==="
$S "echo LANG=\$LANG"

echo ""
echo "=== 5. SEGURANCA: portas ==="
$S "ss -tlnp 2>/dev/null | grep -E ':22|:8080|:5355' | head -6"

echo ""
echo "=== 6. SEGURANCA: sshd config ==="
$S "grep -E 'PermitRootLogin|MaxAuthTries|LoginGraceTime' /etc/ssh/sshd_config.d/10-archiso.conf"

echo ""
echo "=== 7. SEGURANCA: servicos ==="
$S "systemctl is-active ravena-sec-firewall auditd 2>&1; systemctl is-active ravena-chage"

echo ""
echo "=== 8. SEGURANCA: sudo restrito ==="
$S "sudo -l 2>/dev/null | grep -cE 'NOPASSWD'"

echo ""
echo "=== 9. SEGURANCA: LLMNR ==="
$S "grep -c 'LLMNR=no' /etc/systemd/resolved.conf"

echo ""
echo "=== 10. pt-BR no eDEX ==="
$S "grep -c 'SHELL PRINCIPAL' /opt/edex-ui/src/_renderer.js; grep -c contextmenu /opt/edex-ui/src/_renderer.js"

echo ""
echo "=== 11. LIMPEZA ==="
$S "find / -name '*.bak_*' 2>/dev/null | wc -l"

echo ""
echo "=== 12. erro de tela preta? (journal X/electron) ==="
$S "journalctl -b --no-pager 2>/dev/null | grep -iE 'xinit|electron|Fatal|Segmentation' | grep -v audit | tail -10"