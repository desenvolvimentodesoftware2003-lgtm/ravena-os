# MAPEAMENTO COMPLETO — O QUE UM SISTEMA OPERACIONAL DEVE TER

> Objetivo: checklist definitivo de mercado para o Ravena OS, validado pela
> visão humana (usuário), não por testes de VM. Cada item: status no Ravena +
> como testar no PC real + quem valida.
> Criado: 2026-08-15 (após teste real reprovar rede e IA).

---

## LEGENDA

- ✅ FUNCIONA (validado no PC real pelo usuário)
- 🔶 FUNCIONA EM VM, NÃO CONFIRMADO NO PC REAL (validar)
- 🔴 NÃO FUNCIONA / REGRESSÃO (falha real relatada)
- ⬜ FALTA / NÃO IMPLEMENTADO
- ❓ DESCONHECIDO (nunca testado)

---

## 1. BOOT E INICIALIZAÇÃO

| Item | O que um OS deve ter | Ravena | Como testar no PC real |
|---|---|---|---|
| 1.1 | Boot pelo pendrive/USB (BIOS F12) | ✅ (bootou no teste real) | F12 → SanDisk |
| 1.2 | Boot do kernel + initramfs sem PANIC | ✅ | observado no teste |
| 1.3 | Carregar o sistema em tempo razoável (< 2 min) | ❓ | cronometrar |
| 1.4 | Sessão de login/autologin funcional | 🔶 (VM OK) | observar login automático |
| 1.5 | tela gráfica (Xorg + eDEX-UI) sobe | 🔶 (VM OK) | observar eDEX-UI abrir |
| 1.6 | Acesso ao shell/terminal sempre disponível | ✅ | tecla terminal no eDEX |

## 2. REDE (PRIORIDADE 1 — REPROVOU NO REAL)

| Item | O que um OS deve ter | Ravena | Como testar no PC real |
|---|---|---|---|
| 2.1 | Detectar hardware de rede (WiFi + Ethernet) | ❓ | `ip link` / `lspci` |
| 2.2 | **Conectar WiFi automaticamente (perfil salvo)** | 🔴 REPROVOU | conectar WiFi no OOBE, reiniciar, ver se reconecta |
| 2.3 | **DHCP automático (IP da rede)** | 🔴 REPROVOU | `ip addr` mostra IP? |
| 2.4 | DNS resolvendo (ping + navegação) | 🔴 REPROVOU | `ping google.com` |
| 2.5 | Rede cabeada (DHCP no cabo) | ❓ | plugar cabo, `ip a` |
| 2.6 | Serviço de rede ativo no boot (`ravena-net`) | ❓ | `systemctl status ravena-net` |
| 2.7 | Reconectar após reinício (perfil persistido) | 🔴 parece ciclo | reiniciar com WiFi salvo |
| 2.8 | Interface de configuração de rede simples | ❓ | alias `net`/`wifi` no boot |
| 2.9 | Kill-switch / VPN opcional (route-switch) | ⬜ configurar depois | — |

## 3. PROVEDOR DE IA (PRIORIDADE 2 — REGRESSÃO NO REAL)

| Item | O que um OS deve ter | Ravena | Como testar no PC real |
|---|---|---|---|
| 3.1 | Provider de IA inicia no boot (llama-server) | 🔴 REGRESSÃO | `systemctl status ravena-llm` / `ps aux \| grep llama` |
| 3.2 | Modelo de IA carregado (GGUF) | ❓ | web UI porta 8080 / log |
| 3.3 | Chat funciona no terminal (`llm`) | ❓ | digitar `llm` e perguntar algo |
| 3.4 | Barra IA do eDEX-UI responde | 🔶 (só digitação OK) | digitar na barra IA, ver resposta |
| 3.5 | Resposta em tempo aceitável | ❓ | cronometrar resposta |
| 3.6 | Não travar/consumir toda a RAM | ❓ | `free -h` durante resposta |

## 4. ARMAZENAMENTO E PERSISTÊNCIA

