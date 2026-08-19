# ESTADO_VALIDADO â€” Manifesto anti-regressÃ£o do Ravena OS (RV10)

> **Regra de ouro:** Nada Ã© "âœ…" sem teste REAL do usuÃ¡rio no PC (Latitude 5400).
> VM (VirtualBox) serve apenas para lÃ³gica de boot/persistÃªncia â€” **nunca** para
> declarar hardware/rede/IA funcionando.
> Todo ciclo: **1 correÃ§Ã£o â†’ 1 build â†’ 1 gravaÃ§Ã£o â†’ 1 teste real.**
> Criado: 2026-08-16 (apÃ³s v8 â€” placeholder de rede + OOBE perdido no real).
> Atualizado: 2026-08-19 (v20 â€” seguranÃ§a S1-S7 + hora + locale pt-BR + eDEX traduzido â€” TESTADA NO REAL).

---

## BUILD ATUAL

| Campo | Valor |
|---|---|
| VersÃ£o | **RV10v20** |
| ISO | `C:\Users\DELL\RAVENA-ISOS\ravena-remaster-RV10v20.iso` |
| Kernel | 7.1.5-arch1-2 (ISO = rootfs, verificado) |
| SHA512 ISO | `a6036be48bb06adf843eed357c8bacb794b0094996924c4e02e437ba7af9d654893c4535715bb8fc7525b1d61740654c89f595205a13ecfcc61bab5ae11b1118` |
| Build | `/root/ravv2/build_rv10v20.sh` (19/08 14:00) |
| Pendrive | SanDisk Cruzer Blade (Disk 1, 114.6GB) â€” **RV10v20 GRAVADA (Rufus, 19/08 ~14:30) e VERIFICADA 8/8 IGUAL (14:39, verif_v20.ps1)** |
| Firmware 9560 | `QuZ-a0-jf-b0` atÃ© v77 (presente no sfs, kernel >= 5.10 OK) |

---

## O QUE ESTÃ VALIDADO NO PC REAL (nÃ£o regredir!)

| # | Item | Status | EvidÃªncia |
|---|---|---|---|
| R1 | Boot pelo pendrive (F12 â†’ SanDisk) | âœ… REAL | Teste v8/v9/v12/v13 |
| R2 | Kernel/initramfs sem PANIC | âœ… REAL | Teste v8â€“v13 |
| R3 | Shell/terminal disponÃ­vel | âœ… REAL | Teste v8 |
| R4 | Campo de digitaÃ§Ã£o IA nÃ£o rouba foco | âœ… REAL | UsuÃ¡rio confirmou (F9) |
| R5 | eDEX-UI abre no real | âœ… REAL | Teste v8 (widget RAVENA REDE visÃ­vel) |
| R6 | **WiFi: redes aparecem** | âœ… REAL | v10 (ALEXJOSI, wonk, 0582 Pref Osasco, Paloma, ALEXJOSI-5G, Souza 2G, Jessica, Jessica 5G, VMR-2-G) |
| R7 | **WiFi: conectar em rede + senha** | âœ… REAL | v12 (`110922Pg`, conexÃ£o OK â€” senha maiÃºscula NÃƒO era o problema) |
| R8 | **LAN/cabo: internet no boot** | âœ… REAL | v12 (cabo â†’ OOBE nem aparece) |

## O QUE REPROVOU E FOI CORRIGIDO (registro de causas)

