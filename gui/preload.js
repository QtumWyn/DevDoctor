const {
    contextBridge,
    ipcRenderer,
} = require("electron/renderer");

contextBridge.exposeInMainWorld("devdoctor", {
    runDiagnostics: () =>
        ipcRenderer.invoke("devdoctor:run"),
});