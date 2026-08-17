const { app, BrowserWindow, ipcMain } = require("electron/main");
const { execFile } = require("node:child_process");
const { promisify } = require("node:util");
const path = require("node:path");

const execFileAsync = promisify(execFile);

const projectRoot = path.resolve(__dirname, "..");

async function runDiagnostics() {
    const executableName =
        process.platform === "win32"
            ? "devdoctor.exe"
            : "devdoctor";

    const executablePath = path.join(
        projectRoot,
        "zig-out",
        "bin",
        executableName,
    );

    try {
        const { stdout } = await execFileAsync(
            executablePath,
            [
                "--json",
                "--config",
                "devdoctor.json",
            ],
            {
                cwd: projectRoot,
                encoding: "utf8",
                windowsHide: true,
            },
        );

        return {
            ok: true,
            report: JSON.parse(stdout),
        };
    } catch (error) {
        return {
            ok: false,
            message:
                error.stderr?.trim() ||
                error.message ||
                "DevDoctor could not be started.",
        };
    }
}

function createWindow() {
    const mainWindow = new BrowserWindow({
        width: 960,
        height: 700,
        minWidth: 720,
        minHeight: 520,
        title: "DevDoctor",
        backgroundColor: "#0b1020",
        webPreferences: {
            preload: path.join(__dirname, "preload.js"),
            contextIsolation: true,
            nodeIntegration: false,
            sandbox: true,
        },
    });

    mainWindow.loadFile(path.join(__dirname, "index.html"));
}

app.whenReady().then(() => {
    ipcMain.handle("devdoctor:run", runDiagnostics);

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