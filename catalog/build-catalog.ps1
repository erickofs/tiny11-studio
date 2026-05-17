# build-catalog.ps1 - Assembles catalog.json
# Uses ASCII icons to avoid encoding issues

$catalog = @{
    version = "1.0.0"
    categories = @()
}

# Load part 1 (bloatware apps) - fix icon
$part1 = Get-Content -Raw "catalog\catalog_part1.json" | ConvertFrom-Json
foreach ($cat in $part1.categories) { $cat.icon = "[PKG]" }
$catalog.categories += $part1.categories

$catalog.categories += @{
    id = "apps_microsoft"; name = "Microsoft Apps"; icon = "[MS]"
    description = "Core Microsoft applications"
    items = @(
        @{id="edge";name="Microsoft Edge";description="Web browser and WebView";type="files";paths=@("Program Files (x86)\Microsoft\Edge","Program Files (x86)\Microsoft\EdgeUpdate","Program Files (x86)\Microsoft\EdgeCore","Windows\System32\Microsoft-Edge-Webview");risk="moderate";reversible=$false;default_remove=$true;mode="both";notes="Remnants in Settings"}
        @{id="onedrive";name="OneDrive";description="Cloud storage setup";type="files";paths=@("Windows\System32\OneDriveSetup.exe");risk="moderate";reversible=$false;default_remove=$true;mode="both";notes="arm64 may not have this file"}
        @{id="outlook";name="Outlook (New)";description="New Outlook for Windows";type="appx";package="Microsoft.OutlookForWindows";risk="safe";reversible=$true;default_remove=$true;mode="both";notes="May reappear"}
        @{id="teams";name="Microsoft Teams";description="Communication platform";type="appx";package="MSTeams";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
        @{id="copilot_app";name="Copilot";description="AI assistant app";type="appx";package="Microsoft.Copilot";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
        @{id="copilot_win";name="Windows Copilot";description="Integrated Copilot";type="appx";package="Microsoft.Windows.Copilot";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
        @{id="devhome";name="Dev Home";description="Developer dashboard";type="appx";package="Microsoft.Windows.DevHome";risk="safe";reversible=$true;default_remove=$true;mode="both";notes="May reappear"}
        @{id="gaming_app";name="Gaming App";description="Xbox Gaming portal";type="appx";package="Microsoft.GamingApp";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
    )
}

$catalog.categories += @{
    id = "apps_xbox"; name = "Xbox and Gaming"; icon = "[XBOX]"
    description = "Xbox services and gaming overlays"
    items = @(
        @{id="xbox_tcui";name="Xbox TCUI";description="Xbox text/chat UI";type="appx";package="Microsoft.Xbox.TCUI";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
        @{id="xbox_app";name="Xbox App";description="Xbox companion";type="appx";package="Microsoft.XboxApp";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
        @{id="xbox_overlay";name="Xbox Game Overlay";description="In-game overlay";type="appx";package="Microsoft.XboxGameOverlay";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
        @{id="xbox_gaming_overlay";name="Xbox Gaming Overlay";description="Game Bar";type="appx";package="Microsoft.XboxGamingOverlay";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
        @{id="xbox_identity";name="Xbox Identity Provider";description="Xbox auth";type="appx";package="Microsoft.XboxIdentityProvider";risk="moderate";reversible=$true;default_remove=$true;mode="both";notes="Needed for Xbox reinstall"}
        @{id="xbox_speech";name="Xbox Speech to Text";description="Game speech";type="appx";package="Microsoft.XboxSpeechToTextOverlay";risk="safe";reversible=$true;default_remove=$true;mode="both";notes=""}
    )
}

$catalog.categories += @{
    id = "telemetry"; name = "Telemetry and Ads"; icon = "[TEL]"
    description = "Tracking, advertising, and data collection"
    items = @(
        @{id="advertising_id";name="Advertising ID";description="Disable advertising identifier";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zNTUSER";path="Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo";name="Enabled";value=0;type="REG_DWORD"})}
        @{id="tailored_exp";name="Tailored Experiences";description="Disable personalized tips";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zNTUSER";path="Software\Microsoft\Windows\CurrentVersion\Privacy";name="TailoredExperiencesWithDiagnosticDataEnabled";value=0;type="REG_DWORD"})}
        @{id="online_speech";name="Online Speech";description="Disable cloud speech";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zNTUSER";path="Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy";name="HasAccepted";value=0;type="REG_DWORD"})}
        @{id="telemetry_policy";name="Windows Telemetry";description="Disable telemetry";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Policies\Microsoft\Windows\DataCollection";name="AllowTelemetry";value=0;type="REG_DWORD"})}
        @{id="dmwappush";name="Push Notifications Service";description="Disable WAP push";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSYSTEM";path="ControlSet001\Services\dmwappushservice";name="Start";value=4;type="REG_DWORD"})}
        @{id="sponsored_apps";name="Sponsored Apps";description="Disable suggestions and ads";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zNTUSER";path="SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager";name="OemPreInstalledAppsEnabled";value=0;type="REG_DWORD"},@{hive="zNTUSER";path="SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager";name="PreInstalledAppsEnabled";value=0;type="REG_DWORD"},@{hive="zNTUSER";path="SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager";name="SilentInstalledAppsEnabled";value=0;type="REG_DWORD"},@{hive="zSOFTWARE";path="Policies\Microsoft\Windows\CloudContent";name="DisableWindowsConsumerFeatures";value=1;type="REG_DWORD"},@{hive="zSOFTWARE";path="Policies\Microsoft\PushToInstall";name="DisablePushToInstall";value=1;type="REG_DWORD"})}
    )
}

$catalog.categories += @{
    id = "hw_bypass"; name = "Hardware Bypasses"; icon = "[HW]"
    description = "Skip TPM, CPU, RAM, Secure Boot checks"
    items = @(
        @{id="bypass_tpm";name="TPM Bypass";description="Skip TPM requirement";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSYSTEM";path="Setup\LabConfig";name="BypassTPMCheck";value=1;type="REG_DWORD"})}
        @{id="bypass_cpu";name="CPU Bypass";description="Skip CPU check";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSYSTEM";path="Setup\LabConfig";name="BypassCPUCheck";value=1;type="REG_DWORD"})}
        @{id="bypass_ram";name="RAM Bypass";description="Skip RAM check";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSYSTEM";path="Setup\LabConfig";name="BypassRAMCheck";value=1;type="REG_DWORD"})}
        @{id="bypass_secureboot";name="Secure Boot Bypass";description="Skip Secure Boot";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSYSTEM";path="Setup\LabConfig";name="BypassSecureBootCheck";value=1;type="REG_DWORD"})}
        @{id="bypass_storage";name="Storage Bypass";description="Skip storage check";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSYSTEM";path="Setup\LabConfig";name="BypassStorageCheck";value=1;type="REG_DWORD"})}
        @{id="bypass_upgrade";name="Unsupported Upgrade";description="Allow upgrade on unsupported HW";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSYSTEM";path="Setup\MoSetup";name="AllowUpgradesWithUnsupportedTPMOrCPU";value=1;type="REG_DWORD"})}
    )
}

$catalog.categories += @{
    id = "oobe_bypass"; name = "OOBE Bypasses"; icon = "[OOBE]"
    description = "Skip MS Account and network requirements"
    items = @(
        @{id="bypass_nro";name="Local Account (BypassNRO)";description="Enable local account on OOBE";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Microsoft\Windows\CurrentVersion\OOBE";name="BypassNRO";value=1;type="REG_DWORD"})}
    )
}

$catalog.categories += @{
    id = "features_disable"; name = "Features to Disable"; icon = "[OFF]"
    description = "Disable built-in Windows features"
    items = @(
        @{id="reserved_storage";name="Reserved Storage";description="Disable reserved storage";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Microsoft\Windows\CurrentVersion\ReserveManager";name="ShippedWithReserves";value=0;type="REG_DWORD"})}
        @{id="bitlocker";name="BitLocker Auto-Encryption";description="Prevent auto encryption";type="registry";risk="moderate";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSYSTEM";path="ControlSet001\Control\BitLocker";name="PreventDeviceEncryption";value=1;type="REG_DWORD"})}
        @{id="chat_icon";name="Chat Icon";description="Remove chat from taskbar";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Policies\Microsoft\Windows\Windows Chat";name="ChatIcon";value=3;type="REG_DWORD"},@{hive="zNTUSER";path="SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced";name="TaskbarMn";value=0;type="REG_DWORD"})}
        @{id="copilot_disable";name="Copilot Feature";description="Disable Windows Copilot";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Policies\Microsoft\Windows\WindowsCopilot";name="TurnOffWindowsCopilot";value=1;type="REG_DWORD"})}
        @{id="search_suggestions";name="Search Suggestions";description="Disable search box suggestions";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Policies\Microsoft\Windows\Explorer";name="DisableSearchBoxSuggestions";value=1;type="REG_DWORD"})}
        @{id="onedrive_backup";name="OneDrive Backup";description="Disable OneDrive sync";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Policies\Microsoft\Windows\OneDrive";name="DisableFileSyncNGSC";value=1;type="REG_DWORD"})}
    )
}

$catalog.categories += @{
    id = "prevent_reinstall"; name = "Prevent Reinstallation"; icon = "[LOCK]"
    description = "Stop removed apps from being reinstalled"
    items = @(
        @{id="prevent_outlook";name="Prevent Outlook";description="Block Outlook reinstall";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate";name="workCompleted";value=1;type="REG_DWORD"},@{hive="zSOFTWARE";path="Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate";name="workCompleted";value=1;type="REG_DWORD"})}
        @{id="prevent_devhome";name="Prevent Dev Home";description="Block Dev Home reinstall";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate";name="workCompleted";value=1;type="REG_DWORD"})}
        @{id="prevent_teams";name="Prevent Teams";description="Block Teams reinstall";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Policies\Microsoft\Teams";name="DisableInstallation";value=1;type="REG_DWORD"})}
        @{id="prevent_new_outlook";name="Prevent New Outlook";description="Block new mail client";type="registry";risk="safe";reversible=$true;default_remove=$true;mode="both";operations=@(@{hive="zSOFTWARE";path="Policies\Microsoft\Windows\Windows Mail";name="PreventRun";value=1;type="REG_DWORD"})}
    )
}

$catalog.categories += @{
    id = "scheduled_tasks"; name = "Scheduled Tasks"; icon = "[TASK]"
    description = "Remove telemetry scheduled tasks"
    items = @(
        @{id="task_appraiser";name="Compatibility Appraiser";description="Telemetry collector";type="scheduled_task";path="Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser";risk="safe";reversible=$false;default_remove=$true;mode="both";notes=""}
        @{id="task_ceip";name="CEIP Tasks";description="Customer Experience Program";type="scheduled_task";path="Microsoft\Windows\Customer Experience Improvement Program";risk="safe";reversible=$false;default_remove=$true;mode="both";notes="Removes folder"}
        @{id="task_programdata";name="ProgramData Updater";description="App telemetry updater";type="scheduled_task";path="Microsoft\Windows\Application Experience\ProgramDataUpdater";risk="safe";reversible=$false;default_remove=$true;mode="both";notes=""}
        @{id="task_chkdsk";name="Chkdsk Proxy";description="Disk check proxy";type="scheduled_task";path="Microsoft\Windows\Chkdsk\Proxy";risk="safe";reversible=$false;default_remove=$true;mode="both";notes=""}
        @{id="task_wer";name="Error Reporting";description="Error reporting queue";type="scheduled_task";path="Microsoft\Windows\Windows Error Reporting\QueueReporting";risk="safe";reversible=$false;default_remove=$true;mode="both";notes=""}
    )
}

$catalog.categories += @{
    id = "core_extras"; name = "Core Mode Extras"; icon = "[CORE]"
    description = "Aggressive removals for Core mode only (non-serviceable)"
    items = @(
        @{id="windows_defender";name="Windows Defender";description="Disable Defender services";type="service";risk="dangerous";reversible=$true;default_remove=$true;mode="core_only";notes="Can be re-enabled"}
        @{id="windows_update";name="Windows Update";description="Disable WU completely";type="service";risk="dangerous";reversible=$false;default_remove=$true;mode="core_only";notes="System cannot update"}
        @{id="winsxs";name="WinSxS Component Store";description="Remove component store";type="composite";risk="dangerous";reversible=$false;default_remove=$true;mode="core_only";notes="Non-serviceable"}
        @{id="winre";name="Recovery Environment";description="Remove WinRE";type="files";paths=@("Windows\System32\Recovery");risk="dangerous";reversible=$false;default_remove=$true;mode="core_only";notes="No recovery"}
    )
}

$json = $catalog | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText("$PWD\catalog\catalog.json", $json, [System.Text.Encoding]::UTF8)
Remove-Item -Path "catalog\catalog_part1.json" -Force -ErrorAction SilentlyContinue
$totalItems = ($catalog.categories | ForEach-Object { $_.items.Count } | Measure-Object -Sum).Sum
Write-Output "catalog.json created: $($catalog.categories.Count) categories, $totalItems items"
