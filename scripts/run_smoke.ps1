Add-Type -AssemblyName System.Web

# ─── DYNAMIC PATH SETUP ───
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Parent $scriptPath
$rootDir = Split-Path -Parent $scriptDir

$reportDir = "$rootDir\reports"
if (!(Test-Path $reportDir)) { New-Item -ItemType Directory -Path $reportDir -Force | Out-Null }

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  FastPay Agent - Smoke Test Execution  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ─── PREPARE PATHS & VARIABLES ───
# Notice we are pointing to smoke.yaml now!
$suitePath = "$rootDir\suites\smoke.yaml"
$envPath = "$rootDir\.env"

$envArgs = ""
if (Test-Path $envPath) {
    $envLines = Get-Content $envPath
    foreach ($line in $envLines) {
        if ($line -match "=" -and $line -notmatch "^#") {
            $envArgs += "-e " + $line.Trim() + " "
        }
    }
} else {
    Write-Host "ERROR: .env file not found at $envPath" -ForegroundColor Red
    exit
}

# ─── CREATE TEMPORARY BATCH FILE ───
$tempBatFile = "$reportDir\run_smoke_maestro.bat"
$batCommand = "@echo off`nmaestro test $envArgs `"$suitePath`""
Set-Content -Path $tempBatFile -Value $batCommand

# ─── RUN BATCH FILE & CAPTURE LIVE OUTPUT ───
$startTime = Get-Date
Write-Host "Starting Maestro Smoke Tests..." -ForegroundColor Yellow
Write-Host "Executing: maestro test $envArgs `"$suitePath`"" -ForegroundColor DarkGray
Write-Host "----------------------------------------"

$output = ""

# Run the batch file natively and capture output line by line
& cmd.exe /c "`"$tempBatFile`"" | ForEach-Object {
    Write-Host $_  # Print live to the screen
    $output += $_ + "`n" # Save to variable for the HTML report
}

$endTime = Get-Date
$totalDuration = [math]::Round(($endTime - $startTime).TotalSeconds, 2)

# Cleanup the temp batch file
Remove-Item -Path $tempBatFile -ErrorAction SilentlyContinue

# ─── PARSE RESULTS FOR HTML REPORT ───
# We only list the 2 tests that are in your smoke.yaml
$flows = @(
    @{ Name = "Sell Balance (Success)";    File = "sell_balance_success.yaml";       Type="Positive" },
    @{ Name = "Transfer Money (Success)";  File = "transfer_success.yaml";           Type="Positive" }
)

$results = @()

foreach ($flow in $flows) {
    $escapedFile = [regex]::Escape($flow.File)
    
    if ($output -match "(?i)$escapedFile") {
        if ($output -match "(?i)$escapedFile.*(failed|AssertionError|❌|✗)") {
            $results += @{ Name=$flow.Name; File=$flow.File; Status="FAILED"; Type=$flow.Type }
        } else {
            $results += @{ Name=$flow.Name; File=$flow.File; Status="PASSED"; Type=$flow.Type }
        }
    } else {
        $results += @{ Name=$flow.Name; File=$flow.File; Status="NOT RUN"; Type=$flow.Type }
    }
}

# ─── CONSOLE SUMMARY ───
Write-Host "----------------------------------------"
Write-Host "========================================" -ForegroundColor Yellow
Write-Host "         SMOKE TEST SUMMARY             " -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Yellow

foreach ($r in $results) {
    switch ($r.Status) {
        "PASSED"  { Write-Host "  PASS : $($r.Name)" -ForegroundColor Green }
        "FAILED"  { Write-Host "  FAIL : $($r.Name)" -ForegroundColor Red }
        default   { Write-Host "  SKIP : $($r.Name)" -ForegroundColor DarkYellow }
    }
}

$passedCount = ($results | Where-Object { $_.Status -eq "PASSED" }).Count
$failedCount = ($results | Where-Object { $_.Status -eq "FAILED" }).Count
$skippedCount = ($results | Where-Object { $_.Status -eq "NOT RUN" }).Count

Write-Host "`n  Total: $($results.Count) | Passed: $passedCount | Failed: $failedCount | Skipped: $skippedCount"
Write-Host "  Duration: ${totalDuration}s"
Write-Host "========================================" -ForegroundColor Yellow

# ─── GENERATE MODERN HTML REPORT ───
$escapedOutput = [System.Web.HttpUtility]::HtmlEncode($output)
$testRowsHtml = ""; $index = 1

