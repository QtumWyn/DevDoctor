const runButton = document.querySelector("#run-button");
const runStatus = document.querySelector("#run-status");

const totalCount = document.querySelector("#total-count");
const passedCount = document.querySelector("#passed-count");
const failedCount = document.querySelector("#failed-count");

const emptyState = document.querySelector("#empty-state");
const resultMessage = document.querySelector("#result-message");
const resultDetail = document.querySelector("#result-detail");
const checksList = document.querySelector("#checks-list");

function showMessage(message, detail) {
    resultMessage.textContent = message;
    resultDetail.textContent = detail;

    emptyState.hidden = false;
    checksList.hidden = true;
}

function resetSummary() {
    totalCount.textContent = "—";
    passedCount.textContent = "—";
    failedCount.textContent = "—";
}

function renderChecks(checks) {
    checksList.replaceChildren();

    if (checks.length === 0) {
        showMessage(
            "No checks configured.",
            "Add some checks to your DevDoctor configuration.",
        );

        return;
    }

    for (const check of checks) {
        const passed = check.status === "ok";

        const row = document.createElement("article");
        row.className = "check-row";
        row.classList.add(
            passed ? "check-passed" : "check-failed",
        );

        const information = document.createElement("div");
        information.className = "check-information";

        const heading = document.createElement("div");
        heading.className = "check-title";

        const category = document.createElement("span");
        category.className = "check-category";
        category.textContent = check.category;

        const name = document.createElement("strong");
        name.className = "check-name";
        name.textContent = check.name;

        const detail = document.createElement("p");
        detail.className = "check-detail";
        detail.textContent = check.detail;

        const status = document.createElement("span");
        status.className = "check-status";
        status.classList.add(passed ? "status-ok" : "status-fail");
        status.textContent = passed ? "OK" : "FAIL";

        heading.append(category, name);
        information.append(heading, detail);
        row.append(information, status);
        checksList.append(row);
    }

    emptyState.hidden = true;
    checksList.hidden = false;
}

runButton.addEventListener("click", async () => {
    runButton.disabled = true;
    runButton.textContent = "Running...";

    runStatus.textContent = "Running";
    resetSummary();

    showMessage(
        "DevDoctor is inspecting this machine...",
        "Running configured diagnostic checks.",
    );

    try {
        const result =
            await window.devdoctor.runDiagnostics();

        if (!result.ok) {
            runStatus.textContent = "Error";

            showMessage(
                "DevDoctor could not complete the scan.",
                result.message,
            );

            return;
        }

        const report = result.report;

        totalCount.textContent = report.summary.total;
        passedCount.textContent = report.summary.passed;
        failedCount.textContent = report.summary.failed;

        runStatus.textContent =
            report.summary.failed === 0
                ? "Healthy"
                : "Attention needed";

        renderChecks(report.checks);
    } catch (error) {
        runStatus.textContent = "Error";

        showMessage(
            "An unexpected error occurred.",
            error.message || "No additional details are available.",
        );
    } finally {
        runButton.disabled = false;
        runButton.textContent = "Run diagnostics";
    }
});