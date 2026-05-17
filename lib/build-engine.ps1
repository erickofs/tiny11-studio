# build-engine.ps1 — Core build orchestration engine
# Executes the actual ISO modification based on catalog selections

function Get-AdminGroup {
    <#
    .SYNOPSIS
        Get the local Administrators group name (works on any locale).
    #>
    $adminSID = New-Object System.Security.Principal.SecurityIdentifier("S-1-5-32-544")
    return $adminSID.Translate([System.Security.Principal.NTAccount]).Value
}

function Get-OscdimgPath {
    <#
    .SYNOPSIS
        Locate or download oscdimg.exe for ISO creation.
    .OUTPUTS
        Full path to oscdimg.exe.
    #>
    $hostArch = $Env:PROCESSOR_ARCHITECTURE
    $adkPath = "C:\Program Files (x86)\Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\$hostArch\Oscdimg\oscdimg.exe"

    if (Test-Path $adkPath) {
        return $adkPath
    }

    $localPath = Join-Path $env:LOCALAPPDATA "tiny11-studio\oscdimg.exe"
    if (Test-Path $localPath) {
        return $localPath
    }

    # Download from Microsoft Symbol Server
    $url = "https://msdl.microsoft.com/download/symbols/oscdimg.exe/3D44737265000/oscdimg.exe"
    $parentDir = Split-Path $localPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
    }

    try {
        Invoke-WebRequest -Uri $url -OutFile $localPath
        if (Test-Path $localPath) { return $localPath }
    } catch {
        Write-Error "Failed to download oscdimg.exe: $_"
    }
    return $null
}

function Remove-AppxItem {
    <#
    .SYNOPSIS
        Remove a provisioned AppX package from mounted image.
    #>
    param(
        [Parameter(Mandatory)][string]$MountPath,
        [Parameter(Mandatory)]$Item,
        [scriptblock]$OnLog
    )

    $packages = & 'dism' '/English' "/image:$MountPath" '/Get-ProvisionedAppxPackages' |
        ForEach-Object { if ($_ -match 'PackageName : (.*)') { $matches[1].Trim() } }

    $matched = $packages | Where-Object { $_ -like "*$($Item.package)*" }
    foreach ($pkg in $matched) {
        if ($OnLog) { & $OnLog "Removing AppX: $($Item.name) ($pkg)" }
        & 'dism' '/English' "/image:$MountPath" '/Remove-ProvisionedAppxPackage' "/PackageName:$pkg" | Out-Null
    }
}