| # | Item | Causa raiz | CorreÃ§Ã£o (versÃ£o) |
|---|---|---|---|
| X1 | WiFi: NM nÃ£o criava `wlo1` | `wifi.conf` com `wifi.backend=iwlwifi` (backend invÃ¡lido) â†’ `unknown or unsupported wifi-backend` / `factory failed to create device` | Removida a linha do backend (v10) |
| X2 | WiFi: "Insufficient privileges" ao conectar | usuÃ¡rio `ravena` sem permissÃ£o NM: sem grupo `network`, polkit cobria sÃ³ `network-control` (faltava `settings.modify.system` p/ "adicionar" conexÃ£o) | grupo `network:x:90:ravena` + polkit cobrindo TODAS as aÃ§Ãµes `org.freedesktop.NetworkManager` + `sudo` no `ravena-rede.sh` (v12) |
| X3 | WiFi: nÃ£o reconectava no boot | Pendrive em **modo DD sem partiÃ§Ã£o de dados** â†’ RAVENA-DATA nunca criada â†’ perfis WiFi/keys/marcadores sumiam (tmpfs) | `create_data_partition()` no `ravena-data.sh`: cria partiÃ§Ã£o no espaÃ§o livre â‰¥4GiB apÃ³s o ISO (sÃ³ pendrive removÃ­vel, nunca NVMe) â†’ LUKS2+ext4 no 1Âº boot (v13) |
| X4 | OOBE aparecia ANTES do OS (tela preta) | `.bash_profile` chamava `ravena-oobe.sh` antes do `startx` | OOBE removido do boot; novo `ravena-net-ui.sh` abre o painel `rede` DENTRO do OS (janela tmux, nÃ£o-bloqueante, estilo Windows) (v13) |
| X5 | Pastas do sistema poluÃ­am a Ã¡rea de dev | `modelos`/`scripts`/`tmp` soltos em `/home/ravena` + dotfiles visÃ­veis | Centralizado em `/home/ravena/os/` + `hideDotfiles=true` no eDEX; `projects` fica no topo (v13) |
| X6 | llama-server subia no boot (consumo) | autostart `ravena-llm.service` | Service desabilitado; `llm provedor` sobe sob demanda via serviÃ§o (mantÃ©m cgroups) (v13) |
| X7 | **RAVENA-DATA NUNCA criada no real (v13)** | `part_type()` varria TODAS as partiÃ§Ãµes e achou `nvme0n1p1` (LUKS2 do NVMe interno) â†’ tentava abrir sem chave â†’ `open_luks || exit 0` **antes** de `create_data_partition()` rodar â†’ sem partiÃ§Ã£o, sem persistÃªncia, sem WiFi no reboot | `disk_ok()` filtra: sÃ³ aceita partiÃ§Ã£o do BOOTDISK (derivado de `/run/archiso/bootmnt`) ou disco removÃ­vel â€” NVMe interno ignorado (v14). Bonus: `create_data_partition()` nunca mais devolve a ESP via `tail -1` (filtra por `START >= start_lba`); dispatcher NM `10-ravena-sync` persiste perfil WiFi criado pela bolha pÃ³s-boot; `ravena` em `adm,systemd-journal` (diag); `.xinitrc` sem auto-open do painel `rede` (bolha Ã© a interface Ãºnica) (v14) |

---

## CHECAGEM PRÃ‰-GRAVAÃ‡ÃƒO (anti-regressÃ£o â€” rodar SEMPRE)

1. `diff -rq edex-ui-src rootfs/opt/edex-ui/src` â†’ vazio
2. `diff -rq home-ravena rootfs/home/ravena` â†’ vazio
3. `diff -rq usr-local-bin rootfs/usr/local/bin` â†’ vazio
4. `unsquashfs -cat <sfs> home/ravena/.bash_profile` â†’ **0** ocorrÃªncias de `ravena-oobe` (OOBE pÃ³s-OS)
5. `unsquashfs -cat <sfs> home/ravena/.xinitrc` â†’ **0** ocorrÃªncias de `ravena-net-ui` (bolha Ã© a interface Ãºnica)
6. `unsquashfs -cat <sfs> usr/local/bin/ravena-data.sh` â†’ contÃ©m `disk_ok()` + `BOOTDISK` + `awk -v s="$start_lba"`
7. `unsquashfs -cat <sfs> etc/systemd/system/multi-user.target.wants/ravena-llm.service` â†’ **ausente**
8. `unsquashfs -cat <sfs> home/ravena/.config/eDEX-UI/settings.json` â†’ `hideDotfiles: true`
9. Kernel: `ls rootfs/lib/modules` == versÃ£o no sfs
10. Backup da RAVENA-DATA antes do DD (Rufus DD apaga o pendrive INTEIRO)
11. **Antes do START no Rufus: `wsl --shutdown` (libera handles do WSL no Disco 1) + confirmar Disco 1 Online/RO=False; se falhar no meio (erro 0x5), EJEITAR o pendrive e reconectar antes do 2Âº START**
12. Gravar â†’ `verif_v15.ps1` (blocos IGUAL â€” tratar bloco final parcial)
13. `unsquashfs -cat <sfs> etc/NetworkManager/dispatcher.d/10-ravena-sync` â†’ existe; `etc/group` â†’ `adm`/`systemd-journal` contÃªm `ravena`

