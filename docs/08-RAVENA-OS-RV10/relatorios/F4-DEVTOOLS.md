# F4 — Ambiente de Desenvolvimento

**Status:** ✅ Confirmado na VM (10/10 ferramentas)
**Data:** 2026-08-12

## Objetivo

Estação de trabalho de desenvolvimento completa em terminal: linguagens,
editores, buscas e ferramentas de produtividade.

## Ferramentas validadas

| Ferramenta | Versão | Presente na VM |
|---|---|---|
| npm | 12 | ✅ |
| go | 1.26 | ✅ |
| rust/cargo | 1.97 | ✅ |
| neovim (nvim) | 0.12 | ✅ |
| ripgrep (rg) | — | ✅ |
| fzf | — | ✅ |
| btop | — | ✅ |
| git | 2.55 | ✅ |
| python3 | — | ✅ |
| gcc/g++, make, cmake | — | ✅ |

## Workspace

- `~/projects/` com git 2.55 (repo unificado)
- Configuração git global para o usuário `ravena`

## Validação (VM)

```bash
for c in npm go cargo rustc rg fzf btop nvim git python3; do
    command -v $c >/dev/null 2>&1 && echo "$c-OK"
done
# Resultado: npm-OK go-OK cargo-OK rustc-OK rg-OK fzf-OK btop-OK nvim-OK git-OK python3-OK
```
