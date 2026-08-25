$ErrorActionPreference = "Stop"

# ============================================================
# Orion Helper Data Updater
# ============================================================

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$AssetsDir = Join-Path $RepoRoot "assets"
$ManifestPath = Join-Path $AssetsDir "manifest.json"

$Branch = "main"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Orion Helper Data Updater"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Repository: $RepoRoot"
Write-Host "Branch:     $Branch"
Write-Host ""

# ------------------------------------------------------------
# Git helper
# ------------------------------------------------------------

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    & git -C $RepoRoot @Arguments

    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed: git $($Arguments -join ' ')"
    }
}

# ------------------------------------------------------------
# Check repository
# ------------------------------------------------------------

Write-Host "Checking Git repository..."

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    throw "Not a Git repository: $RepoRoot"
}

# Make Git accept the repository even if it is owned by Administrators.
& git config --global --add safe.directory $RepoRoot 2>$null

& git -C $RepoRoot rev-parse --is-inside-work-tree *> $null

if ($LASTEXITCODE -ne 0) {
    throw "Git repository check failed."
}

Write-Host "Git repository OK." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Check working tree
# ------------------------------------------------------------

Write-Host "Checking working tree..."

$status = & git -C $RepoRoot status --porcelain

# Update-Data.ps1 itself is intentionally ignored from the check.
$foreignChanges = @(
    $status | Where-Object {
        $_ -and
        ($_ -notmatch "Update-Data\.ps1$")
    }
)

if ($foreignChanges.Count -gt 0) {

    Write-Host ""
    Write-Host "WARNING: working tree contains changes:" -ForegroundColor Yellow
    $foreignChanges | ForEach-Object {
        Write-Host "  $_"
    }

    Write-Host ""
    $answer = Read-Host "Continue anyway? [y/n]"

    if ($answer -notmatch "^(y|yes)$") {
        Write-Host "Cancelled."
        exit 0
    }
}

Write-Host "Working tree checked." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Read manifest
# ------------------------------------------------------------

if (-not (Test-Path $ManifestPath)) {
    throw "manifest.json not found: $ManifestPath"
}

Write-Host "Reading manifest.json..."
Write-Host ""

$manifestText = Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8
$manifest = $manifestText | ConvertFrom-Json

$currentVersion = [int]$manifest.version
$newVersion = $currentVersion + 1

Write-Host "Current version: $currentVersion"
Write-Host "New version:     $newVersion"
Write-Host ""

# ------------------------------------------------------------
# Files to include
#
# Everything under assets/*.json except:
#   - manifest.json
#   - tiles
#
# Tiles are ignored recursively if their path contains "tiles".
# ------------------------------------------------------------

Write-Host "Scanning JSON files..."
Write-Host ""

$files = @{}

Get-ChildItem `
    -LiteralPath $AssetsDir `
    -Recurse `
    -File `
    -Filter "*.json" |
    ForEach-Object {

        $fullPath = $_.FullName

        $relativePath = $fullPath.Substring(
            $AssetsDir.Length + 1
        ).Replace("\", "/")

        # Ignore manifest itself.
        if ($relativePath -eq "manifest.json") {
            return
        }

        # Ignore map tiles.
        if ($relativePath -match "(^|/)tiles(/|$)") {
            Write-Host "SKIP: $relativePath" -ForegroundColor DarkGray
            return
        }

        Write-Host "HASH: $relativePath"

        $hash = (Get-FileHash `
            -LiteralPath $fullPath `
            -Algorithm SHA256).Hash.ToUpperInvariant()

        $files[$relativePath] = $hash
    }

Write-Host ""

# ------------------------------------------------------------
# Build new manifest
# ------------------------------------------------------------

$newManifest = [ordered]@{
    version = $newVersion
    files   = [ordered]@{}
}

foreach ($path in ($files.Keys | Sort-Object)) {
    $newManifest.files[$path] = $files[$path]
}

# ConvertTo-Json formatting.
$json = $newManifest | ConvertTo-Json -Depth 20

# ------------------------------------------------------------
# Write UTF-8 WITHOUT BOM.
#
# Windows PowerShell 5.1 compatible.
# ------------------------------------------------------------

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

[System.IO.File]::WriteAllText(
    $ManifestPath,
    ($json + [Environment]::NewLine),
    $utf8NoBom
)

Write-Host "manifest.json updated." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Show manifest
# ------------------------------------------------------------

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " New manifest"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Get-Content -LiteralPath $ManifestPath -Raw -Encoding UTF8 |
    Write-Host

Write-Host ""

# ------------------------------------------------------------
# Git diff
# ------------------------------------------------------------

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Git diff"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

& git -C $RepoRoot diff -- assets/manifest.json

if ($LASTEXITCODE -ne 0) {
    throw "Unable to display Git diff."
}

Write-Host ""

# ------------------------------------------------------------
# Confirm commit
# ------------------------------------------------------------

$commitAnswer = Read-Host "Commit this manifest? [y/n]"

if ($commitAnswer -notmatch "^(y|yes)$") {

    Write-Host ""
    Write-Host "Cancelled. manifest.json was NOT committed." -ForegroundColor Yellow
    Write-Host ""

    exit 0
}

# ------------------------------------------------------------
# Add manifest + changed data JSON files
# ------------------------------------------------------------

Write-Host ""
Write-Host "Adding changed data files..."

Invoke-Git @("add", "--", "assets")

Write-Host "Files staged." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Show staged files
# ------------------------------------------------------------

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host " Staged changes"
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

& git -C $RepoRoot status --short

Write-Host ""

# ------------------------------------------------------------
# Commit
# ------------------------------------------------------------

$commitMessage = "Update data manifest to version $newVersion"

Write-Host "Creating commit:"
Write-Host $commitMessage
Write-Host ""

Invoke-Git @(
    "commit",
    "-m",
    $commitMessage
)

Write-Host ""
Write-Host "Commit created." -ForegroundColor Green
Write-Host ""

# ------------------------------------------------------------
# Push confirmation
# ------------------------------------------------------------

$pushAnswer = Read-Host "Push to origin/$Branch? [y/n]"

if ($pushAnswer -notmatch "^(y|yes)$") {

    Write-Host ""
    Write-Host "Commit created but NOT pushed." -ForegroundColor Yellow
    Write-Host ""

    & git -C $RepoRoot log -1 --oneline

    exit 0
}

# ------------------------------------------------------------
# Push
# ------------------------------------------------------------

Write-Host ""
Write-Host "Pushing..." -ForegroundColor Cyan
Write-Host ""

Invoke-Git @(
    "push",
    "origin",
    $Branch
)

# ------------------------------------------------------------
# Done
# ------------------------------------------------------------

Write-Host ""
Write-Host "==========================================" -ForegroundColor Green
Write-Host " DONE"
Write-Host "==========================================" -ForegroundColor Green
Write-Host ""

Write-Host "Version: $newVersion"
Write-Host "Manifest: $ManifestPath"
Write-Host ""

& git -C $RepoRoot log -1 --oneline

Write-Host ""