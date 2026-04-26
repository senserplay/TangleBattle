# Merge current feature/fix/chore branch back to develop and clean up.
# Run this from the feature branch after committing all work.

param(
    [switch]$NoPush,
    [switch]$KeepBranch
)

. "$PSScriptRoot/config.ps1"

Push-Location $script:RepoRoot
try {
    $current = (git rev-parse --abbrev-ref HEAD).Trim()
    if ($current -in @("main", "develop")) {
        Write-Error "You are on '$current'. Switch to a feature branch first."
        exit 1
    }
    if ($current -match "^release/") {
        Write-Error "Release branches are merged by make_release.ps1, not this script."
        exit 1
    }

    # Verify clean working tree
    $dirty = git status --porcelain
    if ($dirty) {
        Write-Error "Working tree is not clean. Commit first."
        Write-Host $dirty
        exit 1
    }

    # Verify LOG.md was updated in this branch
    $logChanges = git log develop..HEAD --oneline -- $script:LogFile
    if (-not $logChanges) {
        Write-Warning "LOG.md was not updated in this branch — this violates the constitution."
        $resp = Read-Host "Continue anyway? (y/N)"
        if ($resp -ne "y") { exit 1 }
    }

    Write-Host "Merging $current into develop..."
    git checkout develop
    if ($LASTEXITCODE -ne 0) { exit 1 }
    # Cooperative sync (CLAUDE.md §9): pick up any commits other
    # contributors pushed to develop while we were on the feature
    # branch. Without this the subsequent push could fail with
    # non-fast-forward, or worse, our merge could overwrite their
    # changes if someone force-pushes.
    Write-Host "Pulling latest origin/develop..."
    git fetch origin
    if ($LASTEXITCODE -ne 0) {
        Write-Error "git fetch failed — check remote connectivity."
        exit 1
    }
    git pull --ff-only origin develop
    if ($LASTEXITCODE -ne 0) {
        Write-Error "develop diverged from origin/develop. Resolve manually before merging the feature branch."
        exit 1
    }
    git merge --no-ff $current -m "Merge $current into develop"
    if ($LASTEXITCODE -ne 0) { exit 1 }

    if (-not $KeepBranch) {
        git branch -d $current
        if ($LASTEXITCODE -ne 0) {
            Write-Warning "Could not delete branch $current — keep it for now."
        }
    }

    if (-not $NoPush) {
        Write-Host "Pushing develop..."
        git push origin develop
    }

    Write-Host ""
    Write-Host "===== BRANCH MERGED ====="
    Write-Host "Merged: $current -> develop"
    if (-not $NoPush) { Write-Host "Pushed: origin/develop" }
    Write-Host ""
    Write-Host "Running release check..."
    Write-Host "========================="
    & "$PSScriptRoot/check_release.ps1"
} finally {
    Pop-Location
}
