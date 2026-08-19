#!/bin/bash
# patch_contextmenu.sh - Adiciona menu de contexto (botao direito) funcional no eDEX
set -e
F=/root/ravv2/rootfs/opt/edex-ui/src/_renderer.js
cp "$F" "$F.bak_ctxmenu"

python3 << 'PYEOF'
import re

path = "/root/ravv2/rootfs/opt/edex-ui/src/_renderer.js"
src = open(path, encoding="utf-8").read()

block = '''
    // (U5) Menu de contexto do botao direito - estilo Windows, fica aberto ate escolher
    // Ligado ao clipboard do xterm (mesmo comando dos atalhos COPY/PASTE)
    window.addEventListener("contextmenu", e => {
        e.preventDefault();
        const term = window.term && window.term[window.currentTerm];
        const hasSel = !!(term && term.term && term.term.hasSelection && term.term.hasSelection());
        const remote = require("@electron/remote");
        const template = [
            { label: "Copiar", enabled: hasSel, accelerator: "CmdOrCtrl+Shift+C",
              click: () => { if (term) term.clipboard.copy(); } },
            { type: "separator" },
            { label: "Colar", accelerator: "CmdOrCtrl+Shift+V",
              click: () => { if (term) term.clipboard.paste(); } },
            { type: "separator" },
            { label: "Selecionar tudo", enabled: !!term,
              click: () => { if (term && term.term && term.term.selectAll) term.term.selectAll(); } }
        ];
        remote.Menu.buildFromTemplate(template).popup({ window: remote.getCurrentWindow() });
    });
'''

anchor = "window.onmouseup = e => {"
assert anchor in src, "anchor onmouseup nao encontrado"
src = src.replace(anchor, block + "\n    " + anchor, 1)
open(path, "w", encoding="utf-8").write(src)
print("PATCH OK")
PYEOF

node -c "$F" && echo "SINTAXE-OK"