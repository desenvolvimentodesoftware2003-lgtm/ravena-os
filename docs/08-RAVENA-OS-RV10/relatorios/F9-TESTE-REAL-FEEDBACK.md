# F9 — Teste Real no PC (Latitude 5400) — Feedback do Usuário

**Status:** 🔴 REGRESSÕES ENCONTRADAS — teste real reprovou em rede e IA
**Data:** 2026-08-15 (após boot do pendrive no PC real)

## Feedback literal do usuário (fonte primária)

> "Não está do jeito que eu gostaria. Eu estou com a VM do Oracle aberto, aqui
> está online, por conta do Windows. Quando eu fui testar na máquina real estava
> offline, eu acredito que seja por que não tem configuração ativa, parece que
> estamos rodando em ciclo. Mas tem um detalhe: teve regressão do provedor da
> inteligência artificial. A única coisa que funcionou foi o espaço da digitação
> que não muda mais. Somente isso."

## Diagnóstico do usuário (traduzido)

| Problema | Observação do usuário | O que significa tecnicamente |
|---|---|---|
| **Rede OFFLINE no PC real** | "online na VM por conta do Windows; offline na máquina real; parece que não tem configuração ativa; parece um ciclo" | A VM usa NAT do VirtualBox (rede "grátis" do Windows). No PC real o WiFi/cabo não conectou — sem conexão ativa no boot. |
| **Regressão no provider de IA** | "teve regressão do provedor da inteligência artificial" | O provider (llama-server) que funcionava antes — agora não funciona no PC real. |
| **Única melhoria real** | "o espaço da digitação não muda mais" | O patch F4 no eDEX-UI (_renderer.js onmouseup) FUNCIONOU — o campo de digitação da IA segura o foco agora. |

## Lição aprendida (o que mudar no processo)

- ❌ **Os testes na VM deram falsa confiança**: rede NAT emulado, hardware
  emulado, tudo "OK" lá não prova nada no PC real.
- ❌ **"Validado na VM" ≠ "funciona no PC real"** — VM valida lógica de boot e
  persistência, mas NÃO valida: driver WiFi real, provider IA real, rede real.
- ✅ A validação que importa é a do usuário no PC real (visão humana).
- Próximo ciclo: corrigir os 2 pontos reais (rede + IA), re-gravar, e o usuário
  testa de novo — UM ciclo por vez, sem "declarar vitória" antes do teste real.

## Prioridades (do mapeamento OS completo)

1. **REDE** — configurar rede ativa no 1º boot (NetworkManager + wifi + DHCP + DNS)
2. **IA** — investigar regressão do provider (llama-server) no PC real
3. Demais itens do mapeamento (ver `MAPEAMENTO-OS-COMPLETO.md`)

## DIAGNÓSTICO TÉCNICO (2026-08-15, investigação na VM + repo)

### 🔴 BUG 1 — REDE: OOBE não roda (causa raiz encontrada no código)

- O `.bash_profile` do repo (`ravena-archiso/home-ravena/.bash_profile`) **NÃO
  chama `ravena-oobe.sh`** antes do `startx` — só faz `startx` e cai no tmux.
- Consequência: no PC real (sem NAT), ninguém oferece configurar WiFi → offline.
- Na VM funciona porque o NAT do VirtualBox entrega rede "de graça".
- **Regressão**: a F1 (OOBE integrado no boot) foi removida no repo, mas o
  relatório F1 dizia implementada → a ISO v2 foi buildada sem o OOBE.

### 🔴 BUG 2 — IA: modelo 11.67GB não cabe na RAM (causa raiz confirmada)

- Print do usuário + VM: `erro ao executar ravena-ia: Command failed`,
  depois `RAVENA: modelo ainda carregando ... (130s ate agora)` em loop.
- Painel IA do eDEX: `PROVEDOR: OFFLINE`.
- Causa: modelo `IQ2_M` de **11.67GB** com RAM visível de **7.7GB** (VM) →
  carrega via swap/mmap → nunca termina na VM; no PC real (16GB) carrega mas
  fica em swap → respostas de 2–5 min.
- "Antes respondia": o modelo estava salvo na partição RAVENA-DATA do pendrive
  RV9b; o modo DD do RV10v2 **apagou a partição** → modelo precisa re-baixar.
- `~/modelos/` na VM: contém arquivos .gguf (confirmado pelo usuário).

### 🔴 BUG 3 — Pastas scripts/ e tmp/ ausentes (regressão F2)

- Print do usuário: `cd "scripts"` → `Arquivo ou diretorio inexistente`.
- Repo `ravena-archiso/home-ravena/` **não contém** `scripts/` nem `tmp/` —
  a correção F2 (pastas com README) não foi sincronizada para o repo nem
  entrou na ISO v2.

### ✅ O que funcionou no real (confirmado pelo usuário)

- Campo de digitação da IA não rouba mais o foco (patch F4 do `_renderer.js`).
- Boot do pendrive, eDEX-UI abre, terminal funciona.

## Contramedidas no processo

- Antes de gravar de novo: checar os 2 pontos de forma **específica** para PC real
  (não VM): estado de serviços de rede no boot, log do provider IA.
- Só declarar "OK" após o FEEDBACK REAL do usuário.
