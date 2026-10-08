const cluster = require("cluster");

if (cluster.isMaster) {
    const electron = require("electron");
    const ipc = electron.ipcMain;
    const signale = require("signale");
    // Also, leave a core available for the renderer process
    const osCPUs = require("os").cpus().length - 1;
    // See #904
    const numCPUs = (osCPUs > 7) ? 7 : osCPUs;

    const si = require("systeminformation");

    // RAVENA: no Linux a systeminformation resolve chamando shells. Medido na
    // VM com o eDEX no ar: um unico networkInterfaces() nasce ~100 processos e
    // leva ~2,4s de parede, um processes() nasce ~84 e leva ~1,9s. Os widgets
    // chamam a cada 1-5s e a soma foi medida em ~126 forks/s, sy 65% e load 10
    // em 4 vCPU - o OS ficava lento a ponto de recusar autenticacao no sshd.
    // Limita a frequencia de cada tipo aqui, no ponto unico de dispatch, sem
    // tocar nos widgets: o chamador sempre recebe uma resposta, e os dados
    // consumidos por estes modulos (lista de processos, interface, temperatura)
    // toleram bem alguns segundos de idade.
    const MIN_INTERVAL = {
        processes: 5000,
        networkInterfaces: 30000,
        networkConnections: 10000,
        cpu: 3000,
        cpuTemperature: 5000
    };
    const recent = {};

    cluster.setupMaster({
        exec: require("path").join(__dirname, "_multithread.js")
    });

    let workers = [];
    cluster.on("fork", worker => {
        workers.push(worker.id);
    });

    for (let i = 0; i < numCPUs; i++) {
        cluster.fork();
    }

    signale.success("Multithreaded controller ready");

    var lastID = 0;

    function dispatch(type, id, arg) {
        let selectedID = lastID+1;
        if (selectedID > numCPUs-1) selectedID = 0;

        cluster.workers[workers[selectedID]].send(JSON.stringify({
            id,
            type,
            arg
        }));

        lastID = selectedID;
    }

    var queue = {};
    var queueResolve = {};

    function reply(e, id, res) {
        if (e.sender && !e.sender.isDestroyed()) {
            e.sender.send("systeminformation-reply-"+id, res);
        }
    }

    ipc.on("systeminformation-call", (e, type, id, ...args) => {
        if (!si[type]) {
            signale.warn("Illegal request for systeminformation");
            return;
        }

        const key = type + "|" + JSON.stringify(args);
        const minMs = MIN_INTERVAL[type] || 0;
        const cached = recent[key];

        // Dentro da janela: devolve a promessa ja em voo (ou o ultimo
        // resultado) em vez de nascer outro lote de processos.
        if (minMs && cached && (Date.now() - cached.at) < minMs) {
            cached.promise.then(res => reply(e, id, res)).catch(() => {});
            return;
        }

        if (args.length > 1 || workers.length <= 0) {
            const promise = si[type](...args);
            recent[key] = { at: Date.now(), promise };
            promise.then(res => reply(e, id, res)).catch(() => {});
        } else {
            let resolve = null;
            const promise = new Promise(r => { resolve = r; });
            recent[key] = { at: Date.now(), promise };
            queue[id] = e.sender;
            queueResolve[id] = resolve;
            dispatch(type, id, args[0]);
        }
    });

    cluster.on("message", (worker, msg) => {
        msg = JSON.parse(msg);
        const resolve = queueResolve[msg.id];
        if (resolve) {
            delete queueResolve[msg.id];
            resolve(msg.res);
        }
        try {
            const sender = queue[msg.id];
            delete queue[msg.id];
            if (sender && !sender.isDestroyed()) {
                sender.send("systeminformation-reply-"+msg.id, msg.res);
            }
        } catch(e) {
            // Window has been closed, ignore.
        }
    });
} else if (cluster.isWorker) {
    const signale = require("signale");
    const si = require("systeminformation");

    signale.info("Multithread worker started at "+process.pid);

    process.on("message", msg => {
        msg = JSON.parse(msg);
        si[msg.type](msg.arg).then(res => {
            process.send(JSON.stringify({
                id: msg.id,
                res
            }));
        });
    });
}
