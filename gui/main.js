const { app, BrowserWindow } = require("electron/main");
const path = require("node:path");

function createWindow() {
    const mainWindow = new BrowserWindow({
        width: 960,
        height: 700,
        minWidth: 720,
        minHeight: 520,
        title: "DevDoctor",
        backgroundColor: "#0b1020",
        webPreferences: {
            contextIsolation: true,
            nodeIntegration: false,
            sandbox: true,
        },
    });

    mainWindow.loadFile(path.join(__dirname, "index.html"));
}

app.whenReady().then(() => {
    createWindow();

    app.on("activate", () => {
        if (BrowserWindow.getAllWindows().length === 0) {
            createWindow();
        }
    });
});

app.on("window-all-closed", () => {
    if (process.platform !== "darwin") {
        app.quit();
    }
});