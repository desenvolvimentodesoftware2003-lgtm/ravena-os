#!/bin/bash
# checklist_v19.sh - conferencia anti-regressao + valida all-in-one antes do build
R=/root/ravv2/rootfs
PASS=0; FAIL=0
ck() { if [ "$2" = "OK" ]; then PASS=$((PASS+1)); else FAIL=$((FAIL+1)); echo "FALHOU: $1"; fi }

# --- 1. FIXES eDEX v17/v18 preservados ---
grep -q "_renderOptions()" $R/opt/edex-ui/src/classes/bootmanager.class.js && ck "boot _renderOptions" OK || ck "boot _renderOptions" FAIL
grep -q "contextmenu" $R/opt/edex-ui/src/_renderer.js && ck "contextmenu patch" OK || ck "contextmenu patch" FAIL
grep -q "window.mods.boot" $R/opt/edex-ui/src/_renderer.js && ck "widget boot" OK || ck "widget boot" FAIL
grep -q "window.mods.net" $R/opt/edex-ui/src/_renderer.js && ck "widget net" OK || ck "widget net" FAIL

# --- 2. Sintaxe JS do eDEX inteiro ---
node -c $R/opt/edex-ui/src/_renderer.js && ck "sintaxe _renderer" OK || ck "sintaxe _renderer" FAIL

# --- 3. Sintaxe dos scripts bash ravena ---
for s in $R/usr/local/bin/ravena-*.sh; do
  bash -n "$s" || { echo "BASH ERRO: $s"; ck "bash $s" FAIL; }
done
ck "scripts bash ravena-*" OK

# --- 4. Seguranca S1-S7 presentes ---
grep -q "PermitRootLogin no" $R/etc/ssh/sshd_config.d/10-archiso.conf && ck "S2 root off" OK || ck "S2 root off" FAIL
grep -q "MaxAuthTries 2" $R/etc/ssh/sshd_config.d/10-archiso.conf && ck "S2 brute force" OK || ck "S2 brute force" FAIL
[ -f $R/etc/ravena/ravena-sec-firewall.nft ] && grep -q "table inet ravena-sec" $R/etc/ravena/ravena-sec-firewall.nft && ck "S1 firewall nft" OK || ck "S1 firewall nft" FAIL
grep -q "LLMNR=no" $R/etc/systemd/resolved.conf && ck "S5 LLMNR off" OK || ck "S5 LLMNR off" FAIL
grep -q "NOPASSWD: /usr/local/bin/ravena-*" $R/etc/sudoers.d/ravena && ck "S6 sudo restrito" OK || ck "S6 sudo restrito" FAIL
grep -q "ravena_id" $R/etc/audit/rules.d/ravena.rules && ck "S7 auditd regras" OK || ck "S7 auditd regras" FAIL
grep -q "Storage=persistent" $R/etc/systemd/journald.conf && ck "S7 journald" OK || ck "S7 journald" FAIL
grep -q "127.0.0.1" $R/usr/local/bin/ravena-llm.sh && ck "S4 IA local" OK || ck "S4 IA local" FAIL

# --- 5. Hora H1 ---
grep -q "LOCAL" $R/etc/adjtime && ck "H1 adjtime LOCAL" OK || ck "H1 adjtime LOCAL" FAIL
grep -q "makestep 10 10" $R/etc/chrony.conf && ck "H1 makestep" OK || ck "H1 makestep" FAIL
grep -q "logchange 0.5" $R/etc/chrony.conf && ck "H1 logchange" OK || ck "H1 logchange" FAIL
grep -q "network-online.target" $R/usr/lib/systemd/system/chronyd.service && ck "H1 After network" OK || ck "H1 After network" FAIL

# --- 6. Locale L1 ---
grep -q "LANG=pt_BR.UTF-8" $R/home/ravena/.bash_profile && ck "L1 LANG profile" OK || ck "L1 LANG profile" FAIL

# --- 7. pt-BR L2 ---
grep -q "SHELL PRINCIPAL" $R/opt/edex-ui/src/_renderer.js && ck "L2 abas" OK || ck "L2 abas" FAIL
grep -q '"FEV"' $R/opt/edex-ui/src/classes/sysinfo.class.js && ck "L2 meses" OK || ck "L2 meses" FAIL
grep -q "Processos Ativos" $R/opt/edex-ui/src/classes/toplist.class.js && ck "L2 toplist" OK || ck "L2 toplist" FAIL

# --- 8. Limpeza C1 ---
Q=$(find $R \( -name '*.bak_*' -o -name 'diagnostico-v13*' \) | wc -l)
[ "$Q" -eq 0 ] && ck "C1 limpeza ($Q mortos)" OK || ck "C1 limpeza ($Q mortos)" FAIL

# --- 9. Servicos enable no boot ---
for s in ravena-sec-firewall ravena-chage auditd; do
  [ -L "$R/etc/systemd/system/multi-user.target.wants/$s.service" ] && ck "svc $s" OK || ck "svc $s" FAIL
done

# --- 10. Alvos criticalos intactos ---
grep -q "ravena" $R/etc/sudoers.d/ravena && ck "sudoers ravena" OK || ck "sudoers ravena" FAIL

echo ""
echo "===== RESUMO: $PASS OK / $FAIL FALHOU ====="
[ "$FAIL" -eq 0 ] && echo "CHECKLIST V19: APROVADO para build" || echo "CHECKLIST V19: REPROVADO - corrigir antes do build"