*Resultado da v15: itens 1â€“3 idÃªnticos, item 4 = 0 (correto), item 5 = 0 (correto), itens 6â€“12 OK, kernel bate; gravaÃ§Ã£o inicial falhou (0x5 no setor 15204352) â†’ `wsl --shutdown` + regravaÃ§Ã£o â†’ verif 8/8 IGUAL (18/08 07:53); TESTE REAL subiu de primeira.*

---

## REGISTRO DE CICLOS

| Ciclo | CorreÃ§Ã£o | Build | GravaÃ§Ã£o | Teste real | Resultado |
|---|---|---|---|---|---|
| v8â†’v9 | placeholder + OOBE + rede-diag | 16/08 17:10 | 16/08 ~20:30 Rufus DD + verif (4/4 + tail) | 16/08 | âœ… boot real, `wlo1` presente, firmware carregado |
| v9â†’v10 | `wifi.backend` invÃ¡lido removido | 17/08 ~12:00 | 17/08 Rufus DD + verif | 17/08 | âœ… redes WiFi aparecem |
| v10â†’v11 | grupo `network` + polkit `network-control` | 17/08 ~14:49 | 17/08 Rufus DD | 17/08 | âŒ "Insufficient privileges" (polkit incompleto) |
| v11â†’v12 | polkit completo + sudo rede.sh + grupo | 17/08 16:08 | 17/08 Rufus DD (UAC) + verif 8/8 | 17/08 | âœ… **WiFi conecta** (R7) |
| v12â†’v13 | persistÃªncia DD + OOBE pÃ³s-OS + os/ + llm sob demanda | 17/08 21:04 | 17/08 Rufus DD (2Âª tentativa) + verif 7/7+parcial | 18/08 ~00:00 | âŒ **RAVENA-DATA nÃ£o criada** â€” diag real: `part_type()` achou LUKS do NVMe interno e saiu antes de criar partiÃ§Ã£o (X7) |
| v13â†’v14 | X7: `disk_ok`+`BOOTDISK` (ignora NVMe) + create_data_partition por setor + dispatcher sync WiFi + grupos diag + xinitrc sem painel | 18/08 01:20 | 18/08 Rufus DD (GUI manual, START+DD mode) + verif 7/7+parcial | **pendente** | â€” |
| v14â†’v15 | U1: abas eDEX independentes (tmux nÃ£o anexa mais todas as abas na mesma sessÃ£o `ravena` dentro do eDEX) + U2: `ravena-boot-menu.sh` + alias `boot` (menu GRUB que reinicia para a opÃ§Ã£o) | 18/08 04:04 | 18/08 1Âª gravaÃ§Ã£o **FALHOU no setor 15204352 (acesso negado 0x5 â€” regiÃ£o da partiÃ§Ã£o v14 ainda segura pelo Windows; a 2Âª gravaÃ§Ã£o tambÃ©m nÃ£o completou o final â†’ verif 7/7 + parcial DIFERENTE)** â†’ regravado apÃ³s `wsl --shutdown` + verif 8/8 IGUAL (07:53) | 18/08 | âœ… **TESTE REAL: subiu de primeira** |
| v15â†’v16 | U2 evoluÃ§Ã£o: widget BOOT no eDEX (bolha arrastÃ¡vel estilo RAVENA REDE, 6 opÃ§Ãµes com confirmaÃ§Ã£o) + `ravena-boot-menu.sh` reescrito com **boot one-shot real via `/ravena.nextboot` na ESP do pendrive** (`grub-reboot` nÃ£o funciona no archiso live) + grub.cfg do ISO com bloco `search --file /EFI/BOOT/BOOTx64.EFI` + `source (esp)/ravena.nextboot` | 18/08 08:56 | 18/08 Rufus DD (apÃ³s `wsl --shutdown`) + verif 8/8 IGUAL (10:09) | 18/08 | âœ… boot subiu + widget BOOT visÃ­vel no eDEX (usuÃ¡rio confirmou) |
| v16â†’v17 | U3: **menu GRUB OCULTO** (boot direto tipo Windows: `timeout=2` + `timeout_style=hidden`; segure tecla nos 2s p/ ver o menu) + **auto-clean one-shot**: GRUB esvazia `/ravena.nextboot` via `write` apÃ³s o `source` (sem loop no UEFI Shell/Firmware) + reforÃ§o `ravena-nextboot-clean.service` no boot do OS + `ravena-boot-menu.sh` simplificado (nextboot sÃ³ grava `set default`) | 18/08 10:49 | 18/08 Rufus (1Âª tentativa erro, 2Âª OK) + verif 8/8 IGUAL (12:12) | **pendente** | â€” |
| v17â†’v18 | U4: **FIX widget BOOT** â€” `_renderOptions()` nunca era chamado (painel abria vazio, sem as 6 opÃ§Ãµes) + `_refreshBootInfo()` blindado com try/catch (Uncaught Error no console) | 18/08 12:42 | 18/08 Rufus (rufus.com) + verif 8/8 IGUAL (13:25) | 18/08 | âœ… widget BOOT com as 6 opÃ§Ãµes (usuÃ¡rio confirmou "deu certo") |
| v18â†’v19 | S1-S7 seguranÃ§a (firewall nft LAN-only, root off SSH, IA 127.0.0.1, LLMNR off, sudo restrito, auditd, chage 90d) + H1 hora (adjtime LOCAL + chrony) + L1 locale pt_BR + L2 eDEX pt-BR + C1 limpeza + U5 menu contexto | 18/08 16:23 | 19/08 Rufus + verif 8/8 IGUAL (17:57) | 19/08 | âŒ **TELA PRETA** â€” S6 (sudo restrito) bloqueou `ln`/`chmod` do `.xinitrc` no boot (pedia senha, travava o X) + chrony morreu (`rtcfile`+`rtcsync` incompatÃ­veis) |
| v19â†’v20 | FIX v19: sudoers com `ln`/`chmod` NOPASSWD + **ordem correta** (no sudoers a Ãºltima regra vence; `ALL` com senha foi movido para o topo) + chrony sem `rtcfile` | 19/08 14:00 | 19/08 Rufus (rufus.com) + verif 8/8 IGUAL (14:39) | 19/08 | âœ… **TESTE REAL: eDEX sobe, hora certa (chrony step -3h), locale pt_BR, IA 127.0.0.1, botÃ£o direito Copiar/Colar funcionando, widgets BOOT+NET validados** |

