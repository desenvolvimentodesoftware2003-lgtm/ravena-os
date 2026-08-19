# RAVENA L1 - locale pt_BR ativo no shell
export LANG=pt_BR.UTF-8
export LC_ALL=pt_BR.UTF-8
export LANGUAGE=pt_BR
# RAVENA OS - perfil de login (ravena)
# 1o boot: assistente OOBE (rede/config) antes da interface grafica.
# Boots seguintes: pula direto para o OS (eDEX-UI) quando ja configurado.


# Iniciar interface grafica (eDEX-UI) no TTY1 (testar SEM travar/caem no tmux)
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    # Rede pos-OS (estilo Windows): painel so abre DENTRO do OS via ravena-net-ui.sh
    startx
    # se o X nao subir ou encerrar, cai no tmux (fallback terminal)
    [ -f ~/.bashrc ] && . ~/.bashrc
    exit 0
fi

# Demais sessoes (serial/pts/ssh): bashrc normal (inclui tmux automatico)
[ -f ~/.bashrc ] && . ~/.bashrc