#!/bin/bash
# checklist_v20.sh - revalidacao apos fixes (sudoers ordem + chrony)
R=/root/ravv2/rootfs
PASS=0; FAIL=0
ck() { if [ "$2" = "OK" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FALHOU: $1"; fi }

# S6 - ordem correta (ALL com senha PRIMEIRO, NOPASSWD por ultimo)
L1=$(grep -n 'ravena ALL=(ALL) ALL$' $R/etc/sudoers.d/ravena | head -1 | cut -d: -f1)
L2=$(grep -n 'NOPASSWD: /usr/local/bin/ravena-' $R/etc/sudoers.d/ravena | head -1 | cut -d: -f1)
if [ -n "$L1" ] && [ -n "$L2" ] && [ "$L1" -lt "$L2" ]; then ck "S6 ordem sudoers" OK; else ck "S6 ordem sudoers" FAIL; fi
grep -q 'NOPASSWD: /usr/bin/ln, /usr/bin/chmod' $R/etc/sudoers.d/ravena && ck "S6 ln/chmod" OK || ck "S6 ln/chmod" FAIL

# H1 - rtcfile removido (incompativel com rtcsync)
if grep -q '^rtcsync' $R/etc/chrony.conf && ! grep -q '^rtcfile' $R/etc/chrony.conf; then ck "H1 chrony rtcfile removido" OK; else ck "H1 chrony rtcfile removido" FAIL; fi

# Demais fixos preservados
grep -q "PermitRootLogin no" $R/etc/ssh/sshd_config.d/10-archiso.conf && ck "S2 root off" OK || ck "S2 root off" FAIL
grep -q "table inet ravena-sec" $R/etc/ravena/ravena-sec-firewall.nft && ck "S1 firewall" OK || ck "S1 firewall" FAIL
grep -q "LLMNR=no" $R/etc/systemd/resolved.conf && ck "S5 LLMNR" OK || ck "S5 LLMNR" FAIL
grep -q "ravena_id" $R/etc/audit/rules.d/ravena.rules && ck "S7 auditd" OK || ck "S7 auditd" FAIL
grep -q "Storage=persistent" $R/etc/systemd/journald.conf && ck "S7 journald" OK || ck "S7 journald" FAIL
grep -q "127.0.0.1" $R/usr/local/bin/ravena-llm.sh && ck "S4 IA local" OK || ck "S4 IA local" FAIL
grep -q "LOCAL" $R/etc/adjtime && ck "H1 adjtime" OK || ck "H1 adjtime" FAIL
grep -q "LANG=pt_BR.UTF-8" $R/home/ravena/.bash_profile && ck "L1 locale" OK || ck "L1 locale" FAIL
grep -q "SHELL PRINCIPAL" $R/opt/edex-ui/src/_renderer.js && ck "L2 pt-BR" OK || ck "L2 pt-BR" FAIL
grep -q "_renderOptions()" $R/opt/edex-ui/src/classes/bootmanager.class.js && ck "fix boot" OK || ck "fix boot" FAIL
grep -q "contextmenu" $R/opt/edex-ui/src/_renderer.js && ck "fix ctxmenu" OK || ck "fix ctxmenu" FAIL
node -c $R/opt/edex-ui/src/_renderer.js && ck "sintaxe renderer" OK || ck "sintaxe renderer" FAIL
Q=$(find $R \( -name '*.bak_*' -o -name 'diagnostico-v13*' \) | wc -l)
[ "$Q" -eq 0 ] && ck "C1 limpeza" OK || ck "C1 limpeza" FAIL
for s in ravena-sec-firewall ravena-chage auditd; do
  [ -L "$R/etc/systemd/system/multi-user.target.wants/$s.service" ] && ck "svc $s" OK || ck "svc $s" FAIL
done
for s in $R/usr/local/bin/ravena-*.sh; do bash -n "$s" || ck "bash $s" FAIL; done
ck "bash ravena-*" OK

echo ""
echo "===== RESUMO: $PASS OK / $FAIL FALHOU ====="
[ "$FAIL" -eq 0 ] && echo "CHECKLIST V20: APROVADO" || echo "CHECKLIST V20: REPROVADO"