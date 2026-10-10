#!/usr/bin/env bash
# verif_regressao.sh -- Fase 1, lado OS (ravena-os). Equivalente do F0.1.
#
# O que faz:
#   1. delega a estrutura para tools/verif_estrutura.sh (fonte unica: sintaxe
#      bash -n, symlinks 120000, CRLF no rootfs, presenca dos manifestos);
#   2. impoe PISOS. O verif_estrutura.sh so checa "esta integro"; este checa
#      "nao encolheu". Encolher arquivo de texto, unit ou script e regressao,
#      e a estrutura continua passando -- por isso o piso separado;
#   3. valida o FORMATO dos dois manifestos OS-1/OS-2 com awk, sem depender de
#      python. Uma linha malformada quebra o parse em ravena-aim; aqui ela
#      aparece antes, no proprio OS.
#
# Uso:  bash tools/verif_regressao.sh
# Sai com 1 se qualquer checagem falhar.
#
# Os pisos sao PISOS, nao contagens exatas: crescer e legittimo (arquivo novo,
# unit nova). Cair abaixo e regressao e falha. Congelados em 2026-10-09;
# re-congelados no Bloco I (2026-10-10: +ravena-adguard.sh, +ravena-adguard.service,
# +llm.conf, +adguardhome.yaml, +linha doc2#060 no OS-2).

set -u
cd "$(dirname "$0")/.." || exit 1

falhas=0
ok()   { printf 'OK   %s\n' "$1"; }
ruim() { printf 'FALHA %s\n' "$1"; falhas=$((falhas + 1)); }

PISO_SCRIPTS=61
PISO_UNITS_RAVENA=15
PISO_NFT_RULES=3
PISO_CONFS_ETC=5
PISO_PACOTES=35
PISO_SERVICOS=46
CAMPOS_PACOTES=5
CAMPOS_SERVICOS=4

# 1) estrutura (fonte unica) -------------------------------------------------
if bash tools/verif_estrutura.sh >/tmp/ravena_estrutura.out 2>&1; then
    ok "estrutura ($(tail -1 /tmp/ravena_estrutura.out))"
else
    cat /tmp/ravena_estrutura.out
    ruim "estrutura quebrada -- ver tools/verif_estrutura.sh acima"
fi