| Item | O que um OS deve ter | Ravena | Como testar no PC real |
|---|---|---|---|
| 4.1 | Detectar disco do sistema | ✅ (bootou) | — |
| 4.2 | Criar LUKS + RAVENA-DATA no 1º boot | 🔶 (VM OK) | ver mensagem da chave de recuperação |
| 4.3 | Imprimir chave de recuperação | 🔶 (VM OK) | guardar a chave impressa |
| 4.4 | Montar partição de dados automaticamente | 🔶 (VM OK) | `df -h` |
| 4.5 | Persistir dados entre boots (não ser "ciclo") | 🔶 (VM OK, real?) | criar arquivo, reiniciar, ver se existe |
| 4.6 | Dotfiles/configs persistidos | 🔶 (VM OK) | ver `.bashrc` etc. após reboot |

## 5. INTERFACE E USABILIDADE (visão humana)

| Item | O que um OS deve ter | Ravena | Como testar no PC real |
|---|---|---|---|
| 5.1 | Teclado ABNT2 correto (ç, ~, acentos) | 🔶 (VM OK) | digitar ç, ~, é |
| 5.2 | Campo de digitação IA não rouba foco | ✅ CONFIRMADO NO REAL | usuário: "espaço da digitação não muda mais" |
| 5.3 | eDEX-UI estável (sem PANIC/crash) | 🔶 (VM OK) | usar alguns minutos |
| 5.4 | Fontes legíveis no monitor real | ❓ | observar |
| 5.5 | Terminal/teclas funcionais | ❓ | navegar no eDEX |
| 5.6 | Relógio/hora correta (chrony) | ❓ | `horas`, comparar com relógio |

## 6. FERRAMENTAS E APLICATIVOS

| Item | O que um OS deve ter | Ravena | Como testar no PC real |
|---|---|---|---|
| 6.1 | Navegador (w3m/links) | 🔶 (VM OK) | `navega` abrir site |
| 6.2 | Editor (nvim) | 🔶 (VM OK) | `nvim` abrir arquivo |
| 6.3 | File manager (ranger) | 🔶 (VM OK) | `arquivos` |
| 6.4 | Vídeo (mpv) + download (yt-dlp) | 🔶 (VM OK) | tocar vídeo |
| 6.5 | Monitor do sistema (btop/horas) | 🔶 (VM OK) | `btop` |
| 6.6 | Dev tools (npm, go, rust, git) | 🔶 (VM OK) | `git --version` |
| 6.7 | Painel de hardware (ravena-hardware) | ❓ | `ravena-hardware` |

## 7. SEGURANÇA

| Item | O que um OS deve ter | Ravena | Como testar no PC real |
|---|---|---|---|
| 7.1 | Login com senha (ravena/root) | 🔶 (VM OK) | login |
| 7.2 | Criptografia em repouso (LUKS) | 🔶 (VM OK) | 1º boot mostra criação |
| 7.3 | Chave de recuperação | 🔶 (VM OK) | imprimir e guardar |
| 7.4 | Firewall básico | 🔶 (VM OK) | `nft list ruleset` |
| 7.5 | Sem vulnerabilidade óbvia (root exposto?) | ❓ | revisão humana |

## 8. QUALIDADE DE VIDA

| Item | O que um OS deve ter | Ravena | Como testar no PC real |
|---|---|---|---|
| 8.1 | Inicialização sem "ciclo" (sem reboot loop) | 🔴 SUSPEITO ("parece ciclo") | reboot 2x, ver estabilidade |
| 8.2 | Mensagens de erro claras (não silencioso) | ❓ | observar |
| 8.3 | Logs acessíveis (`journalctl`) | 🔶 (VM OK) | `journalctl -b -p err` |
| 8.4 | Apagar limpo (não danifica hardware) | ❓ | — |

---

## RESUMO EXECUTIVO

| Área | Status |
|---|---|
| Boot | 🟡 OK no real, detalhes a confirmar |
| **Rede** | 🔴 REPROVOU — prioridade máxima |
| **IA provider** | 🔴 REGRESSÃO — prioridade 2 |
| Persistência | 🟡 OK em VM, confirmar no real |
| Interface | 🟢 1 item confirmado (digitação); resto em VM |
| Ferramentas | 🟡 OK em VM, confirmar no real |
| Segurança | 🟡 OK em VM, confirmar no real |
| Qualidade de vida | 🟡 "ciclo" suspeito — investigar |

## REGRA NOVA (a partir de agora)

**Nenhum item é "✅" sem teste REAL do usuário no PC.** VM é só para lógica de
boot/persistência. Rede e IA só serão declaradas OK após feedback humano.
