# Check whether a release is recommended.
# Exit code: 0 = release recommended, 1 = not yet, 2 = error.
# Prints a JSON-ish summary to stdout for Claude to parse.

. "$PSScriptRoot/config.ps1"

Push-Location $script:RepoRoot
try {
    $currentVersion = Get-CurrentVersion
    $lastTag = Get-LastReleaseTag

    # Count commits since last tag
    $commitCount = 0
    if ($lastTag) {
        $commitCount = (git rev-list --count "$lastTag..HEAD" 2>$null)
        if ($LASTEXITCODE -ne 0) { $commitCount = 0 }
        $commitCount = [int]$commitCount
    } else {
        $commitCount = (git rev-list --count HEAD 2>$null)
        $commitCount = [int]$commitCount
    }

    # Count LOG.md entries (## headings) since last tag
    $logEntries = 0
    $hasMajor = $false
    $logSinceTag = ""
    if (Test-Path $script:LogFile) {
        if ($lastTag) {
            # Diff of LOG.md from tag to HEAD
            $logSinceTag = git diff "$lastTag..HEAD" -- $script:LogFile 2>$null
            # Count added "## " heading lines
            $logEntries = ($logSinceTag -split "`n" |
                Where-Object { $_ -match '^\+## \d{4}-' }).Count
        } else {
            # No tag yet — count all top-level dated headings
            $logEntries = (Get-Content $script:LogFile |
                Where-Object { $_ -match '^## \d{4}-' }).Count
        }

        # Detect major-change keywords in recent LOG content
        $recentLog = if ($lastTag) { $logSinceTag } else { Get-Content $script:LogFile -Raw -Encoding UTF8 }
        foreach ($kw in $script:MajorChangeKeywords) {
            if ($recentLog -match [regex]::Escape($kw)) {
                $hasMajor = $true
                break
            }
        }
    }

    # Days since last release
    $daysSinceRelease = -1
    if ($lastTag) {
        $tagDateStr = git log -1 --format=%ai $lastTag 2>$null
        if ($LASTEXITCODE -eq 0 -and $tagDateStr) {
            $tagDate = [datetime]::Parse($tagDateStr.Trim().Substring(0, 10))
            $daysSinceRelease = ((Get-Date) - $tagDate).Days
        }
    }

    # Determine triggers
    $triggers = @()
    if ($logEntries -ge $script:MinLogEntriesForRelease) {
        $triggers += "log_entries_threshold ($logEntries >= $($script:MinLogEntriesForRelease))"
    }
    if ($hasMajor) {
        $triggers += "major_change_keyword_in_log"
    }
    if ($daysSinceRelease -ge $script:MaxDaysSinceLastRelease -and $commitCount -gt 0) {
        $triggers += "stale_release ($daysSinceRelease days, $commitCount commits)"
    }

    $recommend = $triggers.Count -gt 0

    Write-Host "===== RELEASE CHECK ====="
    Write-Host "Current version       : $currentVersion"
    Write-Host "Last release tag      : $(if ($lastTag) { $lastTag } else { '(none)' })"
    Write-Host "Commits since tag     : $commitCount"
    Write-Host "LOG entries since tag : $logEntries"
    Write-Host "Major change detected : $hasMajor"
    Write-Host "Days since release    : $(if ($daysSinceRelease -ge 0) { $daysSinceRelease } else { 'n/a' })"
    Write-Host "Recommend release     : $recommend"
    if ($recommend) {
        Write-Host "Triggers              :"
        foreach ($t in $triggers) { Write-Host "  - $t" }
        $nextVer = Bump-Version -BumpType minor -CurrentVersion $currentVersion
        Write-Host "Next minor version    : $nextVer"
    }
    Write-Host "========================="

    if ($recommend) { exit 0 } else { exit 1 }
} catch {
    Write-Error "check_release failed: $_"
    exit 2
} finally {
    Pop-Location
}
