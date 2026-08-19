# F2 — Persistência Real (a causa do "ciclo")

**Status:** ✅ Implementado + validado na VM
**Data:** 2026-08-12

## Problema original

No live ISO, `/etc` e `/home` são tmpfs — toda senha, perfil WiFi e configuração
sumiam a cada reboot. A solução: **RAVENA-DATA**, partição própria criptografada
com LUKS2 e persistência bidirecional.

## O que foi feito

### `/usr/local/bin/ravena-data.sh` (script de persistência)

- **1º boot**: detecta partição sem formato → cria **LUKS2**
  (AES-256-XTS, chave 512 bits, PBKDF Argon2id, `--iter-time 2000`), gera:
  - `data.key` (64 bytes aleatórios) — usada no boot, sem interação
  - `recovery.key` (20 caracteres) — **impressa na tela no 1º boot, imprimir e guardar**
- Formata ext4 (`RAVENA-DATA`), monta em `/mnt/ravena-data`
- **Boots seguintes**: restaura chaves do pendrive e reabre o LUKS
  automaticamente (sem pedir senha)
- Persiste: perfis WiFi (`system-connections`), dotfiles (`.bashrc`,
  `.bash_profile`, `.tmux.conf`, `.gitconfig`), config do eDEX-UI, chaves
- `/home/ravena/.ravena` → symlink para `/mnt/ravena-data/ravena`
  (config+cache sobrevivem ao live ISO)
- `ravena-sync-rede.sh`: sincroniza perfis WiFi criados no boot atual

### Persistência das chaves no pendrive

Chaves ficam em `ravena-keys/` na **partição EFI do pendrive** (funciona mesmo em
modo DD, onde o bootmnt é ISO9660 ro). Ordem de busca da ESP em `find_esp_partition`:

1. Disco removível com vfat ≤ 1 GiB (pendrive real)
2. **ESP marcada** `PARTLABEL/LABEL=ESP` em qualquer disco (fix para VM/QEMU e modo instalado)
3. Modo instalado (`/etc/ravena/instalado` existe)
4. Fallback: removível sem filtro de tamanho

**Nunca** grava na ESP do Windows (disco interno).

### Serviço systemd

- `ravena-data.service` em `sysinit.target.wants` — roda **antes** do NetworkManager
  e do login (não trava o boot)

## Validação (VM, off-line)

### 1º boot (13/13 checks)
| Check | Resultado |
|---|---|
| LUKS criado + recovery.key impresso | ✅ |
| RAVENA-DATA montada em `/mnt/ravena-data` | ✅ |
| `.ravena` linkado | ✅ |
| Estrutura `ravena/{cache,chaves,config}` criada | ✅ |
| Dotfiles persistidos | ✅ |
| Chaves gravadas na ESP (`ravena-keys/data.key` + `recovery.key`) | ✅ |

### 2º boot (11/11 checks)
| Check | Resultado |
|---|---|
| Chaves restauradas da ESP → `/etc/ravena` | ✅ |
| LUKS reaberto sem interação (`aes-xts-plain64`) | ✅ |
| RAVENA-DATA montada | ✅ |
| Dados do 1º boot preservados | ✅ |
| Dotfiles restaurados da partição | ✅ |
| **NÃO** recriou o LUKS | ✅ |
| eDEX-UI persistente | ✅ |

## Correção de bug durante a validação

- **Bug**: `find_esp_partition` não achava a ESP na VM (QEMU reporta
  `removable=0` no sysfs) → chaves nunca persistiam
- **Fix**: passo 1b — aceitar ESP com `PARTLABEL=ESP` ou `LABEL=ESP` em qualquer
  disco (validado e rebuildado no ISO final)
