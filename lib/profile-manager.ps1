# profile-manager.ps1 — Save, load, and manage configuration profiles
# Profiles store user selections as JSON files

function Get-CatalogPath {
    <#
    .SYNOPSIS
        Returns the path to the catalog directory.
    #>
    $devPath = Join-Path $PSScriptRoot "..\catalog"
    $appDataPath = Join-Path $env:LOCALAPPDATA "tiny11-studio\catalog"

    if (Test-Path (Join-Path $devPath "catalog.json")) { return $devPath }
    if (Test-Path (Join-Path $appDataPath "catalog.json")) { return $appDataPath }
    return $devPath
}

function Get-ProfilesPath {
    <#
    .SYNOPSIS
        Returns the path to the profiles directory.
    #>
    $devPath = Join-Path $PSScriptRoot "..\profiles"
    $appDataPath = Join-Path $env:LOCALAPPDATA "tiny11-studio\profiles"

    if (Test-Path $appDataPath) { return $appDataPath }
    if (Test-Path $devPath) { return $devPath }
    return $devPath
}

function Import-Catalog {
    <#
    .SYNOPSIS
        Load the catalog.json file.
    .OUTPUTS
        Parsed catalog object.
    #>
    $catalogFile = Join-Path (Get-CatalogPath) "catalog.json"
    if (-not (Test-Path $catalogFile)) {
        Write-Error "Catalog not found at $catalogFile"
        return $null
    }
    return (Get-Content -Raw $catalogFile | ConvertFrom-Json)
}

function Save-Profile {
    <#
    .SYNOPSIS
        Export current selections to a profile JSON file.
    .PARAMETER Name
        Profile display name.
    .PARAMETER Description
        Profile description.
    .PARAMETER Mode
        Build mode ("regular" or "core").
    .PARAMETER Selections
        Hashtable of item_id => $true/$false (remove/keep).
    .PARAMETER Path
        Output file path. If not specified, saves to profiles directory.
    #>
    param(
        [Parameter(Mandatory)][string]$Name,
        [string]$Description = "",
        [string]$Mode = "regular",
        [Parameter(Mandatory)][hashtable]$Selections,
        [string]$Path
    )

    if (-not $Path) {
        $safeName = $Name.ToLower() -replace '[^a-z0-9]', '_'
        $Path = Join-Path (Get-ProfilesPath) "$safeName.json"
    }

    $profile = @{
        name        = $Name
        description = $Description
        author      = $env:USERNAME
        version     = "1.0.0"
        mode        = $Mode
        selections  = $Selections
    }

    $json = $profile | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($Path, $json, [System.Text.Encoding]::UTF8)
    Write-Output "Profile saved to $Path"
    return $Path
}

function Import-Profile {
    <#
    .SYNOPSIS
        Load a profile from a JSON file.
    .PARAMETER Path
        Path to the profile JSON file.
    .OUTPUTS
        Parsed profile object.
    #>
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Error "Profile not found: $Path"
        return $null
    }

    return (Get-Content -Raw $Path | ConvertFrom-Json)
}

function Get-PresetProfiles {
    <#
    .SYNOPSIS
        List all available preset profiles.
    .OUTPUTS
        Array of objects with Name, Description, Path, Mode.
    #>
    $profilesDir = Get-ProfilesPath
    if (-not (Test-Path $profilesDir)) { return @() }

    $profiles = @()
    Get-ChildItem -Path $profilesDir -Filter "*.json" | ForEach-Object {
        try {
            $data = Get-Content -Raw $_.FullName | ConvertFrom-Json
            $profiles += @{
                Name        = $data.name
                Description = $data.description
                Mode        = $data.mode
                Path        = $_.FullName
            }
        } catch {
            Write-Warning "Invalid profile: $($_.Name)"
        }
    }
    return $profiles
}

function Merge-ProfileWithCatalog {
    <#
    .SYNOPSIS
        Apply a profile's selections to catalog items.
    .PARAMETER Profile
        Loaded profile object.
    .PARAMETER Catalog
        Loaded catalog object.
    .PARAMETER BuildMode
        Current build mode ("regular" or "core").
    .OUTPUTS
        Hashtable of item_id => $true/$false representing final selections.
    #>
    param(
        [Parameter(Mandatory)]$Profile,
        [Parameter(Mandatory)]$Catalog,
        [string]$BuildMode = "regular"
    )

    $selections = @{}

    foreach ($category in $Catalog.categories) {
        foreach ($item in $category.items) {
            # Skip core_only items in regular mode
            if ($item.mode -eq "core_only" -and $BuildMode -ne "core") {
                continue
            }

            $itemId = $item.id

            # Check if profile has explicit selection
            if ($Profile.selections.PSObject.Properties.Match($itemId).Count -gt 0) {
                $selections[$itemId] = [bool]$Profile.selections.$itemId
            } else {
                # Use catalog default
                $selections[$itemId] = [bool]$item.default_remove
            }
        }
    }

    return $selections
}

function Get-SelectionSummary {
    <#
    .SYNOPSIS
        Get a summary of selections grouped by category.
    .PARAMETER Selections
        Hashtable of item_id => $true/$false.
    .PARAMETER Catalog
        Loaded catalog object.
    .OUTPUTS
        Array of category summaries with item counts.
    #>
    param(
        [Parameter(Mandatory)][hashtable]$Selections,
        [Parameter(Mandatory)]$Catalog
    )

    $summary = @()
    foreach ($category in $Catalog.categories) {
        $removing = 0
        $keeping = 0
        foreach ($item in $category.items) {
            if ($Selections.ContainsKey($item.id)) {
                if ($Selections[$item.id]) { $removing++ }
                else { $keeping++ }
            }
        }
        if (($removing + $keeping) -gt 0) {
            $summary += @{
                Category = $category.name
                Removing = $removing
                Keeping  = $keeping
                Total    = $removing + $keeping
            }
        }
    }
    return $summary
}
