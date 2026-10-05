# build-and-install.ps1
# Build the OpenGoal VSCode extension (.vsix).
# Installs npm dependencies and @vscode/vsce locally if missing.
# Does NOT install the extension into VS Code.
#
# Usage:
#   cd D:\projects\hww\_c\opengoal-vscode.git
#   powershell -ExecutionPolicy Bypass -File build-and-install.ps1

[CmdletBinding()]
param(
    [string]$ProjectDir = (Get-Location).Path
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-Ok($msg)   { Write-Host "OK: $msg" -ForegroundColor Green }
function Write-Err($msg)  { Write-Host "ERROR: $msg" -ForegroundColor Red }

# 0. Environment checks
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Err "Node.js not found in PATH. Install Node.js LTS: https://nodejs.org/"
    exit 1
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Err "npm not found in PATH."
    exit 1
}

Set-Location -LiteralPath $ProjectDir
Write-Step "Working directory: $ProjectDir"

# 1. Project dependencies
if (-not (Test-Path -LiteralPath 'node_modules')) {
    Write-Step "node_modules missing - running npm install"
    npm install
    if ($LASTEXITCODE -ne 0) { Write-Err "npm install failed"; exit 1 }
} else {
    Write-Step "node_modules present"
}

# 2. Ensure @vscode/vsce is available locally
$vsceLocal = Join-Path $ProjectDir 'node_modules\.bin\vsce.cmd'
if (-not (Test-Path -LiteralPath $vsceLocal)) {
    Write-Step "Installing @vscode/vsce locally"
    npm install --save-dev @vscode/vsce
    if ($LASTEXITCODE -ne 0) { Write-Err "npm install @vscode/vsce failed"; exit 1 }
}
if (-not (Test-Path -LiteralPath $vsceLocal)) {
    Write-Err "vsce.cmd not found at $vsceLocal"
    exit 1
}
Write-Step "Using local vsce: $vsceLocal"

# 3. Clean old .vsix
Write-Step "Removing old .vsix files"
Get-ChildItem -LiteralPath $ProjectDir -Filter '*.vsix' -File -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

# 4. Package
Write-Step "Packaging with vsce"
& $vsceLocal package --no-yarn
if ($LASTEXITCODE -ne 0) { Write-Err "vsce package failed"; exit 1 }

# 5. Locate produced .vsix
$vsix = Get-ChildItem -LiteralPath $ProjectDir -Filter '*.vsix' -File |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1

if (-not $vsix) {
    Write-Err ".vsix not found after packaging"
    exit 1
}

# 6. Size sanity check
$size = $vsix.Length
Write-Step ("Found: {0} ({1:N0} bytes)" -f $vsix.Name, $size)
if ($size -lt 1MB) {
    Write-Err ("Package too small ({0:N0} bytes). Packaging aborted." -f $size)
    Write-Host "Run manually to see the error:" -ForegroundColor Yellow
    Write-Host "  node_modules\.bin\vsce.cmd package --no-yarn" -ForegroundColor Yellow
    exit 1
}

# 7. ZIP integrity check via .NET
Write-Step "Verifying archive integrity"
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem | Out-Null
    $zip = [System.IO.Compression.ZipFile]::OpenRead($vsix.FullName)
    $entries = $zip.Entries.Count
    $zip.Dispose()
    Write-Ok "Archive is valid, entries: $entries"
} catch {
    Write-Err "Archive is corrupted: $($_.Exception.Message)"
    exit 1
}

# 8. Summary
Write-Host ""
Write-Ok ("Built: {0}" -f $vsix.FullName)
Write-Host ""
Write-Host "Install manually in VS Code:" -ForegroundColor Yellow
Write-Host "  Ctrl+Shift+P -> Extensions: Install from VSIX..." -ForegroundColor Yellow
Write-Host ("  File: {0}" -f $vsix.FullName) -ForegroundColor Yellow
Write-Host ""
Write-Host "Or drag and drop the .vsix file into the VS Code window." -ForegroundColor Yellow