## CORREÃ‡Ã•ES DE UI (implementadas e validadas no v15 â€” TESTE REAL OK)

| # | Pedido do usuÃ¡rio | ImplementaÃ§Ã£o | Status |
|---|---|---|---|
| U1 | **Abas do eDEX independentes** (clicar numa aba continuava mostrando o conteÃºdo de outra) | Causa: `.bashrc` rodava `tmux new -As ravena` â†’ **todas as abas anexavam na MESMA sessÃ£o tmux**. Fix: dentro do eDEX (DISPLAY setado) NÃƒO inicia tmux â†’ cada aba Ã© um bash independente; tmux sÃ³ no fallback/ssh. Arquivo: `home/ravena/.bashrc` | âœ… **v15 TESTE REAL: subiu de primeira** |
| U2 | **Menu de boot dentro do OS** que reinicia para a opÃ§Ã£o escolhida (replica GRUB/F12: RAVENA OS, Modo Seguro, UEFI Shell, Firmware, desligar, reiniciar) | Novo `usr/local/bin/ravena-boot-menu.sh` (menu colorido + `--exec` para widget) + alias `boot` no `.bashrc` + **widget BOOT no eDEX** (`bootmanager.class.js` + `mod_boot.css`, bolha arrastÃ¡vel) + **grub.cfg one-shot via `/ravena.nextboot` na ESP** (`grub-reboot` nÃ£o existe no archiso live) | âœ… v16 VM (menu + `--exec` + widget carregado) |
| U5 | **Menu de contexto (botÃ£o direito) com Copiar/Colar** | `window.addEventListener("contextmenu")` em `_renderer.js` com `remote.Menu.buildFromTemplate([Copiar, Colar, Selecionar tudo])`, ligado ao clipboard do xterm (mesmos atalhos COPY/PASTE) | âœ… v20 TESTE REAL: Copiar/Colar funcionando |

