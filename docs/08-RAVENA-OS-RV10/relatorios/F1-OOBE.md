# F1 — OOBE de Primeiro Boot (estilo Windows/MEC)

**Status:** ✅ Implementado + validado na VM
**Data:** 2026-08-12

## Objetivo

Primeira configuração do sistema com assistente semelhante ao Windows/MEC:
detecta falta de internet e guia o usuário a conectar antes de prosseguir.

## O que foi feito

### `/usr/local/bin/ravena-oobe.sh`

- Executa **somente enquanto não existir o marcador de conclusão** (`oobe-done`)
- Se já há internet → sai silencioso (sem interferir no boot)
- Sem internet → mostra a tela **"BEM-VINDO AO RAVENA OS"** e abre o painel
  `ravena-rede.sh` (1=WiFi, 2=cabo, 3=nmtui, 4=desconectar, 5=IP/DNS)
- Após conectar → chama `ravena-sync-rede.sh` (persiste o perfil WiFi na RAVENA-DATA)
- Cria marcador local (`/etc/ravena/oobe-done`) **e** persistido
  (`/mnt/ravena-data/ravena/config/oobe-done`) — não re-exibe no próximo boot
- Alias `oobe` para rodar manualmente

### Integração

- Chamado no `.bash_profile` ANTES do `startx` (só no tty1)

## Validação (VM, off-line)

| Teste | Resultado |
|---|---|
| Banner "BEM-VINDO AO RAVENA OS" exibido sem internet | ✅ |
| Painel de rede abre (interativo) | ✅ |
| Marcador criado após conclusão (`/etc/ravena/oobe-done` + `RAVENA-DATA/config/oobe-done`) | ✅ |
| OOBE **não** re-exibe quando marcador existe | ✅ |
| Sem internet não trava o boot (saída limpa) | ✅ |

## Detalhes técnicos

- O teste interativo na VM exige PTY real (`script -qec`) porque o painel
  `ravena-rede.sh` usa `read` interativo — sem TTY, o fluxo fica preso no menu.
