#!/bin/bash
# RAVENA BOOT - painel de boot estilo "icone do Windows" (igual ravena-rede)
# Replica dentro do OS o menu GRUB/F12: escolhe a opcao e o PC reinicia nela.
# Mecanismo: grava /ravena.nextboot na ESP do pendrive (GRUB le no proximo
# boot e define default; menu oculto, boot direto como Windows) e reinicia.
# Nao altera a instalacao.
# Uso:  boot                      (menu completo)
#       boot --exec <id>          (acao direta p/ o widget BOOT do eDEX)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;36m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

[ "$(id -u)" -eq 0 ] || exec sudo "$0" "$@"

# ---- acha a ESP do pendrive de boot (onde fica o GRUB) ----
find_esp() {
    local bootsrc bootdisk
    bootsrc=$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null)
    [ -n "$bootsrc" ] || { echo "ERRO: bootmnt nao encontrado"; return 1; }
    bootdisk=$(lsblk -no PKNAME "$bootsrc" 2>/dev/null)
    [ -n "$bootdisk" ] || { echo "ERRO: disco de boot nao identificado"; return 1; }
    lsblk -npo NAME,PARTTYPE,TYPE "/dev/$bootdisk" 2>/dev/null | \
        awk '$3=="part" && $2=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b"{print $1; exit}'
}

# ---- grava o one-shot na ESP e reinicia ----
boot_once() { # $1=id GRUB da entrada (ou titulo para shell)
    local esp title="$1"
    esp=$(find_esp)
    if [ -z "$esp" ]; then
        echo -e "${RED}ERRO: ESP do pendrive nao encontrada.${NC}"
        echo "  Reiniciando normal (o menu GRUB aparece com o F12/tecla)."
        read -r -p "Enter p/ reiniciar, Ctrl+C p/ cancelar" _
        systemctl reboot
        return
    fi
    mkdir -p /mnt/ravboot
    mount -o rw "$esp" /mnt/ravboot 2>/dev/null || { echo -e "${RED}ERRO: nao consegui montar a ESP.${NC}"; return 1; }
    {
        echo "set default=\"$title\""
    } > /mnt/ravboot/ravena.nextboot
    sync
    umount /mnt/ravboot
    echo -e "${GREEN}Proximo boot: ${WHITE}$title${NC} (boot direto, sem menu)"
    sleep 2
    systemctl reboot
}

# ---- acao direta (widget eDEX) ----
if [ "$1" = "--exec" ]; then
    case "$2" in
        ravena)                     boot_once "ravena" ;;
        archlinux-accessibility)    boot_once "archlinux-accessibility" ;;
        shell)                      boot_once "UEFI Shell" ;;
        firmware)                   boot_once "uefi-firmware" ;;
        shutdown)                   echo -e "${RED}Desligando...${NC}"; sleep 2; systemctl poweroff ;;
        restart)                    echo -e "${YELLOW}Reiniciando...${NC}"; sleep 2; systemctl reboot ;;
        *)                          echo "opcao desconhecida: $2"; exit 1 ;;
    esac
    exit 0
fi

info_grub() {
    echo
    echo -e "${WHITE}=== MENU DE BOOT (GRUB/F12) ===${NC}"
    echo -e "  Estas sao as mesmas opcoes que aparecem ao ligar o PC"
    echo -e "  antes do sistema abrir. Aqui voce escolhe e o PC reinicia"
    echo -e "  direto para a opcao selecionada (sem tela de menu)."
    echo
}

opcoes() {
    echo -e "${WHITE}==========================="
    echo -e "  RAVENA BOOT${NC} (digite o numero, 0 sai)"
    echo -e "${WHITE}===========================${NC}"
    echo -e "  1) ${GREEN}RAVENA OS${NC}          - boot normal do sistema"
    echo -e "  2) ${GREEN}Modo Seguro${NC}        - sem acessibilidade (leitor de tela off)"
    echo -e "  3) ${YELLOW}UEFI Shell${NC}         - shell do firmware (diag/manutencao, sem OS)"
    echo -e "  4) ${YELLOW}Firmware Settings${NC}  - entra direto na BIOS/UEFI Setup"
    echo -e "  5) ${RED}System shutdown${NC}     - desliga o PC"
    echo -e "  6) ${RED}System restart${NC}      - reinicia o PC"
    echo -e "  0) Sair (voltar ao OS)"
    echo -e "${WHITE}===========================${NC}"
    echo -e "${YELLOW}O PC vai REINICIAR para a opcao escolhida.${NC}"
    echo
}

menu_main() {
    while true; do
        clear
        info_grub
        opcoes
        read -r -p "Escolha: " op
        case "$op" in
            1) boot_once "ravena" ;;
            2) boot_once "archlinux-accessibility" ;;
            3) boot_once "UEFI Shell" ;;
            4) boot_once "uefi-firmware" ;;
            5) echo -e "${RED}Desligando...${NC}"; sleep 2; systemctl poweroff ;;
            6) echo -e "${YELLOW}Reiniciando...${NC}"; sleep 2; systemctl reboot ;;
            0|"") clear; exit 0 ;;
            *) echo -e "${RED}Opcao invalida.${NC}"; sleep 1 ;;
        esac
    done
}

menu_main