## CORREÃ‡Ã•ES DE SEGURANÃ‡A (v19/v20 â€” aplicadas e validadas)

| # | Medida | ImplementaÃ§Ã£o | ValidaÃ§Ã£o |
|---|---|---|---|
| S1 | Firewall de entrada (LAN only) | `etc/ravena/ravena-sec-firewall.nft` + `ravena-sec-firewall.service` (nftables: SSH/IA sÃ³ de sub-redes privadas, resto drop) | âœ… v20 VM (service active) |
| S2 | SSH hardening | `PermitRootLogin no` + `MaxAuthTries 2` + `LoginGraceTime 30` + `LogLevel VERBOSE` (10-archiso.conf) | âœ… v20 VM + real (`MaxAuthTries 2`) |
| S3 | ExpiraÃ§Ã£o de senha (90d) | `ravena-chage.service` (one-shot, `chage -M 90 -W 7 ravena`) | âœ… v20 VM (service active) |
| S4 | IA somente local | `ravena-llm.sh` `--host 127.0.0.1` + airllm `make_server("127.0.0.1")` | âœ… v20 real (`127.0.0.1:8080`) |
| S5 | LLMNR/mDNS off | `resolved.conf` `LLMNR=no` + `MulticastDNS=no` | âœ… v20 VM (porta 5355 fechada) |
| S6 | sudo NOPASSWD restrito | `sudoers.d/ravena` (ravena-*, nmcli, efibootmgr, mount/umount/findmnt/lsblk, ln, chmod; **`ALL` com senha no TOPO** â€” a Ãºltima regra vence no sudoers) | âœ… v20 VM (6 regras NOPASSWD; pacman pede senha) |
| S7 | Auditd + journald persistente | `audit.rules` (shadow/passwd/sudoers/ssh/exec) + `journald.conf` Storage=persistent 500M/90d | âœ… v20 VM (auditd active) |

*Nota v19: a 1Âª tentativa de seguranÃ§a (v19) quebrou o boot (tela preta) porque `ln`/`chmod` do `.xinitrc` ficaram fora do NOPASSWD e a regra `ALL` (com senha) anulava as NOPASSWD por ficar por Ãºltimo. Corrigido na v20: `ln`/`chmod` liberados + ordem invertida. LiÃ§Ã£o: ao restringir sudo, SEMPRE testar o boot completo (X/eDEX) na VM antes de gravar.*

*Nota gravaÃ§Ã£o v15: a 1Âª gravaÃ§Ã£o falhou (acesso negado 0x5 no setor 15204352 â€” Windows segurava a regiÃ£o da partiÃ§Ã£o v14) e a 2Âª nÃ£o completou o final (verif parcial DIFERENTE). CorreÃ§Ã£o: `wsl --shutdown` + re-gravaÃ§Ã£o â†’ verif 8/8 IGUAL. LiÃ§Ã£o: SEMPRE `wsl --shutdown` e garantir Disco Online antes do START no Rufus; se falhar, ejetar e reconectar o pendrive.*



