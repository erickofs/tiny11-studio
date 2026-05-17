# scan-iso.ps1 — ISO analysis and DISM enumeration functions
# Provides functions to mount ISOs, detect editions, and scan installed packages

function Mount-IsoImage {
    <#
    .SYNOPSIS
        Mount an ISO file and return the drive letter.
    .PARAMETER Path
        Full path to the .iso file.
    .OUTPUTS
        Drive letter string (e.g., "E:") or $null on failure.
    #>
    param(
        [Parameter(Mandatory)][string]$Path
    )

    if (-not (Test-Path $Path)) {
        Write-Error "ISO file not found: $Path"
        return $null
    }

    try {
        $mountResult = Mount-DiskImage -ImagePath $Path -PassThru
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        if ($driveLetter) {
            return "$($driveLetter):"
        }
    } catch {
        Write-Error "Failed to mount ISO: $_"
    }
    return $null
}

function Dismount-IsoImage {
    <#
    .SYNOPSIS
        Dismount a previously mounted ISO.
    .PARAMETER DriveLetter
        Drive letter of mounted ISO (e.g., "E:" or "E").
    #>
    param(
        [Parameter(Mandatory)][string]$DriveLetter
    )

    $letter = $DriveLetter -replace '[:\\]', ''
    try {
        Get-Volume -DriveLetter $letter | Get-DiskImage | Dismount-DiskImage | Out-Null
        return $true
    } catch {
        Write-Error "Failed to dismount: $_"
        return $false
    }
}

function Get-IsoEditions {
    <#
    .SYNOPSIS
        List all editions available in the Windows image.
    .PARAMETER DriveLetter
        Drive letter of mounted ISO.
    .OUTPUTS
        Array of objects with Index, Name, Size, Description.
    #>
    param(
        [Parameter(Mandatory)][string]$DriveLetter
    )

    $letter = $DriveLetter.TrimEnd(':') + ":"
    $wimPath = "$letter\sources\install.wim"
    $esdPath = "$letter\sources\install.esd"

    $imagePath = $null
    if (Test-Path $wimPath) { $imagePath = $wimPath }
    elseif (Test-Path $esdPath) { $imagePath = $esdPath }
    else {
        Write-Error "No install.wim or install.esd found on $letter"
        return @()
    }

    try {
        $images = Get-WindowsImage -ImagePath $imagePath
        $editions = @()
        foreach ($img in $images) {
            $editions += @{
                Index       = $img.ImageIndex
                Name        = $img.ImageName
                Size        = $img.ImageSize
                Description = $img.ImageDescription
            }
        }
        return $editions
    } catch {
        Write-Error "Failed to read image info: $_"
        return @()
    }
}

function Get-ImageFormat {
    <#
    .SYNOPSIS
        Detect whether the ISO contains WIM or ESD format.
    .OUTPUTS
        "wim", "esd", or $null.
    #>
    param(
        [Parameter(Mandatory)][string]$DriveLetter
    )

    $letter = $DriveLetter.TrimEnd(':') + ":"
    if (Test-Path "$letter\sources\install.wim") { return "wim" }
    if (Test-Path "$letter\sources\install.esd") { return "esd" }
    return $null
}

function Get-InstalledAppxPackages {
    <#
    .SYNOPSIS
        Enumerate provisioned AppX packages in a mounted WIM image.
    .PARAMETER MountPath
        Path where the WIM is mounted (e.g., "D:\scratchdir").
    .OUTPUTS
        Array of package name strings.
    #>
    param(
        [Parameter(Mandatory)][string]$MountPath
    )

    try {
        $output = & 'dism' '/English' "/image:$MountPath" '/Get-ProvisionedAppxPackages'
        $packages = $output | ForEach-Object {
            if ($_ -match 'PackageName : (.*)') {
                $matches[1].Trim()
            }
        }
        return ($packages | Where-Object { $_ })
    } catch {
        Write-Error "Failed to enumerate AppX packages: $_"
        return @()
    }
}

function Test-CatalogAgainstImage {
    <#
    .SYNOPSIS
        Cross-reference catalog items with what's installed in the mounted image.
    .PARAMETER CatalogItems
        Array of catalog item objects (from catalog.json).
    .PARAMETER MountPath
        Path where WIM is mounted.
    .OUTPUTS
        Array of items with added 'present' boolean property.
    #>
    param(
        [Parameter(Mandatory)][array]$CatalogItems,
        [Parameter(Mandatory)][string]$MountPath
    )

    # Get installed packages once
    $installedPackages = Get-InstalledAppxPackages -MountPath $MountPath

    foreach ($item in $CatalogItems) {
        switch ($item.type) {
            "appx" {
                $item | Add-Member -NotePropertyName "present" -NotePropertyValue (
                    $installedPackages | Where-Object { $_ -like "*$($item.package)*" }
                ) -Force
                $item.present = [bool]$item.present
            }
            "files" {
                $allPresent = $true
                foreach ($p in $item.paths) {
                    if (-not (Test-Path (Join-Path $MountPath $p))) {
                        $allPresent = $false
                        break
                    }
                }
                $item | Add-Member -NotePropertyName "present" -NotePropertyValue $allPresent -Force
            }
            default {
                # Registry, service, task items are always "applicable"
                $item | Add-Member -NotePropertyName "present" -NotePropertyValue $true -Force
            }
        }
    }

    return $CatalogItems
}

function Get-ImageLanguage {
    <#
    .SYNOPSIS
        Detect the default UI language of a mounted image.
    .PARAMETER MountPath
        Path where WIM is mounted.
    .OUTPUTS
        Language code string (e.g., "en-US") or $null.
    #>
    param(
        [Parameter(Mandatory)][string]$MountPath
    )

    try {
        $intlInfo = & dism /English /Get-Intl "/Image:$MountPath"
        $langLine = $intlInfo -split '\n' | Where-Object {
            $_ -match 'Default system UI language : ([a-zA-Z]{2}-[a-zA-Z]{2})'
        }
        if ($langLine) { return $Matches[1] }
    } catch {
        Write-Error "Failed to detect language: $_"
    }
    return $null
}

function Get-ImageArchitecture {
    <#
    .SYNOPSIS
        Detect the architecture of a WIM image.
    .PARAMETER WimPath
        Path to the WIM file.
    .PARAMETER Index
        Image index to inspect.
    .OUTPUTS
        Architecture string (e.g., "amd64", "arm64").
    #>
    param(
        [Parameter(Mandatory)][string]$WimPath,
        [Parameter(Mandatory)][int]$Index
    )

    try {
        $info = & 'dism' '/English' '/Get-WimInfo' "/wimFile:$WimPath" "/index:$Index"
        foreach ($line in ($info -split '\r?\n')) {
            if ($line -like '*Architecture : *') {
                $arch = ($line -replace 'Architecture : ', '').Trim()
                if ($arch -eq 'x64') { $arch = 'amd64' }
                return $arch
            }
        }
    } catch {
        Write-Error "Failed to detect architecture: $_"
    }
    return $null
}
