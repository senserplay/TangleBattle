# Create a new development branch from develop.
# Usage: pwsh scripts/release/new_branch.ps1 <type> <name>
# <type>: feature | fix | chore | hotfix
# <name>: kebab-case short identifier
#
# Example: pwsh scripts/release/new_branch.ps1 feature phase-shot-tweak

param(
    [Parameter(Mandatory)] [ValidateSet("feature", "fix", "chore", "hotfix")] [string]$Type,
    [Parameter(Mandatory)] [string]$Name
)

. "$PSScriptRoot/config.ps1"

# Validate name
if ($Name -notmatch '^[a-z0-9][a-z0-9-]*$') {
    Write-Error "Name must be kebab-case (lowercase letters, digits, hyphens). Got: '$Name'"
    exit 1
}

$branchName = "$Type/$Name"

Push-Location $script:RepoRoot
try {
    # Verify clean working tree
    $dirty = git status --porcelain
    if ($dirty) {
        Write-Error "Working tree is not clean. Commit or stash first."
        Write-Host $dirty
        exit 1
    }

    # Hotfix branches start from latest tag, not develop
    if ($Type -eq "hotfix") {
        $tag = Get-LastReleaseTag
        if (-not $tag) {
            Write-Error "No release tag found — cannot start hotfix."
            exit 1
        }
        Write-Host "Starting hotfix from tag $tag..."
        git checkout $tag
        if ($LASTEXITCODE -ne 0) { exit 1 }
    } else {
        Write-Host "Switching to develop..."
        git checkout develop
        if ($LASTEXITCODE -ne 0) { exit 1 }
        git pull --ff-only origin develop 2>$null
    }

    # Check branch doesn't already exist
    $exists = git rev-parse --verify --quiet "refs/heads/$branchName"
    if ($LASTEXITCODE -eq 0) {
        Write-Error "Branch '$branchName' already exists locally."
        exit 1
    }

    git checkout -b $branchName
    if ($LASTEXITCODE -ne 0) { exit 1 }

    Write-Host ""
    Write-Host "===== NEW BRANCH READY ====="
    Write-Host "Branch: $branchName"
    Write-Host ""
    Write-Host "Next steps for Claude:"
    Write-Host "  1. Read work_notes/LOG.md"
    Write-Host "  2. Implement changes + test via mcp__godot__run_project"
    Write-Host "  3. Update work_notes/LOG.md"
    Write-Host "  4. git commit"
    Write-Host "  5. Run pwsh scripts/release/finish_branch.ps1"
    Write-Host "============================"
} finally {
    Pop-Location
}
