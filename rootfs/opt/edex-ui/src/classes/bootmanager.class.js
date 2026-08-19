class BootManager {
    constructor() {
        const path = require("path");
        const fs = require("fs");
        const { exec } = require("child_process");
        const remote = require("@electron/remote");

        this.fs = fs;
        this.path = path;
        this.exec = exec;
        this.stateFile = path.join(remote.app.getPath("userData"), "bootmanager.json");

        let state = {};
        try {
            state = JSON.parse(fs.readFileSync(this.stateFile, "utf8"));
        } catch (e) {}

        // x,y = posicao do FAB em % da viewport. Default: esquerda, acima da bolha NET
        this.state = Object.assign({ x: 1, y: 12, open: false }, state);

        this._drag = null;
        this._moved = false;
        this._buildDom();
        this._applyPos();
        this._renderOptions();
        if (this.state.open) this._openPanel();
        this._refreshBootInfo();
    }

    _buildDom() {
        const fab = document.createElement("div");
        fab.id = "boot_fab";
        fab.innerHTML = "<span>BOOT</span>";

        const wrap = document.createElement("div");
        wrap.id = "boot_floating";
        wrap.className = "dragging";
        wrap.appendChild(fab);
        document.body.appendChild(wrap);

        const panel = document.createElement("div");
        panel.id = "boot_panel";
        panel.style.display = "none";
        panel.innerHTML = `
            <div class="boot_panel_header">
                <span>RAVENA&nbsp;BOOT</span>
                <span class="boot_status" id="boot_status">...</span>
                <button id="boot_close">&times;</button>
            </div>
            <div id="boot_current">menu de boot (GRUB/F12) dentro do OS.<br>Escolha a opcao e o PC reinicia direto nela.</div>
            <div class="boot_list_header">
                <span>OPCOES DE BOOT</span>
                <button id="boot_refresh">ATUALIZAR</button>
            </div>
            <div id="boot_list"></div>
            <div id="boot_confirm" style="display:none"></div>
            <div id="boot_log"></div>
        `;
        document.body.appendChild(panel);

        this.fab = fab;
        this.wrap = wrap;
        this.panel = panel;
        this.current = document.getElementById("boot_current");
        this.status = document.getElementById("boot_status");
        this.list = document.getElementById("boot_list");
        this.logEl = document.getElementById("boot_log");
        this.confirmEl = document.getElementById("boot_confirm");
        this.closeBtn = document.getElementById("boot_close");
        this.refreshBtn = document.getElementById("boot_refresh");

        this.closeBtn.addEventListener("click", (e) => {
            e.stopPropagation();
            this._closePanel();
        });
        this.refreshBtn.addEventListener("click", () => this._refreshBootInfo());

        fab.addEventListener("click", (e) => {
            e.stopPropagation();
            if (this._moved) return;
            if (this.state.open) this._closePanel();
            else this._openPanel();
        });

        // Drag: pointer events cobrem mouse + touch
        fab.addEventListener("pointerdown", (e) => {
            this._moved = false;
            this._drag = {
                startX: e.clientX,
                startY: e.clientY,
                origX: this.state.x,
                origY: this.state.y
            };
            fab.setPointerCapture(e.pointerId);
        });

        fab.addEventListener("pointermove", (e) => {
            if (!this._drag) return;
            const dx = e.clientX - this._drag.startX;
            const dy = e.clientY - this._drag.startY;
            if (Math.abs(dx) > 4 || Math.abs(dy) > 4) this._moved = true;
            this.state.x = this._clampX(this._drag.origX + (dx / window.innerWidth) * 100);
            this.state.y = this._clampY(this._drag.origY + (dy / window.innerHeight) * 100);
            this._applyPos();
            if (this.state.open) this._positionPanel();
        });

        const endDrag = (e) => {
            if (!this._drag) return;
            this._drag = null;
            this._save();
        };
        fab.addEventListener("pointerup", endDrag);
        fab.addEventListener("pointercancel", endDrag);

        window.addEventListener("resize", () => this._positionPanel());
    }

    _clampX(v) { return Math.min(92, Math.max(1, v)); }
    _clampY(v) { return Math.min(88, Math.max(1, v)); }

    _applyPos() {
        this.wrap.style.left = this.state.x + "vw";
        this.wrap.style.top = this.state.y + "vh";
    }

    _positionPanel() {
        const r = this.wrap.getBoundingClientRect();
        let top = r.top - this.panel.offsetHeight - 1;
        if (top < 0) top = r.bottom + 1;
        this.panel.style.left = Math.min(r.left, window.innerWidth - this.panel.offsetWidth - 8) + "px";
        this.panel.style.top = top + "px";
    }

    _openPanel() {
        this.state.open = true;
        this.panel.style.display = "flex";
        this._positionPanel();
        this._renderOptions();
        this._refreshBootInfo();
    }

    _closePanel() {
        this.state.open = false;
        this.panel.style.display = "none";
        this._save();
    }

    _log(msg, cls) {
        const d = document.createElement("div");
        if (cls) d.className = cls;
        d.textContent = msg;
        this.logEl.appendChild(d);
        this.logEl.scrollTop = this.logEl.scrollHeight;
    }

    _exec(cmd, cb) {
        this.exec(cmd, { timeout: 60000, maxBuffer: 4 * 1024 * 1024 }, (err, out, errout) => {
            cb && cb(err, (out || "").trim(), (errout || "").trim());
        });
    }

    _refreshBootInfo() {
        // proxima entrada one-shot agendada? + BootCurrent
        this._exec("cat /mnt/ravboot/ravena.nextboot 2>/dev/null; sudo -n efibootmgr 2>/dev/null", (err, out) => {
            try {
                const cur = (out || "").split("\n").filter(l => l.indexOf("BootCurrent") >= 0).map(l => l.split(":")[1].trim()).join("");
                const hasNext = (out || "").indexOf("set default") >= 0;
                this.status.textContent = (hasNext ? "NEXTBOOT AGENDADO | " : "") + (cur ? "BootCurrent: " + cur : "UEFI");
                this.status.className = "boot_status " + (hasNext ? "on" : "");
            } catch (e) {
                console.warn("BootManager refresh:", e);
            }
        });
    }

    _renderOptions() {
        const opts = [
            { id: "ravena", label: "RAVENA OS", desc: "boot normal do sistema", color: "#37ff8b" },
            { id: "archlinux-accessibility", label: "RAVENA OS - Modo Seguro", desc: "sem acessibilidade (leitor de tela off)", color: "#37ff8b" },
            { id: "shell", label: "UEFI Shell", desc: "shell do firmware (diag/manutencao, sem OS)", color: "#ffcc66" },
            { id: "firmware", label: "Firmware Settings", desc: "entra direto na BIOS/UEFI Setup", color: "#ffcc66" },
            { id: "shutdown", label: "System shutdown", desc: "desliga o PC", color: "#ff5b5b" },
            { id: "restart", label: "System restart", desc: "reinicia o PC", color: "#ff5b5b" }
        ];
        this.list.innerHTML = "";
        opts.forEach(o => {
            const row = document.createElement("div");
            row.className = "boot_row";
            row.style.borderLeftColor = o.color;
            row.innerHTML = "<div class=\"boot_row_label\">" + this._esc(o.label) + "</div>" +
                "<div class=\"boot_row_desc\">" + this._esc(o.desc) + "</div>";
            row.addEventListener("click", () => this._pickOption(o));
            this.list.appendChild(row);
        });
    }

    _pickOption(o) {
        this.confirmEl.style.display = "block";
        this.confirmEl.innerHTML = "<div class=\"boot_confirm_msg\">Reiniciar para <b>" + this._esc(o.label) + "</b>?</div>" +
            "<div class=\"boot_confirm_btns\"><button id=\"boot_yes\">SIM, REINICIAR</button><button id=\"boot_no\">CANCELAR</button></div>";
        const yes = document.getElementById("boot_yes");
        const no = document.getElementById("boot_no");
        yes.addEventListener("click", () => this._execute(o));
        no.addEventListener("click", () => {
            this.confirmEl.style.display = "none";
            this.confirmEl.innerHTML = "";
        });
    }

    _execute(o) {
        this.confirmEl.innerHTML = "<div class=\"boot_confirm_msg\">Executando...</div>";
        this._log("Executando: " + o.label + "...");
        this._exec("sudo -n /usr/local/bin/ravena-boot-menu.sh --exec " + o.id, (err, out, erout) => {
            if (err) {
                this._log("falha: " + (erout || out || err.message), "err");
                this.confirmEl.innerHTML = "<div class=\"boot_confirm_msg boot_err\">Falha ao executar: " + this._esc(erout || err.message) + "</div>" +
                    "<div class=\"boot_confirm_btns\"><button id=\"boot_no2\">OK</button></div>";
                document.getElementById("boot_no2").addEventListener("click", () => {
                    this.confirmEl.style.display = "none";
                    this.confirmEl.innerHTML = "";
                });
            } else {
                this._log("sucesso! reiniciando...", "ok");
            }
        });
    }

    _esc(s) {
        return String(s || "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    _save() {
        try {
            this.fs.writeFileSync(this.stateFile, JSON.stringify(this.state, "", 2));
        } catch (e) {
            console.warn("BootManager save:", e);
        }
    }
}

module.exports = BootManager;