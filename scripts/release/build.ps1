# Build a Windows release binary via Godot CLI.
# Usage: pwsh scripts/release/build.ps1 [-Version 0.2] [-Output path/to/file.exe]

param(
    [string]$Version = "",
    [string]$Output = ""
)

. "$PSScriptRoot/config.ps1"

Push-Location $script:RepoRoot
try {
    if (-not $Version) { $Version = Get-CurrentVersion }
    if (-not $Output) {
        New-Item -ItemType Directory -Force -Path $script:BuildsDir | Out-Null
        $Output = Join-Path $script:BuildsDir "TangleBattle-v$Version.exe"
    }

    if (-not (Test-Path $script:GodotEditorExe)) {
        Write-Error "Godot editor exe not found: $script:GodotEditorExe"
        Write-Error "Set TANGLE_GODOT_EDITOR env var or edit scripts/release/config.ps1"
        exit 1
    }

    # Ensure builds/ exists
    $outDir = Split-Path $Output -Parent
    if (-not (Test-Path $outDir)) {
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    }

    Write-Host "Building TangleBattle v$Version -> $Output"
    Write-Host "Godot: $script:GodotEditorExe"
    Write-Host "Preset: $script:ExportPreset"
    Write-Host ""

    # First, run --import to make sure resources are imported (needed on CI/clean)
    Write-Host "[1/2] Importing resources..."
    & $script:GodotEditorExe --headless --import --path $script:RepoRoot --quit 2>&1 |
        Where-Object { $_ -notmatch "^\s*$" } | Select-Object -Last 30
    # Don't fail on import — Godot returns nonzero even on success sometimes

    Write-Host ""
    Write-Host "[2/2] Exporting Windows release..."
    & $script:GodotEditorExe --headless --path $script:RepoRoot --export-release $script:ExportPreset $Output 2>&1 |
        Tee-Object -Variable exportOutput

    if (-not (Test-Path $Output)) {
        Write-Error "Export failed — output file not created."
        exit 1
    }

    $sizeMB = [math]::Round((Get-Item $Output).Length / 1MB, 2)
    Write-Host ""
    Write-Host "===== BUILD COMPLETE ====="
    Write-Host "File: $Output"
    Write-Host "Size: $sizeMB MB"
    Write-Host "=========================="
} finally {
    Pop-Location
}
