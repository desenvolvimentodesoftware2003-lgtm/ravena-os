#!/usr/bin/env bash
# verif_estrutura.sh -- Fase 0, lado OS (ravena-os).
#
# Protege o que um refator mal feito quebra em silencio na ISO:
#
#   1. sintaxe de todo .sh (bash -n) -- um `if` aberto quebra o build inteiro;
#   2. symlinks mode 120000 -- o git so preserva symlink se o modo for 120000,
#      e o rootfs tem 6 que nao podem virar arquivo de texto;
#   3. CRLF -- o rootfs e LF; CRLF num script executavel da ISO vira
#      "/bin/bash^M: bad interpreter".
#
# Uso:  bash tools/verif_estrutura.sh
# Sai com 1 se qualquer checagem falhar.

set -u
cd "$(dirname "$0")/.." || exit 1

falhas=0
ok()   { printf 'OK   %s\n' "$1"; }
ruim() { printf 'FALHA %s\n' "$1"; falhas=$((falhas + 1)); }

PISO_SYMLINKS=6

# 1) sintaxe dos shell scripts ----------------------------------------------
shopt -s globstar nullglob
scripts=(**/*.sh tools/*.sh)
shopt -u globstar
declare -A vistos
sintaxe=0
for s in "${scripts[@]}"; do
    [[ -n "${vistos[$s]:-}" ]] && continue
    vistos[$s]=1
    [[ -f "$s" ]] || continue
    if bash -n "$s" 2>/dev/null; then
        sintaxe=$((sintaxe + 1))
    else
        ruim "bash -n $s"
    fi
done
[[ $sintaxe -gt 0 ]] && ok "bash -n em $sintaxe script(s)" || ruim "nenhum .sh encontrado"

# 2) symlinks mode 120000 ----------------------------------------------------
n=$(git ls-files -s | awk '$1 == "120000"' | wc -l)
if [[ "$n" -eq "$PISO_SYMLINKS" ]]; then
    ok "symlinks 120000 = $n"
else
    ruim "symlinks 120000 = $n (esperado $PISO_SYMLINKS) -- symlink virou arquivo de texto?"
fi

# toda entrada 120000 precisa estar em rootfs/etc/systemd/system
forudo=$(git ls-files -s | awk '$1 == "120000" {print $4}' | grep -cv '^rootfs/etc/systemd/system/' || true)
if [[ "$forudo" -eq 0 ]]; then
    ok "symlinks todos em rootfs/etc/systemd/system"
else
    ruim "$forudo symlink(s) 120000 fora de rootfs/etc/systemd/system"
fi

# 3) CRLF no rootfs ----------------------------------------------------------
# So arquivos de texto. Byte 0x0D em binario (.wav do edex-ui, por exemplo)
# e dado legitimo, nao CRLF -- medir tudo ja marcou 18 falsos positivos.
#
# A allowlist por extensao tem um buraco: os executaveis de /usr/local/bin/
# na maioria NAO tem extensao (ravena-update, ravena-ia, horas, intel, llm...).
# CRLF em qualquer um deles vira "/bin/bash^M: bad interpreter" na ISO, e a
# allowlist sozinha deixava passar. Correcao achada pela prova de mutacao do
# OS-7: shebang tambem e texto.
texto=0
crlf=0
while IFS= read -r -d '' f; do
    caso=0
    case "$f" in
        *.sh|*.service|*.socket|*.slice|*.timer|*.mount|*.target|*.path|*.link|\
        *.conf|*.nft|*.rules|*.cfg|*.txt|*.json|*.toml|*.yaml|*.yml|\
        *.md|*.ps1|*.py|*.desktop|*.list|*.repo|*.install|*.hook)
            caso=1
            ;;
        *)
            # sem extensao (ou extensao desconhecida): se comeca com #!, e script
            if [[ "$(head -c 2 "$f" 2>/dev/null)" == '#!' ]]; then
                caso=1
            fi
            ;;
    esac
    if [[ $caso -eq 1 ]]; then
        texto=$((texto + 1))
        # tr, nao grep: o GNU grep 3.0 do Git Bash nao casa CR de forma
        # confiavel no caminho rootfs/... (dava falso "0 com CRLF" e o guard
        # inteiro era no-op desde o F0.4). tr -dc '\r' | wc -c foi medido
        # certo em arquivo LF puro e em arquivo com CRLF.
        if [[ "$(tr -dc '\r' < "$f" | wc -c)" -gt 0 ]]; then
            crlf=$((crlf + 1))
            ruim "CRLF em $f"
        fi
    fi
done < <(find rootfs -type f -print0 2>/dev/null)

if [[ "$texto" -eq 0 ]]; then
    ruim "nenhum arquivo de texto encontrado em rootfs/"
elif [[ "$crlf" -eq 0 ]]; then
    ok "rootfs: $texto arquivo(s) de texto, 0 com CRLF"
fi

# 4) manifestos OS-1/OS-2 no lugar certo ------------------------------------
# Ja aconteceu: arquivo escrito em etc/ravena/ em vez de rootfs/etc/ravena/,
# e o test em ravena-aim lia o caminho errado e passava verde. Um arquivo fora
# do rootfs nao entra na ISO e ninguem percebe.
manifestos=(rootfs/etc/ravena/pacotes-os.txt rootfs/etc/ravena/servicos-os.txt)
for m in "${manifestos[@]}"; do
    if [[ -f "$m" ]]; then
        ok "manifesto presente: $m"
    else
        ruim "manifesto ausente (fora do rootfs?): $m"
    fi
done

echo
if [[ $falhas -gt 0 ]]; then
    echo "ESTRUTURA QUEBRADA em $falhas checagem(ns)" >&2
    exit 1
fi
echo "ESTRUTURA OK"
exit 0
