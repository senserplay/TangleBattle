# Full release process — creates release/x.y branch, bumps version,
# updates CHANGELOG, builds Windows exe, merges to main, tags vX.Y,
# pushes everything, creates GitHub Release, merges back to develop.
#
# Usage:
#   pwsh scripts/release/make_release.ps1                      # minor bump (default)
#   pwsh scripts/release/make_release.ps1 -BumpType major
#   pwsh scripts/release/make_release.ps1 -SkipBuild           # skip exe build
#   pwsh scripts/release/make_release.ps1 -SkipPush            # local only
#   pwsh scripts/release/make_release.ps1 -DryRun              # show what would happen

param(
    [ValidateSet("major", "minor")] [string]$BumpType = "minor",
    [switch]$SkipBuild,
    [switch]$SkipPush,
    [switch]$DryRun,
    [switch]$FromHotfix,
    [string]$NotesAddendum = ""
)

. "$PSScriptRoot/config.ps1"

function Invoke-Cmd($cmd) {
    if ($DryRun) {
        Write-Host "[DRY-RUN] $cmd" -ForegroundColor Yellow
        return
    }
    Write-Host "+ $cmd" -ForegroundColor Cyan
    Invoke-Expression $cmd
    if ($LASTEXITCODE -ne 0) { throw "Command failed: $cmd" }
}

function Update-VersionInProjectGodot([string]$NewVersion) {
    $content = Get-Content $script:ProjectFile -Raw
    if ($content -match 'config/version="[^"]*"') {
        $content = $content -replace 'config/version="[^"]*"', "config/version=`"$NewVersion`""
    } else {
        # Insert after config/name line
        $content = $content -replace '(config/name="[^"]*")', "`$1`r`nconfig/version=`"$NewVersion`""
    }
    if (-not $DryRun) {
        Set-Content -Path $script:ProjectFile -Value $content -NoNewline
    }
}

function Update-ChangelogForRelease([string]$NewVersion, [string]$LogSummary) {
    $today = (Get-Date -Format "yyyy-MM-dd")
    $content = Get-Content $script:ChangelogFile -Raw

    $newSection = @"
## [$NewVersion] — $today

$LogSummary

---

"@
    # Insert after the [Unreleased] section, before the previous version
    $unreleasedPattern = '(?ms)(## \[Unreleased\].*?\n)(---\n+)(## )'
    if ($content -match $unreleasedPattern) {
        $content = $content -replace $unreleasedPattern, "`$1### Added`r`n_будущие изменения здесь_`r`n`r`n---`r`n`r`n$newSection`$3"
        # The above replaces twice — fix by simpler approach:
        $content = Get-Content $script:ChangelogFile -Raw
    }

    # Simpler: find "## [Unreleased]" block end (next "---") and insert after it
    $lines = $content -split "`r?`n"
    $newLines = @()
    $inserted = $false
    $afterUnreleased = $false
    foreach ($line in $lines) {
        $newLines += $line
        if ($line -match '^## \[Unreleased\]') { $afterUnreleased = $true }
        if ($afterUnreleased -and -not $inserted -and $line -eq "---") {
            $newLines += ""
            $newLines += $newSection.TrimEnd()
            $inserted = $true
            $afterUnreleased = $false
        }
    }
    # Add link reference at end
    $newLines += ""
    $newLines += "[$NewVersion]: https://github.com/senserplay/TangleBattle/releases/tag/v$NewVersion"

    if (-not $DryRun) {
        Set-Content -Path $script:ChangelogFile -Value ($newLines -join "`r`n") -NoNewline
    }
}

function Get-LogSummarySinceTag([string]$Tag) {
    if (-not $Tag) {
        return "### Added`r`n- Initial release."
    }
    # Show LOG.md ## headings added since tag
    Push-Location $script:RepoRoot
    try {
        $diff = git log "$Tag..HEAD" --pretty=format:"- %s" 2>$null
        if (-not $diff) { return "### Changed`r`n- Internal cleanup, no user-facing changes." }
        return "### Changed`r`n$diff"
    } finally { Pop-Location }
}

