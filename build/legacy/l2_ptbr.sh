#!/bin/bash
# l2_ptbr.sh - eDEX-UI em portugues (strings visiveis)
set -e
D=/root/ravv2/rootfs/opt/edex-ui

# --- _renderer.js: abas, paineis, erros, editor ---
R=$D/src/_renderer.js
sed -i 's|<p>PANEL</p><p>SYSTEM</p>|<p>PAINEL</p><p>SISTEMA</p>|' $R
sed -i 's|<p>TERMINAL</p><p>MAIN SHELL</p>|<p>TERMINAL</p><p>SHELL PRINCIPAL</p>|' $R
sed -i 's|<p>PANEL</p><p>NETWORK</p>|<p>PAINEL</p><p>REDE</p>|' $R
sed -i 's|>MAIN SHELL<|>SHELL PRINCIPAL<|g' $R
sed -i 's|>EMPTY<|>VAZIO<|g' $R
sed -i 's|>ERROR<|>ERRO<|g' $R
sed -i 's|>LOADING...<|>CARREGANDO...<|g' $R
sed -i 's|>File saved.<|>Arquivo salvo.<|' $R
sed -i 's|New values written to settings.json file at|Novos valores gravados em settings.json as|' $R
sed -i 's|<p>MAIN - |<p>PRINCIPAL - |' $R

# --- tela de boot RAVEN BIOS (visivel no POST) ---
sed -i 's|RAVEN BIOS v1.0.4 - POST|RAVEN BIOS v1.0.4 - PÓS|g' $R
sed -i 's|RAVEN BIOS v1.0.4 - DISCOVERY|RAVEN BIOS v1.0.4 - DESCOBERTA|g' $R
sed -i 's|RAVEN BIOS v1.0.4 - SECURITY CHECK|RAVEN BIOS v1.0.4 - VERIFICAÇÃO DE SEGURANÇA|g' $R
sed -i 's|RAVEN BIOS v1.0.4 - VERIFIED BOOT|RAVEN BIOS v1.0.4 - BOOT VERIFICADO|g' $R

# --- sysinfo: meses + CHARGE ---
S=$D/src/classes/sysinfo.class.js
sed -i 's/"JAN"/"JAN"/; s/"FEB"/"FEV"/; s/"MAR"/"MAR"/; s/"APR"/"ABR"/; s/"MAY"/"MAI"/; s/"JUN"/"JUN"/; s/"JUL"/"JUL"/; s/"AUG"/"AGO"/; s/"SEP"/"SET"/; s/"OCT"/"OUT"/; s/"NOV"/"NOV"/; s/"DEC"/"DEZ"/' $S
sed -i 's/"CHARGE"/"CARGA"/' $S

# --- netstat: ONLINE/OFFLINE/VPN ---
N=$D/src/classes/netstat.class.js
sed -i 's/"ONLINE"/"ON-LINE"/g; s/"OFFLINE"/"OFF-LINE"/g; s/"VPN OFF"/"VPN DESLIGADA"/' $N

# --- locationGlobe ---
G=$D/src/classes/locationGlobe.class.js
sed -i 's/"CRITICAL"/"CRÍTICO"/; s/"HIGH"/"ALTO"/; s/"LOW"/"BAIXO"/; s/"UNKNOWN"/"DESCONHECIDO"/; s/"ONLINE"/"ON-LINE"/g; s/"OFFLINE"/"OFF-LINE"/g; s/"VPN OFF"/"VPN DESLIGADA"/; s/"Clash Report"/"Relatório de Conflitos"/; s/"ESTABLISHED"/"ESTABELECIDA"/' $G

# --- toplist ---
T=$D/src/classes/toplist.class.js
sed -i 's/"Active Processes"/"Processos Ativos"/; s/"Memory"/"Memória"/; s/"Name"/"Nome"/; s/"Runtime"/"Tempo"/; s/"Started"/"Iniciado"/; s/"State"/"Estado"/; s/"User"/"Usuário"/' $T

# --- aiAssist ---
A=$D/src/classes/aiAssist.class.js
sed -i 's/"OFFLINE"/"OFF-LINE"/' $A

# --- cpuinfo: TEMP/CORES ja aceitaveis em pt ---

echo "=== conferencia ==="
grep -c "PAINEL\|SISTEMA\|REDE\|SHELL PRINCIPAL\|VAZIO\|ERRO" $R
grep -cE "PÓS|DESCOBERTA|SEGURANÇA|BOOT VERIFICADO" $R
grep -oE '"(JAN|FEV|ABR|MAI|AGO|SET|OUT|DEZ)"' $S | sort -u | head -8
grep -c "ON-LINE\|VPN DESLIGADA" $N
grep -c "Processos Ativos\|Memória\|Usuário" $T
echo "L2 OK"