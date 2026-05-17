# i18n.ps1 — Lightweight localization system for tiny11-studio
# Loads language strings from JSON files and provides Get-String function

$script:CurrentLanguage = $null
$script:Strings = @{}
$script:FallbackStrings = @{}

function Initialize-Language {
    <#
    .SYNOPSIS
        Detect system language and load corresponding strings file.
    .PARAMETER LangCode
        Optional language code override (e.g., "en", "pt-br", "es").
        If not provided, detects from system culture.
    #>
    param(
        [string]$LangCode
    )

    $langDir = Join-Path $PSScriptRoot "..\lang"

    # Check if running from AppData (compiled mode)
    $appDataLang = Join-Path $env:LOCALAPPDATA "tiny11-studio\lang"
    if (Test-Path $appDataLang) {
        $langDir = $appDataLang
    }

    # Always load English as fallback
    $enPath = Join-Path $langDir "en.json"
    if (Test-Path $enPath) {
        $script:FallbackStrings = Get-Content -Raw $enPath | ConvertFrom-Json
    }

    # Determine language
    if (-not $LangCode) {
        $culture = (Get-Culture).Name.ToLower()
        if ($culture -like "pt*") { $LangCode = "pt-br" }
        elseif ($culture -like "es*") { $LangCode = "es" }
        else { $LangCode = "en" }
    }

    $script:CurrentLanguage = $LangCode

    # Load target language
    $langPath = Join-Path $langDir "$LangCode.json"
    if (Test-Path $langPath) {
        $script:Strings = Get-Content -Raw $langPath | ConvertFrom-Json
    } else {
        $script:Strings = $script:FallbackStrings
        $script:CurrentLanguage = "en"
    }
}

function Get-String {
    <#
    .SYNOPSIS
        Get a localized string by key. Supports format placeholders.
    .PARAMETER Key
        The string key (e.g., "step1.title").
    .PARAMETER Args
        Optional format arguments for placeholders like {0}, {1}.
    .EXAMPLE
        Get-String "step3.items_selected" -Args 42
        # Returns: "42 items selected for removal"
    #>
    param(
        [Parameter(Mandatory)][string]$Key,
        [object[]]$Args
    )

    $value = $null

    # Try current language
    if ($script:Strings.PSObject.Properties.Match($Key).Count -gt 0) {
        $value = $script:Strings.$Key
    }
    # Fallback to English
    elseif ($script:FallbackStrings.PSObject.Properties.Match($Key).Count -gt 0) {
        $value = $script:FallbackStrings.$Key
    }
    # Key not found
    else {
        return "[$Key]"
    }

    # Apply format args if provided
    if ($Args -and $Args.Count -gt 0) {
        return [string]::Format($value, $Args)
    }

    return $value
}

function Set-Language {
    <#
    .SYNOPSIS
        Switch language at runtime.
    .PARAMETER Code
        Language code: "en", "pt-br", or "es".
    #>
    param(
        [Parameter(Mandatory)][string]$Code
    )
    Initialize-Language -LangCode $Code
}

function Get-AvailableLanguages {
    <#
    .SYNOPSIS
        List available language files.
    .OUTPUTS
        Array of hashtables with Code and Name properties.
    #>
    $langDir = Join-Path $PSScriptRoot "..\lang"
    $appDataLang = Join-Path $env:LOCALAPPDATA "tiny11-studio\lang"
    if (Test-Path $appDataLang) { $langDir = $appDataLang }

    $names = @{
        "en" = "English"
        "pt-br" = "Portugues (Brasil)"
        "es" = "Espanol"
    }

    $languages = @()
    Get-ChildItem -Path $langDir -Filter "*.json" | ForEach-Object {
        $code = $_.BaseName
        $languages += @{
            Code = $code
            Name = if ($names.ContainsKey($code)) { $names[$code] } else { $code }
        }
    }
    return $languages
}

function Get-CurrentLanguage {
    return $script:CurrentLanguage
}