foreach ($r in $results) {
    $statusColor = switch ($r.Status) { "PASSED"{"#4CAF50"}; "FAILED"{"#f44336"}; default{"#FF9800"} }
    $statusIcon = switch ($r.Status) { "PASSED"{"&#9989;"}; "FAILED"{"&#10060;"}; default{"&#9888;"}}
    $typeTag = "<span style='background:#eee;padding:4px 8px;border-radius:4px;font-size:11px;color:#555;font-weight:bold;'>$($r.Type)</span>"
    
    $testRowsHtml += @"
    <tr>
        <td style='text-align:center'>$index</td>
        <td>$typeTag &nbsp; $($r.Name)</td>
        <td><code>$($r.File)</code></td>
        <td style='color:$statusColor;font-weight:bold;text-align:center;font-size:18px;'>$statusIcon</td>
    </tr>
"@
    $index++
}

$bannerColor = if ($failedCount -gt 0) {"#ffebee;color:#c62828"} elseif ($skippedCount -gt 0) {"#fff3e0;color:#f57c00"} else {"#e8f5e9;color:#2e7d32"}
$bannerText = if ($failedCount -gt 0) {"&#10060; SMOKE TEST FAILED"} elseif ($skippedCount -gt 0) {"&#9888; SMOKE TEST INCOMPLETE"} else {"&#9989; SMOKE TEST PASSED"}

$html = @"
<!DOCTYPE html><html><head><title>FastPay Smoke Test Report</title>
<style>
body{font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;background:#f5f7fa;padding:20px;color:#333}
.container{max-width:1200px;margin:0 auto}
.card{background:white;border-radius:12px;padding:20px;margin-bottom:20px;box-shadow:0 4px 6px rgba(0,0,0,.04)}
.banner{padding:30px;text-align:center;border-radius:12px;background:$bannerColor;font-size:24px;font-weight:800;margin-bottom:20px;letter-spacing:1px}
.header{text-align:center;margin-bottom:30px}
.header h1{margin:0;color:#1a202c;font-size:32px}.header p{color:#718096;margin-top:8px}
.stats{display:flex;gap:20px;margin-bottom:20px}
.stat{flex:1;background:white;padding:30px 20px;border-radius:12px;text-align:center;box-shadow:0 4px 6px rgba(0,0,0,.04)}
.stat h2{font-size:42px;margin:0;font-weight:800}.stat p{margin:8px 0 0;color:#718096;font-size:14px;text-transform:uppercase;letter-spacing:1px;font-weight:bold}
table{width:100%;border-collapse:collapse;background:white;border-radius:12px;overflow:hidden;box-shadow:0 4px 6px rgba(0,0,0,.04)}
th{text-align:left;padding:18px 15px;background:#2b6cb0;color:white;font-weight:600;text-transform:uppercase;font-size:13px;letter-spacing:1px}
td{padding:16px 15px;border-bottom:1px solid #edf2f7;vertical-align:middle}
tr:last-child td{border-bottom:none}
tr:hover{background-color:#f8fafc}
code{background:#edf2f7;padding:4px 8px;border-radius:4px;color:#4a5568;font-size:13px}
.log{background:#1a202c;color:#a0aec0;padding:25px;border-radius:12px;font-size:12px;height:400px;overflow:auto;font-family:'Consolas','Monaco',monospace;line-height:1.5;box-shadow:inset 0 2px 4px rgba(0,0,0,0.5)}
</style></head>
<body>
<div class='container'>
    <div class='header'>
        <h1>FastPay Agent - Smoke Test Report</h1>
        <p>Generated on $timestamp</p>
    </div>
    <div class='banner'>$bannerText</div>
    <div class='stats'>
        <div class='stat'><h2 style='color:#2d3748'>$($results.Count)</h2><p>Total Flows</p></div>
        <div class='stat'><h2 style='color:#48bb78'>$passedCount</h2><p>Passed</p></div>
        <div class='stat'><h2 style='color:#e53e3e'>$failedCount</h2><p>Failed</p></div>
        <div class='stat'><h2 style='color:#805ad5'>${totalDuration}s</h2><p>Duration</p></div>
    </div>
    <table><tr><th style='width:50px;text-align:center'>#</th><th>Test Case Scenario</th><th>Source File</th><th style='text-align:center'>Status</th></tr>$testRowsHtml</table>
    <h3 style='margin-top:40px;color:#2d3748'>Execution Console Logs</h3>
    <pre class='log'>$escapedOutput</pre>
</div>
</body></html>
"@

$htmlPath = "$reportDir\FastPay_Smoke_Report_$timestamp.html"
$html | Out-File -FilePath $htmlPath -Encoding UTF8
Write-Host "`nBeautiful HTML Smoke Report Generated: $htmlPath" -ForegroundColor Green

# Automatically open the report in your browser
Start-Process $htmlPath