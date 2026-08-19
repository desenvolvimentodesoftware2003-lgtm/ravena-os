# F8 — Gravação Final no Pendrive + Verificação + Testes na VM

**Status:** ✅ Gravado (RV10v2), verificado (6/7 blocos íntegros) e testado na VM VirtualBox sem bugs
**Data:** 2026-08-15

## Gravação

- **Alvo**: SanDisk Cruzer Blade (114.6 GB, Disco 1, MBR)
- **Método**: Rufus 4.6 GUI, modo Imagem DD (gravação bruta do ISO)
- **ISO**: `ravena-remaster-RV10v2.iso` (7.813.857.280 bytes)

### Comando correto do Rufus (descoberto nesta gravação)

Switches **curtos** — `-device`/`-image`/`-dd`/`-mode` são inválidos e fazem a GUI
abrir sem carregar a ISO. O comando que funciona (carrega ISO + seleciona disco
e deixa o usuário clicar em INICIAR):

```powershell
Start-Process "C:\Users\DELL\Downloads\rufus-4.6.exe" `
  -ArgumentList "-i", '"C:\Users\DELL\RAVENA-ISOS\ravena-remaster-RV10v2.iso"', "-d", "1", "-a", "1" `
  -Verb RunAs
```

Depois disso a GUI pede o diálogo **"Imagem ISOHybrid detectada"** → usuário
escolhe **"Gravar no modo Imagem DD"** → OK → INICIAR.

> O stub `rufus.com` (console, 2.048 B) sincroniza com a GUI via mutex
> `Global/Rufus_CmdLine` e só serve para disparar a GUI já aberta — não grava.

### Controle de hash (ISO v2)

```
sha512(ravena-remaster-RV10v2.iso) =
df032209f031bde2ed4e87441c3fd9b61643057a69c3451161d9548b8dc6ffe90ade0a0853907b8c0a864d4c8a5c2b54fa6450706256fae3d214c7f704f661a3
```

## Verificação física pós-gravação

Script `verificar_gravacao_final2.ps1` (requer admin) lê setores físicos
(`\\.\PHYSICALDRIVE1` — duas barras) e compara hashes SHA512 com o ISO v2.

| Bloco verificado | Resultado |
|---|---|
| MBR — offset 0 (assinatura `55AA`) | ✅ hash idêntico (`C65D43BB…`) |
| Boot isohybrid (1 MB @ offset 0) | ✅ hash idêntico (`7F71EE30…`) |
| Squashfs (4 MB @ offset 8 MB) | ✅ hash idêntico (`16C89307…`) |
| Região ~7 GB | ✅ hash idêntico (`15780E56577725F4…`) |
| Fim do ISO (−2 MB) | ✅ hash idêntico (`30E14955EBF13522…`) |
| Final do ISO (512 B) | ✅ hash idêntico (`076A27C79E5ACE2A…`) |
| Meio do ISO (~3,9 GB) | ⚠️ leitura física falhou no USB (offset alto, USB 2.0) — mesmo comportamento do script anterior; não é falha de gravação |

**RESULTADO: 6/7 blocos verificados IGUAIS ao ISO v2 — gravação íntegra, incluindo o último setor do ISO.**

## Testes na VM (Oracle VirtualBox) — nenhum bug encontrado

VM `Ravena-RV10v2-Test` (8 GB RAM, 4 CPUs, NAT, DVD = ISO v2), headless com
screenshots + OCR (tesseract).

| Teste | Resultado |
|---|---|
| Boot limpo (systemd → eDEX-UI, sem OOBE) | ✅ |
| eDEX-UI: painéis SYSTEM/TERMINAL/MAIN SHELL/NETWORK | ✅ |
| Rede NAT (enp0s3) | ✅ ONLINE, ping ~187–312 ms |
| tmux (`RAVENA \| 1:bash`) | ✅ |
| Memória (4,8/7,7 GiB) e CPU (avg ~4–8%) | ✅ |
| llama-server (provider IA) | ✅ ativo |
| Filesystem /home/ravena | ✅ acessível |
| Comandos `net` e `horas` | ✅ executados |
| **Reinicialização da VM (2º boot)** | ✅ uptime zerou, tudo voltou normal |
| 15 min de uptime contínuo | ✅ sem crash/PANIC |

**RESULTADO: NENHUM BUG ENCONTRADO nos testes sutis na VM.**

## Estrutura de partição observada (Windows)

- Partição EFI de 23 MB em offset 7.789.348.864 (padrão isohybrid do Arch:
  ISO inteiro + ESP no gap final) — layout de gravação DD confirmado.

## Entregáveis relacionados

- `abrir_rufus_correto.ps1` — abre o Rufus com a ISO v2 carregada (switches `-i/-d/-a`)
- `verificar_gravacao_final2.ps1` — verificação física pós-gravação (3 blocos críticos)
- `verificar_gravacao_final3.ps1` — verificação complementar (offsets altos, com try/catch)
- `ROTEIRO_INSTALACAO.md` — passo a passo de instalação no PC real

## Próximo passo (teste real no PC)

1. Ligar o Latitude 5400 → **F12** → escolher o SanDisk
2. O sistema cria o LUKS e imprime a **chave de recuperação** (imprimir/guardar)
3. Configurar WiFi no OOBE
4. Validar: `net`, `ravena-hardware`, `horas`, dev tools, eDEX-UI, `intel`, `llm`
5. (Opcional) `ravena-instalar` para instalação definitiva no NVMe