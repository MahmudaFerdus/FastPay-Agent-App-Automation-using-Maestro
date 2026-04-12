Markdown

# 🚀 FastPay Agent - Maestro Automation Framework

A scalable, modular, and data-driven mobile UI automation framework for the **FastPay Agent** Android application. Built using [Maestro](https://maestro.mobile.dev/), this framework supports both positive (Happy Path) and negative test cases, comprehensive test suites (Smoke & Regression), and generates beautiful, detailed HTML reports.

---

## 🏗️ Project Architecture

This project follows a professional, enterprise-grade directory structure to maximize reusability and maintainability:

```text
AgentApp Maestro Automation/
│
├── .env                 # Centralized test data and credentials (No hardcoded secrets)
│
├── e2e/                 # Actual test cases separated by feature
│   ├── sellbalance/     # Contains positive and negative Sell Balance tests
│   └── transfermoney/   # Contains positive and negative Transfer Money tests
│
├── flows/               # Reusable helper flows (Called by E2E tests)
│   ├── login_helper.yaml
│   ├── logout_helper.yaml
│   └── teardown_helper.yaml  # Ensures app state is cleared between tests
│
├── suites/              # Test execution groupings
│   ├── smoke.yaml       # Critical path tests only
│   └── regression.yaml  # Full suite including negative validations
│
├── scripts/             # PowerShell execution & reporting engines
│   ├── run_smoke.ps1
│   └── run_regression.ps1
│
└── reports/             # Auto-generated HTML reports and execution logs
📋 Prerequisites
Before running the tests, ensure you have the following installed and configured on your Windows machine:

Maestro CLI installed.
Android Emulator running OR a physical Android device connected via USB.
Android SDK / ADB installed and added to your system path.
The FastPay Agent app (com.fastpay.agent) installed on the target device.
⚙️ Setup & Execution Guide
Step 1: Unzip and Open
Unzip the downloaded AgentApp Maestro Automation.zip folder.
Open the extracted folder in your preferred IDE (e.g., Visual Studio Code).
Step 2: Configure Test Data
Open the .env file in the root directory and ensure your credentials and test numbers are correct.
(Note: Do not add quotes or comments on the same line as the variables).

env

User=YOUR_USER
Password=YOUR_PASSWORD
Customer=YOUR_CUSTOMER
Agent=YOUR_AGENT
Step 3: Run your Tests!
Open a PowerShell terminal, navigate into the extracted folder, and move into the scripts directory:

PowerShell

cd "path\to\AgentApp Maestro Automation\scripts"
(Optional: If your system blocks scripts, run this command once: Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass)

Whenever you want to run the quick smoke test (just the 2 main positive tests), you type:

PowerShell

.\run_smoke.ps1
Whenever you want to run the full regression (all 4 tests, including negative scenarios), you type:

PowerShell

.\run_regression.ps1
📊 Reporting
This framework includes a custom reporting engine. Once test execution is complete, a visually appealing HTML Report is automatically generated and saved in the reports/ folder.

The script will automatically open the report in your default web browser, displaying:

Overall Execution Status (Passed / Failed / Skipped)
Total Execution Duration
Test Case Categorization (Positive / Negative Badges)
Live Maestro Console Logs (Embedded directly into the UI for easy debugging)