# ============== MAIN ==============

Push-Location $script:RepoRoot
try {
    $currentVersion = Get-CurrentVersion
    $lastTag = Get-LastReleaseTag
    $newVersion = Bump-Version -BumpType $BumpType -CurrentVersion $currentVersion
    $newTag = "v$newVersion"
    $releaseBranch = "release/$newVersion"

    Write-Host "===== RELEASE PLAN ====="
    Write-Host "Current version : $currentVersion"
    Write-Host "Last tag        : $(if ($lastTag) { $lastTag } else { '(none)' })"
    Write-Host "New version     : $newVersion"
    Write-Host "New tag         : $newTag"
    Write-Host "Release branch  : $releaseBranch"
    Write-Host "Bump type       : $BumpType"
    Write-Host "Skip build      : $SkipBuild"
    Write-Host "Skip push       : $SkipPush"
    Write-Host "Dry run         : $DryRun"
    Write-Host "========================"
    Write-Host ""

    # Pre-checks
    $current = (git rev-parse --abbrev-ref HEAD).Trim()
    $expectedSrc = if ($FromHotfix) { "hotfix/" } else { "develop" }
    if (-not $FromHotfix -and $current -ne "develop") {
        throw "Must be on 'develop' branch (currently on '$current'). Use -FromHotfix for hotfix release."
    }

    $dirty = git status --porcelain
    if ($dirty) {
        throw "Working tree is not clean. Commit first.`n$dirty"
    }

    # 1. Create release branch
    Write-Host "[1/10] Creating release branch $releaseBranch..."
    Invoke-Cmd "git checkout -b $releaseBranch"

    # 2. Bump VERSION file
    Write-Host "[2/10] Bumping VERSION -> $newVersion..."
    if (-not $DryRun) { Set-Content -Path $script:VersionFile -Value $newVersion }

    # 3. Bump project.godot
    Write-Host "[3/10] Bumping project.godot version..."
    Update-VersionInProjectGodot $newVersion

    # 4. Bump export_presets.cfg version fields
    if (Test-Path "$script:RepoRoot/export_presets.cfg") {
        $exportContent = Get-Content "$script:RepoRoot/export_presets.cfg" -Raw
        $exportContent = $exportContent -replace 'application/file_version="[^"]*"', "application/file_version=`"$newVersion.0.0`""
        $exportContent = $exportContent -replace 'application/product_version="[^"]*"', "application/product_version=`"$newVersion.0.0`""
        if (-not $DryRun) { Set-Content -Path "$script:RepoRoot/export_presets.cfg" -Value $exportContent -NoNewline }
    }

    # 5. Update CHANGELOG
    Write-Host "[4/10] Updating CHANGELOG.md..."
    $logSummary = Get-LogSummarySinceTag $lastTag
    if ($NotesAddendum) { $logSummary += "`r`n`r`n$NotesAddendum" }
    Update-ChangelogForRelease $newVersion $logSummary

    # 6. Smoke test (Godot --quit-after)
    Write-Host "[5/10] Smoke test..."
    if (-not $SkipBuild -and -not $DryRun) {
        & $script:GodotEditorExe --headless --path $script:RepoRoot --quit-after 100 2>&1 |
            Select-Object -Last 5
    }

    # 7. Commit version bumps
    Write-Host "[6/10] Committing version bumps..."
    Invoke-Cmd "git add VERSION project.godot CHANGELOG.md export_presets.cfg"
    Invoke-Cmd "git commit -m `"release: v$newVersion`""

    # 8. Build (after commit so version in exe is correct)
    if (-not $SkipBuild) {
        Write-Host "[7/10] Building Windows release..."
        if (-not $DryRun) {
            & "$PSScriptRoot/build.ps1" -Version $newVersion
            if ($LASTEXITCODE -ne 0) { throw "Build failed" }
        }
    } else {
        Write-Host "[7/10] Skipping build (per -SkipBuild)"
    }

    # 9. Merge to main, tag
    # Godot --import pass may re-render .import files with different line endings;
    # discard those transient changes so checkout main doesn't abort.
    $dirtyAfterBuild = git status --porcelain
    if ($dirtyAfterBuild) {
        Write-Host "Discarding transient working tree changes from build pass..."
        Invoke-Cmd "git checkout -- ."
    }
    Write-Host "[8/10] Merging to main and tagging..."
    Invoke-Cmd "git checkout main"
    Invoke-Cmd "git merge --no-ff $releaseBranch -m `"Release $newTag`""
    Invoke-Cmd "git tag -a $newTag -m `"Release $newVersion`""

    # 10. Push
    if (-not $SkipPush) {
        Write-Host "[9/10] Pushing main + tag..."
        Invoke-Cmd "git push origin main"
        Invoke-Cmd "git push origin $newTag"
    } else {
        Write-Host "[9/10] Skipping push (per -SkipPush)"
    }

    # 11. GitHub Release
    if (-not $SkipPush -and -not $DryRun) {
        $ghAvailable = Get-Command gh -ErrorAction SilentlyContinue
        $exePath = Join-Path $script:BuildsDir "TangleBattle-v$newVersion.exe"
        $notesPath = Join-Path $script:RepoRoot "release_notes_v$newVersion.md"
        Set-Content -Path $notesPath -Value $logSummary

        if ($ghAvailable) {
            Write-Host "[10/10] Creating GitHub Release..."
            $ghArgs = @("release", "create", $newTag, "--title", "TangleBattle $newTag", "--notes-file", $notesPath)
            if (-not $SkipBuild -and (Test-Path $exePath)) { $ghArgs += $exePath }
            & gh @ghArgs
        } else {
            Write-Warning "gh CLI not found. Manual steps:"
            Write-Host "  winget install GitHub.cli"
            Write-Host "  gh auth login"
            Write-Host "  gh release create $newTag --title 'TangleBattle $newTag' --notes-file '$notesPath' '$exePath'"
        }
    }

    # 12. Merge release branch back to develop
    Write-Host "[11/10] Merging release back to develop..."
    Invoke-Cmd "git checkout develop"
    Invoke-Cmd "git merge --no-ff $releaseBranch -m `"Merge $releaseBranch into develop`""
    if (-not $SkipPush) {
        Invoke-Cmd "git push origin develop"
    }

    # 13. Delete release branch
    Invoke-Cmd "git branch -d $releaseBranch"

    Write-Host ""
    Write-Host "===== RELEASE $newTag DONE ====="
    Write-Host "Tag      : $newTag"
    Write-Host "Branch   : main, develop both updated"
    if (-not $SkipBuild) {
        $exePath = Join-Path $script:BuildsDir "TangleBattle-v$newVersion.exe"
        if (Test-Path $exePath) {
            $sizeMB = [math]::Round((Get-Item $exePath).Length / 1MB, 2)
            Write-Host "Build    : $exePath ($sizeMB MB)"
        }
    }
    Write-Host "================================="

    # Add release entry to LOG
    if (-not $DryRun) {
        $today = Get-Date -Format "yyyy-MM-dd"
        $logHead = Get-Content $script:LogFile -Raw
        $newLogEntry = "## $today — RELEASE v$newVersion`r`n`r`nСм. CHANGELOG.md и GitHub Release: https://github.com/senserplay/TangleBattle/releases/tag/$newTag`r`n`r`n---`r`n`r`n"
        # Insert after "# TangleBattle — Рабочий лог"
        $logHead = $logHead -replace '(# TangleBattle — Рабочий лог\r?\n\r?\n)', "`$1$newLogEntry"
        Set-Content -Path $script:LogFile -Value $logHead -NoNewline
        Write-Host "LOG.md updated. Commit + push manually if desired."
    }
} finally {
    Pop-Location
}
