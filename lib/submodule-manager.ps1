# submodule-manager.ps1 â€” Manages tiny11builder upstream scripts
# Handles first-run detection, cloning, local copy, and updates

function Get-ScriptsPath {
    <#
    .SYNOPSIS
        Returns the path where tiny11builder scripts should be located.
    #>
    $devPath = Join-Path $PSScriptRoot "..\scripts\tiny11builder"
    $appDataPath = Join-Path $env:LOCALAPPDATA "tiny11-studio\scripts\tiny11builder"

    if (Test-Path $devPath) { return (Resolve-Path $devPath).Path }
    if (Test-Path $appDataPath) { return $appDataPath }

    # Return expected path (not yet created)
    if (Test-Path (Join-Path $PSScriptRoot "..\.git")) {
        return $devPath
    }
    return $appDataPath
}

function Test-SubmodulePresent {
    <#
    .SYNOPSIS
        Check if tiny11builder scripts are available.
    #>
    $path = Get-ScriptsPath
    if (-not (Test-Path $path)) { return $false }

    $files = Get-ChildItem -Path $path -Filter "*.ps1" -ErrorAction SilentlyContinue
    return ($files.Count -gt 0)
}

function Initialize-SubmoduleFromGit {
    <#
    .SYNOPSIS
        Clone tiny11builder from GitHub.
    .PARAMETER TargetPath
        Where to clone to. Defaults to auto-detected scripts path.
    #>
    param([string]$TargetPath)

    if (-not $TargetPath) { $TargetPath = Get-ScriptsPath }

    $parentDir = Split-Path $TargetPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }

    $repoUrl = "https://github.com/ntdevlabs/tiny11builder.git"

    try {
        & git clone $repoUrl $TargetPath 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Output "tiny11builder cloned successfully to $TargetPath"
            return $true
        }
    } catch {
        Write-Error "Failed to clone: $_"
    }
    return $false
}

function Copy-LocalScripts {
    <#
    .SYNOPSIS
        Copy tiny11builder from a local directory.
    .PARAMETER SourcePath
        Path to existing tiny11builder folder.
    #>
    param(
        [Parameter(Mandatory)][string]$SourcePath
    )

    if (-not (Test-Path $SourcePath)) {
        Write-Error "Source path does not exist: $SourcePath"
        return $false
    }

    $targetPath = Get-ScriptsPath
    $parentDir = Split-Path $targetPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }

    try {
        Copy-Item -Path "$SourcePath\*" -Destination $targetPath -Recurse -Force
        Write-Output "Scripts copied from $SourcePath to $targetPath"
        return $true
    } catch {
        Write-Error "Failed to copy: $_"
        return $false
    }
}

function Update-Submodule {
    <#
    .SYNOPSIS
        Pull latest changes from upstream tiny11builder.
    #>
    $path = Get-ScriptsPath

    if (-not (Test-Path (Join-Path $path ".git"))) {
        Write-Output "Not a git repository. Cannot update."
        return $false
    }

    try {
        Push-Location $path
        & git pull origin main 2>&1 | Out-Null
        Pop-Location

        if ($LASTEXITCODE -eq 0) {
            Write-Output "tiny11builder updated successfully"
            return $true
        }
    } catch {
        Pop-Location
        Write-Error "Failed to update: $_"
    }
    return $false
}

function Test-SubmoduleUpdateAvailable {
    <#
    .SYNOPSIS
        Check if a newer version of tiny11builder is available upstream.
    .OUTPUTS
        $true if update available, $false otherwise.
    #>
    $path = Get-ScriptsPath

    if (-not (Test-Path (Join-Path $path ".git"))) { return $false }

    try {
        Push-Location $path
        & git fetch origin 2>&1 | Out-Null
        $localHash = (& git rev-parse HEAD 2>&1).Trim()
        $remoteHash = (& git rev-parse origin/main 2>&1).Trim()
        Pop-Location

        return ($localHash -ne $remoteHash)
    } catch {
        Pop-Location
        return $false
    }
}