# 2) pisos -------------------------------------------------------------------
shopt -s globstar nullglob
scripts=(**/*.sh)
shopt -u globstar
n_scripts=0
for s in "${scripts[@]}"; do
    [[ -f "$s" ]] && n_scripts=$((n_scripts + 1))
done
if [[ $n_scripts -ge $PISO_SCRIPTS ]]; then
    ok "scripts .sh = $n_scripts (piso $PISO_SCRIPTS)"
else
    ruim "scripts .sh = $n_scripts, piso $PISO_SCRIPTS -- sumiu shell script?"
fi

n_units=$(ls rootfs/etc/systemd/system/ 2>/dev/null | grep -c '^ravena-')
if [[ $n_units -ge $PISO_UNITS_RAVENA ]]; then
    ok "units ravena-* = $n_units (piso $PISO_UNITS_RAVENA)"
else
    ruim "units ravena-* = $n_units, piso $PISO_UNITS_RAVENA -- unit deletada?"
fi

n_nft=$(find rootfs \( -name '*.nft' -o -name '*.rules' \) -type f 2>/dev/null | wc -l)
if [[ $n_nft -ge $PISO_NFT_RULES ]]; then
    ok "arquivos .nft/.rules = $n_nft (piso $PISO_NFT_RULES)"
else
    ruim "arquivos .nft/.rules = $n_nft, piso $PISO_NFT_RULES -- regra de firewall/audit sumiu?"
fi

n_confs=$(ls rootfs/etc/ravena/ 2>/dev/null | wc -l)
if [[ $n_confs -ge $PISO_CONFS_ETC ]]; then
    ok "confs em rootfs/etc/ravena = $n_confs (piso $PISO_CONFS_ETC)"
else
    ruim "confs em rootfs/etc/ravena = $n_confs, piso $PISO_CONFS_ETC"
fi

# 3) formato dos manifestos --------------------------------------------------
# Linhas de dado = nao vazias e que nao comecam com '#'.
valida_manifesto() {
    local arquivo="$1" campos_esperados="$2" piso="$3" rotulo="$4"
    [[ -f "$arquivo" ]] || { ruim "$rotulo: $arquivo ausente"; return; }

    local linhas
    linhas=$(grep -cvE '^[[:space:]]*(#|$)' "$arquivo")
    if [[ "$linhas" -ge "$piso" ]]; then
        ok "$rotulo: $linhas linhas de dado (piso $piso)"
    else
        ruim "$rotulo: $linhas linhas de dado, piso $piso"
    fi

    # -F' \| ' separa exatamente por " | ". Contagem diferente = linha torta.
    local ruins
    ruins=$(awk -F' \\| ' -v n="$campos_esperados" '
        /^[[:space:]]*(#|$)/ { next }
        NF != n { printf "    linha %d tem %d campos (esperado %d): %s\n", NR, NF, n, $0; falha++ }
        END { print falha+0 }
    ' "$arquivo")
    if [[ "$ruins" -eq 0 ]]; then
        ok "$rotulo: toda linha com $campos_esperados campos"
    else
        awk -F' \\| ' -v n="$campos_esperados" '
            /^[[:space:]]*(#|$)/ { next }
            NF != n { printf "FALHA %s linha %d tem %d campos (esperado %d)\n", FILENAME, NR, NF, n }
        ' "$arquivo"
        ruim "$rotulo: $ruins linha(s) com numero de campos errado"
    fi
}

valida_manifesto rootfs/etc/ravena/pacotes-os.txt  "$CAMPOS_PACOTES"  "$PISO_PACOTES"  "OS-1 pacotes"
valida_manifesto rootfs/etc/ravena/servicos-os.txt "$CAMPOS_SERVICOS" "$PISO_SERVICOS" "OS-2 servicos"

# 3.1) checagens de conteudo (Bloco I, 2026-10-10) ---------------------------
# Guardam as entregas de conteudo do Bloco I que um piso nao captura (o piso
# so ve quantidade; estas veem "continua la").
tem() { # tem <arquivo> <padrao-grep> <rotulo>
    if grep -q -e "$2" "$1" 2>/dev/null; then
        ok "$3"
    else
        ruim "$3 ($1 sem '$2')"
    fi
}
tem rootfs/etc/systemd/system/ravena-shield.service '^CPUWeight=10$' \
    "shield: CPUWeight=10 (contencao de CPU)"
tem rootfs/usr/local/bin/ravena-llm.sh --cors-origins \
    "llama: feature-detection de --cors-origins (CORS opt-in)"
tem rootfs/etc/ravena/llm.conf LLM_CORS_ORIGINS \
    "llama: /etc/ravena/llm.conf com LLM_CORS_ORIGINS"
tem rootfs/usr/local/bin/ravena-adguard.sh 'exit 0' \
    "adguard: wrapper inerte (exit 0) sem binario"
tem rootfs/etc/ravena/adguardhome.yaml 'bind_host: 127.0.0.1' \
    "adguard: DNS em 127.0.0.1 (opt-in, resolved intacto)"
tem rootfs/etc/systemd/system/ravena-adguard.service 'WantedBy=multi-user.target' \
    "adguard: unit com [Install]"

# 4) coerencia OS-1 <-> OS-2 -------------------------------------------------
# Todo pacote extra/aur do OS-1 tem de ter linha no OS-2 (mesma regra do
# teste em ravena-aim, mas sem python -- e o OS que tem de se defender).
pacotes_instalaveis=$(awk -F' \\| ' '
    /^[[:space:]]*(#|$)/ { next }
    $2 == "extra" || $2 == "aur" { print $1 }
' rootfs/etc/ravena/pacotes-os.txt | sort -u)

forados_mapa=0
for p in $pacotes_instalaveis; do
    if ! awk -F' \\| ' -v alvo="$p" '
        /^[[:space:]]*(#|$)/ { next }
        $1 == alvo { achou=1; exit }
        END { exit achou ? 0 : 1 }
    ' rootfs/etc/ravena/servicos-os.txt; then
        printf 'FALHA OS-1<->OS-2: %s instalavel mas sem linha no mapa de units\n' "$p"
        forados_mapa=$((forados_mapa + 1))
    fi
done
if [[ $forados_mapa -eq 0 ]]; then
    ok "OS-1<->OS-2: todo extra/aur tem linha no mapa de units"
else
    ruim "OS-1<->OS-2: $forados_mapa pacote(s) fora do mapa"
fi

echo
if [[ $falhas -gt 0 ]]; then
    echo "REGRESSAO DO OS em $falhas checagem(ns)" >&2
    exit 1
fi
echo "BASELINE DO OS CONGELADO -- nenhuma regressao"
exit 0