function Remove-FileItem {
    <#
    .SYNOPSIS
        Take ownership and remove files/directories from mounted image.
    #>
    param(
        [Parameter(Mandatory)][string]$MountPath,
        [Parameter(Mandatory)]$Item,
        [scriptblock]$OnLog
    )

    $adminGroup = Get-AdminGroup
    foreach ($relativePath in $Item.paths) {
        $fullPath = Join-Path $MountPath $relativePath
        if (Test-Path $fullPath) {
            if ($OnLog) { & $OnLog "Removing files: $relativePath" }
            & 'takeown' '/f' $fullPath '/r' 2>&1 | Out-Null
            & 'icacls' $fullPath '/grant' "$($adminGroup):(F)" '/T' '/C' 2>&1 | Out-Null
            Remove-Item -Path $fullPath -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Set-RegistryItem {
    <#
    .SYNOPSIS
        Apply registry tweaks to offline hives.
    #>
    param(
        [Parameter(Mandatory)]$Item,
        [scriptblock]$OnLog
    )

    if ($OnLog) { & $OnLog "Applying registry: $($Item.name)" }

    foreach ($op in $Item.operations) {
        $regPath = "HKLM\$($op.hive)\$($op.path)"

        if ($op.action -eq "delete" -or $op.type -eq "REG_DELETE") {
            & 'reg' 'delete' $regPath '/f' 2>&1 | Out-Null
        } else {
            & 'reg' 'add' $regPath '/v' $op.name '/t' $op.type '/d' "$($op.value)" '/f' 2>&1 | Out-Null
        }
    }
}

function Remove-ScheduledTaskItem {
    <#
    .SYNOPSIS
        Delete scheduled task definition files from mounted image.
    #>
    param(
        [Parameter(Mandatory)][string]$MountPath,
        [Parameter(Mandatory)]$Item,
        [scriptblock]$OnLog
    )

    $tasksBase = Join-Path $MountPath "Windows\System32\Tasks"
    $taskPath = Join-Path $tasksBase $Item.path

    if (Test-Path $taskPath) {
        if ($OnLog) { & $OnLog "Removing task: $($Item.name)" }
        Remove-Item -Path $taskPath -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Start-Tiny11Build {
    <#
    .SYNOPSIS
        Main build orchestration — the complete pipeline.
    .PARAMETER SourceDrive
        Drive letter of mounted ISO (e.g., "E:").
    .PARAMETER EditionIndex
        Image index to process.
    .PARAMETER SelectedItems
        Array of catalog items to apply (items marked for removal).
    .PARAMETER OutputPath
        Full path for the output ISO file.
    .PARAMETER ScratchDir
        Scratch directory for temp files.
    .PARAMETER BuildMode
        "regular" or "core".
    .PARAMETER OnProgress
        Scriptblock callback: param($phase, $step, $total, $message)
    .PARAMETER OnLog
        Scriptblock callback: param($message)
    #>
    param(
        [Parameter(Mandatory)][string]$SourceDrive,
        [Parameter(Mandatory)][int]$EditionIndex,
        [Parameter(Mandatory)][array]$SelectedItems,
        [Parameter(Mandatory)][string]$OutputPath,
        [Parameter(Mandatory)][string]$ScratchDir,
        [string]$BuildMode = "regular",
        [scriptblock]$OnProgress,
        [scriptblock]$OnLog
    )

    $adminGroup = Get-AdminGroup
    $totalSteps = 12
    $currentStep = 0

    function Report-Progress($phase, $msg) {
        $script:currentStep++
        if ($OnProgress) { & $OnProgress $phase $script:currentStep $totalSteps $msg }
        if ($OnLog) { & $OnLog "[$script:currentStep/$totalSteps] $msg" }
    }

    try {
        # Step 1: Prepare directories
        Report-Progress "prepare" "Creating working directories..."
        $workDir = Join-Path $ScratchDir "tiny11"
        $mountDir = Join-Path $ScratchDir "scratchdir"
        New-Item -ItemType Directory -Force -Path "$workDir\sources" | Out-Null
        New-Item -ItemType Directory -Force -Path $mountDir | Out-Null

        # Step 2: Copy ISO contents
        Report-Progress "copy" "Copying Windows image files..."
        Copy-Item -Path "$SourceDrive\*" -Destination $workDir -Recurse -Force | Out-Null

        # Step 3: Handle ESD conversion
        $wimPath = Join-Path $workDir "sources\install.wim"
        $esdPath = Join-Path $workDir "sources\install.esd"

        if ((Test-Path $esdPath) -and -not (Test-Path $wimPath)) {
            Report-Progress "convert" "Converting ESD to WIM..."
            Export-WindowsImage -SourceImagePath $esdPath -SourceIndex $EditionIndex `
                -DestinationImagePath $wimPath -CompressionType Maximum -CheckIntegrity
            Remove-Item $esdPath -Force -ErrorAction SilentlyContinue
        } else {
            Report-Progress "convert" "WIM format detected, skipping conversion."
            # Clean up ESD if both exist
            if (Test-Path $esdPath) {
                Set-ItemProperty -Path $esdPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                Remove-Item $esdPath -Force -ErrorAction SilentlyContinue
            }
        }

        # Step 4: Mount WIM
        Report-Progress "mount" "Mounting Windows image..."
        & takeown "/F" $wimPath | Out-Null
        & icacls $wimPath "/grant" "$($adminGroup):(F)" | Out-Null
        Set-ItemProperty -Path $wimPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
        Mount-WindowsImage -ImagePath $wimPath -Index $EditionIndex -Path $mountDir

        # Step 5: Detect image properties
        Report-Progress "detect" "Detecting image language and architecture..."
        $imageInfo = & 'dism' '/English' '/Get-WimInfo' "/wimFile:$wimPath" "/index:$EditionIndex"
        $architecture = "amd64"
        foreach ($line in ($imageInfo -split '\r?\n')) {
            if ($line -like '*Architecture : *') {
                $architecture = ($line -replace 'Architecture : ', '').Trim()
                if ($architecture -eq 'x64') { $architecture = 'amd64' }
                break
            }
        }

        # Step 6: Load offline registry hives
        Report-Progress "registry_load" "Loading offline registry hives..."
        reg load HKLM\zCOMPONENTS "$mountDir\Windows\System32\config\COMPONENTS" 2>&1 | Out-Null
        reg load HKLM\zDEFAULT "$mountDir\Windows\System32\config\default" 2>&1 | Out-Null
        reg load HKLM\zNTUSER "$mountDir\Users\Default\ntuser.dat" 2>&1 | Out-Null
        reg load HKLM\zSOFTWARE "$mountDir\Windows\System32\config\SOFTWARE" 2>&1 | Out-Null
        reg load HKLM\zSYSTEM "$mountDir\Windows\System32\config\SYSTEM" 2>&1 | Out-Null

        # Step 7: Process selected items
        Report-Progress "remove" "Applying $($SelectedItems.Count) modifications..."
        $itemCount = 0
        foreach ($item in $SelectedItems) {
            $itemCount++
            if ($OnLog) { & $OnLog "  [$itemCount/$($SelectedItems.Count)] Processing: $($item.name)" }

            switch ($item.type) {
                "appx"           { Remove-AppxItem -MountPath $mountDir -Item $item -OnLog $OnLog }
                "files"          { Remove-FileItem -MountPath $mountDir -Item $item -OnLog $OnLog }
                "registry"       { Set-RegistryItem -Item $item -OnLog $OnLog }
                "scheduled_task" { Remove-ScheduledTaskItem -MountPath $mountDir -Item $item -OnLog $OnLog }
                "service"        { Set-RegistryItem -Item $item -OnLog $OnLog }
                "composite"      {
                    if ($OnLog) { & $OnLog "  Composite item: $($item.name) — skipping (manual handling)" }
                }
                default {
                    if ($OnLog) { & $OnLog "  Unknown type: $($item.type) for $($item.name)" }
                }
            }
        }

        # Step 8: Copy autounattend.xml for OOBE bypass
        Report-Progress "autounattend" "Copying autounattend.xml for OOBE bypass..."
        $scriptsPath = Get-ScriptsPath
        $autoXml = Join-Path $scriptsPath "autounattend.xml"
        if (Test-Path $autoXml) {
            $sysprepDir = Join-Path $mountDir "Windows\System32\Sysprep"
            Copy-Item -Path $autoXml -Destination (Join-Path $sysprepDir "autounattend.xml") -Force | Out-Null
        }

        # Step 9: Unload registry and cleanup
        Report-Progress "registry_unload" "Unloading registry hives..."
        reg unload HKLM\zCOMPONENTS 2>&1 | Out-Null
        reg unload HKLM\zDEFAULT 2>&1 | Out-Null
        reg unload HKLM\zNTUSER 2>&1 | Out-Null
        reg unload HKLM\zSOFTWARE 2>&1 | Out-Null
        reg unload HKLM\zSYSTEM 2>&1 | Out-Null

        Report-Progress "cleanup" "Running DISM cleanup..."
        dism.exe /Image:$mountDir /Cleanup-Image /StartComponentCleanup /ResetBase 2>&1 | Out-Null

        # Step 10: Unmount and export
        Report-Progress "unmount" "Unmounting and exporting image..."
        Dismount-WindowsImage -Path $mountDir -Save

        $exportWim = Join-Path $workDir "sources\install2.wim"
        $compression = if ($BuildMode -eq "core") { "fast" } else { "recovery" }
        Dism.exe /Export-Image /SourceImageFile:"$wimPath" /SourceIndex:$EditionIndex `
            /DestinationImageFile:"$exportWim" /Compress:$compression
        Remove-Item $wimPath -Force | Out-Null
        Rename-Item $exportWim -NewName "install.wim" | Out-Null

        # Step 11: Process boot.wim (hardware bypasses)
        Report-Progress "boot" "Processing boot.wim for setup bypasses..."
        $bootWim = Join-Path $workDir "sources\boot.wim"
        if (Test-Path $bootWim) {
            & takeown "/F" $bootWim | Out-Null
            & icacls $bootWim "/grant" "$($adminGroup):(F)" | Out-Null
            Set-ItemProperty -Path $bootWim -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
            Mount-WindowsImage -ImagePath $bootWim -Index 2 -Path $mountDir

            reg load HKLM\zCOMPONENTS "$mountDir\Windows\System32\config\COMPONENTS" 2>&1 | Out-Null
            reg load HKLM\zDEFAULT "$mountDir\Windows\System32\config\default" 2>&1 | Out-Null
            reg load HKLM\zNTUSER "$mountDir\Users\Default\ntuser.dat" 2>&1 | Out-Null
            reg load HKLM\zSOFTWARE "$mountDir\Windows\System32\config\SOFTWARE" 2>&1 | Out-Null
            reg load HKLM\zSYSTEM "$mountDir\Windows\System32\config\SYSTEM" 2>&1 | Out-Null

            # Apply HW bypass items to boot.wim
            $hwItems = $SelectedItems | Where-Object {
                $_.id -like "bypass_*" -or $_.id -eq "hw_notification"
            }
            foreach ($item in $hwItems) {
                if ($item.type -eq "registry") {
                    Set-RegistryItem -Item $item -OnLog $OnLog
                }
            }

            reg unload HKLM\zCOMPONENTS 2>&1 | Out-Null
            reg unload HKLM\zDEFAULT 2>&1 | Out-Null
            reg unload HKLM\zNTUSER 2>&1 | Out-Null
            reg unload HKLM\zSOFTWARE 2>&1 | Out-Null
            reg unload HKLM\zSYSTEM 2>&1 | Out-Null

            Dismount-WindowsImage -Path $mountDir -Save
        }

        # Step 12: Create ISO
        Report-Progress "iso" "Creating final ISO image..."
        $oscdimg = Get-OscdimgPath
        if (-not $oscdimg) {
            throw "oscdimg.exe not found. Please install Windows ADK."
        }

        # Copy autounattend.xml to ISO root for OOBE bypass
        if (Test-Path $autoXml) {
            Copy-Item -Path $autoXml -Destination "$workDir\autounattend.xml" -Force | Out-Null
        }

        & "$oscdimg" '-m' '-o' '-u2' '-udfver102' `
            "-bootdata:2#p0,e,b$workDir\boot\etfsboot.com#pEF,e,b$workDir\efi\microsoft\boot\efisys.bin" `
            "$workDir" "$OutputPath"

        if ($OnLog) { & $OnLog "Build complete! ISO saved to: $OutputPath" }

        # Cleanup
        Remove-Item -Path $workDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $mountDir -Recurse -Force -ErrorAction SilentlyContinue

        return @{ Success = $true; OutputPath = $OutputPath }

    } catch {
        if ($OnLog) { & $OnLog "ERROR: $_" }

        # Emergency cleanup
        reg unload HKLM\zCOMPONENTS 2>&1 | Out-Null
        reg unload HKLM\zDEFAULT 2>&1 | Out-Null
        reg unload HKLM\zNTUSER 2>&1 | Out-Null
        reg unload HKLM\zSOFTWARE 2>&1 | Out-Null
        reg unload HKLM\zSYSTEM 2>&1 | Out-Null

        try { Dismount-WindowsImage -Path $mountDir -Discard -ErrorAction SilentlyContinue } catch {}

        return @{ Success = $false; Error = $_.ToString() }
    }
}
