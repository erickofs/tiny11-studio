# build.ps1 - Two-stage build pipeline for tiny11 Studio
# Stage 1: Merge all PS1 + XAML into a single script
# Stage 2: Compile with ps2exe to .exe

param(
    [switch]$SkipExe,
    [string]$OutputName = "tiny11-studio"
)

$ErrorActionPreference = "Stop"
$buildDir = Join-Path $PSScriptRoot "dist"
$mergedScript = Join-Path $buildDir "$OutputName.ps1"
$exePath = Join-Path $buildDir "$OutputName.exe"

Write-Host "=== tiny11 Studio Build Pipeline ===" -ForegroundColor Cyan
Write-Host ""

# Clean dist folder
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
New-Item -ItemType Directory -Force -Path $buildDir | Out-Null

# Stage 1: Merge
Write-Host "[1/2] Merging scripts..." -ForegroundColor Yellow

$header = @"
# tiny11-studio.ps1 - Merged build (auto-generated)
# Do not edit - regenerate with build.ps1
#Requires -Version 5.1

"@

# Read XAML and embed as variable
$xamlContent = Get-Content -Raw (Join-Path $PSScriptRoot "assets\window.xaml")
$xamlContent = $xamlContent -replace "'", "''"
$embeddedXaml = "`$script:EmbeddedXaml = @'`r`n$xamlContent`r`n'@`r`n"

# Embed catalog.json
$catalogContent = Get-Content -Raw (Join-Path $PSScriptRoot "catalog\catalog.json")
$catalogContent = $catalogContent -replace "'", "''"
$embeddedCatalog = "`$script:EmbeddedCatalog = @'`r`n$catalogContent`r`n'@`r`n"

# Embed language files
$langEmbed = ""
foreach ($langFile in (Get-ChildItem -Path (Join-Path $PSScriptRoot "lang") -Filter "*.json")) {
    $langCode = $langFile.BaseName
    $langJson = Get-Content -Raw $langFile.FullName
    $langJson = $langJson -replace "'", "''"
    $langEmbed += "`$script:EmbeddedLang_$($langCode -replace '-','_') = @'`r`n$langJson`r`n'@`r`n"
}

# Embed profiles
$profileEmbed = ""
foreach ($pFile in (Get-ChildItem -Path (Join-Path $PSScriptRoot "profiles") -Filter "*.json")) {
    $pName = $pFile.BaseName
    $pJson = Get-Content -Raw $pFile.FullName
    $pJson = $pJson -replace "'", "''"
    $profileEmbed += "`$script:EmbeddedProfile_$($pName -replace '-','_') = @'`r`n$pJson`r`n'@`r`n"
}

# Collect library scripts (order matters: dependencies first)
$libOrder = @(
    "i18n.ps1",
    "submodule-manager.ps1",
    "scan-iso.ps1",
    "profile-manager.ps1",
    "build-engine.ps1"
)

$libContent = ""
foreach ($lib in $libOrder) {
    $path = Join-Path $PSScriptRoot "lib\$lib"
    if (Test-Path $path) {
        $content = Get-Content -Raw $path
        # Remove dot-source lines and #Requires
        $content = $content -replace '^\. .*$', '' -replace '#Requires.*$', ''
        $libContent += "# --- $lib ---`r`n$content`r`n"
    }
}

# Read main script and modify for embedded mode
$mainContent = Get-Content -Raw (Join-Path $PSScriptRoot "tiny11-studio.ps1")
# Remove dot-source lines
$mainContent = $mainContent -replace '\. "\$PSScriptRoot\\lib\\[^"]+\.ps1"', '# (embedded)'
# Remove #Requires
$mainContent = $mainContent -replace '#Requires.*', ''
# Replace XAML file loading with embedded variable
$mainContent = $mainContent -replace '\$xamlPath = .*', '# Using embedded XAML'
$mainContent = $mainContent -replace '\$xamlContent = Get-Content -Raw \$xamlPath', '$xamlContent = $script:EmbeddedXaml'

# Assemble
$merged = $header + $embeddedXaml + "`r`n" + $embeddedCatalog + "`r`n" + $langEmbed + "`r`n" + $profileEmbed + "`r`n" + $libContent + "`r`n" + $mainContent

[System.IO.File]::WriteAllText($mergedScript, $merged, [System.Text.UTF8Encoding]::new($true))

$lineCount = ($merged -split "`n").Count
Write-Host "  Merged script: $mergedScript ($lineCount lines)" -ForegroundColor Green

if ($SkipExe) {
    Write-Host "[2/2] Skipping EXE compilation (-SkipExe)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Build complete! Output: $mergedScript" -ForegroundColor Green
    return
}

# Stage 2: Compile to EXE
Write-Host "[2/2] Compiling to EXE..." -ForegroundColor Yellow

# Check for ps2exe
if (-not (Get-Module -ListAvailable -Name ps2exe)) {
    Write-Host "  Installing ps2exe module..." -ForegroundColor DarkGray
    Install-Module ps2exe -Scope CurrentUser -Force
}

$iconPath = Join-Path $PSScriptRoot "assets\icon.ico"
$ps2exeParams = @{
    inputFile  = $mergedScript
    outputFile = $exePath
    noConsole  = $true
    title      = "tiny11 Studio"
    description = "Modular Windows 11 Image Builder"
    company    = "erickofs"
    version    = "1.0.0"
    copyright  = "MIT License"
    requireAdmin = $true
}

if (Test-Path $iconPath) {
    $ps2exeParams.iconFile = $iconPath
}

Invoke-ps2exe @ps2exeParams

if (Test-Path $exePath) {
    $size = [math]::Round((Get-Item $exePath).Length / 1MB, 1)
    Write-Host "  EXE created: $exePath ($size MB)" -ForegroundColor Green
} else {
    Write-Host "  EXE compilation failed!" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Build Complete ===" -ForegroundColor Cyan
