# Centralized config for release scripts.
# Override via environment variables if needed.

$script:GodotExe = if ($env:TANGLE_GODOT_EXE) { $env:TANGLE_GODOT_EXE } else {
    "C:\Users\belya\Downloads\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64_console.exe"
}
$script:GodotEditorExe = if ($env:TANGLE_GODOT_EDITOR) { $env:TANGLE_GODOT_EDITOR } else {
    "C:\Users\belya\Downloads\Godot_v4.6.1-stable_mono_win64\Godot_v4.6.1-stable_mono_win64.exe"
}

$script:RepoRoot = (Resolve-Path "$PSScriptRoot/../..").Path
$script:VersionFile = Join-Path $script:RepoRoot "VERSION"
$script:ProjectFile = Join-Path $script:RepoRoot "project.godot"
$script:ChangelogFile = Join-Path $script:RepoRoot "CHANGELOG.md"
$script:LogFile = Join-Path $script:RepoRoot "work_notes/LOG.md"
$script:BuildsDir = Join-Path $script:RepoRoot "builds"
$script:ExportPreset = "Windows Desktop"

# Release trigger thresholds
$script:MinLogEntriesForRelease = 5
$script:MaxDaysSinceLastRelease = 14
# Keywords in LOG.md that mark a "major" change (any one triggers release)
$script:MajorChangeKeywords = @(
    "новая способность", "новая пассивка", "новая карта", "новый режим",
    "новая система", "RELEASE", "переработка"
)

function Get-CurrentVersion {
    if (Test-Path $script:VersionFile) {
        return (Get-Content $script:VersionFile -Raw).Trim()
    }
    return "0.0"
}

function Get-LastReleaseTag {
    Push-Location $script:RepoRoot
    try {
        $tag = git describe --tags --abbrev=0 --match "v*" 2>$null
        if ($LASTEXITCODE -eq 0) { return $tag.Trim() }
        return $null
    } finally { Pop-Location }
}

function Bump-Version {
    param(
        [Parameter(Mandatory)] [ValidateSet("major", "minor")] [string]$BumpType,
        [string]$CurrentVersion = (Get-CurrentVersion)
    )
    $parts = $CurrentVersion.Split(".")
    $major = [int]$parts[0]
    $minor = [int]$parts[1]
    if ($BumpType -eq "major") { $major++; $minor = 0 } else { $minor++ }
    return "$major.$minor"
}
