# tiny11-studio.ps1 - Main entry point for tiny11 Studio
# Modular Windows 11 Image Builder GUI

#Requires -Version 5.1

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Dot-source library modules
. "$PSScriptRoot\lib\i18n.ps1"
. "$PSScriptRoot\lib\submodule-manager.ps1"
. "$PSScriptRoot\lib\scan-iso.ps1"
. "$PSScriptRoot\lib\build-engine.ps1"
. "$PSScriptRoot\lib\profile-manager.ps1"

Initialize-Language

# State
$script:catalog = Import-Catalog
$script:currentStep = 1
$script:buildMode = "regular"
$script:installType = "standard"
$script:selections = @{}
$script:mountedDrive = $null
$script:buildRunning = $false

# Load XAML from file
$xamlPath = Join-Path $PSScriptRoot "assets\window.xaml"
$xamlContent = Get-Content -Raw $xamlPath
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xamlContent))
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find all named controls
$c = @{}
@(
    'txtTitle','txtSubtitle','cmbLanguage',
    'stepDot1','stepDot2','stepDot3','stepDot4',
    'stepLine1','stepLine2','stepLine3',
    'step1Panel','step2Panel','step3Panel','step4Panel',
    'submodulePanel',
    'btnBrowseIso','txtIsoPath','cmbEdition',
    'btnBrowseScratch','txtScratchDir',
    'btnBrowseOutput','txtOutputPath',
    'cardRegular','cardCore',
    'cardStandard','cardCustom','customPanel',
    'btnSelectAll','btnDeselectAll','btnLoadProfile','btnSaveProfile',
    'txtSearch','lstCategories','pnlItems','txtItemCount',
    'txtSummarySource','txtSummaryMode','txtSummaryOutput','txtSummaryCount',
    'txtPhase','txtPercent','progressBar','txtLog',
    'btnStartBuild','btnCancelBuild','btnOpenFolder',
    'btnCloneGithub','btnUseLocal','txtSubmoduleStatus',
    'btnBack','btnNext','navBar'
) | ForEach-Object { $c[$_] = $window.FindName($_) }

# --- Helpers ---

$bc = [System.Windows.Media.BrushConverter]::new()

function Update-StepIndicator([int]$Step) {
    $dots = @($c.stepDot1, $c.stepDot2, $c.stepDot3, $c.stepDot4)
    $lines = @($c.stepLine1, $c.stepLine2, $c.stepLine3)
    for ($i = 0; $i -lt 4; $i++) {
        if ($i -lt $Step) {
            $dots[$i].Background = $bc.ConvertFrom("#89b4fa")
            $dots[$i].Child.Foreground = $bc.ConvertFrom("#1e1e2e")
        } else {
            $dots[$i].Background = $bc.ConvertFrom("#45475a")
            $dots[$i].Child.Foreground = $bc.ConvertFrom("#a6adc8")
        }
        if ($i -lt 3) {
            $lines[$i].Background = if ($i -lt ($Step - 1)) { $bc.ConvertFrom("#89b4fa") } else { $bc.ConvertFrom("#45475a") }
        }
    }
}

function Show-Step([int]$Step) {
    $script:currentStep = $Step
    $c.step1Panel.Visibility = if ($Step -eq 1) { 'Visible' } else { 'Collapsed' }
    $c.step2Panel.Visibility = if ($Step -eq 2) { 'Visible' } else { 'Collapsed' }
    $c.step3Panel.Visibility = if ($Step -eq 3) { 'Visible' } else { 'Collapsed' }
    $c.step4Panel.Visibility = if ($Step -eq 4) { 'Visible' } else { 'Collapsed' }
    $c.submodulePanel.Visibility = 'Collapsed'
    $c.btnBack.Visibility = if ($Step -gt 1) { 'Visible' } else { 'Collapsed' }
    $c.btnNext.Visibility = if ($Step -lt 4) { 'Visible' } else { 'Collapsed' }
    Update-StepIndicator $Step
    if ($Step -eq 4) { Update-BuildSummary }
}

function Update-BuildSummary {
    $c.txtSummarySource.Text = $c.txtIsoPath.Text
    $c.txtSummaryOutput.Text = $c.txtOutputPath.Text
    $c.txtSummaryMode.Text = if ($script:buildMode -eq "regular") { "Regular (Serviceable)" } else { "Core (Maximum Reduction)" }
    $c.txtSummaryMode.Foreground = $bc.ConvertFrom($(if ($script:buildMode -eq "regular") { "#94e2d5" } else { "#cba6f7" }))
    $removeCount = ($script:selections.Values | Where-Object { $_ -eq $true }).Count
    $c.txtSummaryCount.Text = "$removeCount items"
}

function Initialize-Selections {
    $script:selections = @{}
    foreach ($cat in $script:catalog.categories) {
        foreach ($item in $cat.items) {
            if ($item.mode -eq "core_only" -and $script:buildMode -ne "core") { continue }
            $script:selections[$item.id] = [bool]$item.default_remove
        }
    }
}

function Build-CategoryList {
    $c.lstCategories.Items.Clear()
    foreach ($cat in $script:catalog.categories) {
        $hasVisible = $false
        foreach ($item in $cat.items) {
            if ($item.mode -ne "core_only" -or $script:buildMode -eq "core") { $hasVisible = $true; break }
        }
        if (-not $hasVisible) { continue }
        $li = New-Object System.Windows.Controls.ListBoxItem
        $li.Content = "$($cat.icon) $($cat.name)"
        $li.Tag = $cat.id
        $li.Foreground = $bc.ConvertFrom("#cdd6f4")
        $li.Padding = [System.Windows.Thickness]::new(8, 6, 8, 6)
        $c.lstCategories.Items.Add($li) | Out-Null
    }
    if ($c.lstCategories.Items.Count -gt 0) { $c.lstCategories.SelectedIndex = 0 }
}

function Build-ItemsForCategory([string]$CategoryId) {
    $c.pnlItems.Children.Clear()
    $search = $c.txtSearch.Text.ToLower()
    $cat = $script:catalog.categories | Where-Object { $_.id -eq $CategoryId }
    if (-not $cat) { return }

    foreach ($item in $cat.items) {
        if ($item.mode -eq "core_only" -and $script:buildMode -ne "core") { continue }
        if ($search -and $item.name.ToLower() -notlike "*$search*" -and $item.description.ToLower() -notlike "*$search*") { continue }

        $panel = New-Object System.Windows.Controls.StackPanel
        $panel.Orientation = "Horizontal"
        $panel.Margin = [System.Windows.Thickness]::new(0, 3, 0, 3)

        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.IsChecked = if ($script:selections.ContainsKey($item.id)) { $script:selections[$item.id] } else { $item.default_remove }
        $cb.Tag = $item.id
        $cb.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $cb.VerticalAlignment = "Center"
        $cb.Add_Checked({ $script:selections[$this.Tag] = $true; Update-ItemCount })
        $cb.Add_Unchecked({ $script:selections[$this.Tag] = $false; Update-ItemCount })

        $nm = New-Object System.Windows.Controls.TextBlock
        $nm.Text = $item.name; $nm.Foreground = $bc.ConvertFrom("#cdd6f4"); $nm.FontSize = 13
        $nm.VerticalAlignment = "Center"; $nm.Margin = [System.Windows.Thickness]::new(0,0,8,0)

        $desc = New-Object System.Windows.Controls.TextBlock
        $desc.Text = "- $($item.description)"; $desc.Foreground = $bc.ConvertFrom("#a6adc8"); $desc.FontSize = 11
        $desc.VerticalAlignment = "Center"; $desc.Margin = [System.Windows.Thickness]::new(0,0,8,0)

        $badge = New-Object System.Windows.Controls.Border
        $badge.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $badge.Padding = [System.Windows.Thickness]::new(6, 2, 6, 2)
        $badge.VerticalAlignment = "Center"
        $bt = New-Object System.Windows.Controls.TextBlock; $bt.FontSize = 10
        switch ($item.risk) {
            "safe"      { $badge.Background = $bc.ConvertFrom("#2d4a2d"); $bt.Foreground = $bc.ConvertFrom("#a6e3a1"); $bt.Text = "Safe" }
            "moderate"  { $badge.Background = $bc.ConvertFrom("#4a4a2d"); $bt.Foreground = $bc.ConvertFrom("#f9e2af"); $bt.Text = "Moderate" }
            "dangerous" { $badge.Background = $bc.ConvertFrom("#4a2d2d"); $bt.Foreground = $bc.ConvertFrom("#f38ba8"); $bt.Text = "Dangerous" }
        }
        $badge.Child = $bt

        $panel.Children.Add($cb) | Out-Null
        $panel.Children.Add($nm) | Out-Null
        $panel.Children.Add($desc) | Out-Null
        $panel.Children.Add($badge) | Out-Null
        $c.pnlItems.Children.Add($panel) | Out-Null
    }
}

function Update-ItemCount {
    $rem = ($script:selections.Values | Where-Object { $_ }).Count
    $c.txtItemCount.Text = "$rem of $($script:selections.Count) items selected for removal"
}

function Add-Log([string]$msg) {
    $c.txtLog.Dispatcher.Invoke([action]{ $c.txtLog.AppendText("$msg`r`n"); $c.txtLog.ScrollToEnd() })
}

# --- Language ---
$languages = Get-AvailableLanguages
foreach ($lang in $languages) { $c.cmbLanguage.Items.Add($lang.Name) | Out-Null }
$li = switch (Get-CurrentLanguage) { "en" { 0 } "pt-br" { 1 } "es" { 2 } default { 0 } }
if ($li -lt $c.cmbLanguage.Items.Count) { $c.cmbLanguage.SelectedIndex = $li }

# --- Navigation ---
$c.btnNext.Add_Click({
    if ($script:currentStep -lt 4) {
        if ($script:currentStep -eq 1 -and (-not $c.txtIsoPath.Text -or $c.txtIsoPath.Text -eq "Select a Windows 11 ISO file...")) {
            [System.Windows.MessageBox]::Show("Please select a Windows 11 ISO file.", "tiny11 Studio", "OK", "Warning"); return
        }
        if ($script:currentStep -eq 2) { Initialize-Selections; Build-CategoryList }
        Show-Step ($script:currentStep + 1)
    }
})
$c.btnBack.Add_Click({ if ($script:currentStep -gt 1) { Show-Step ($script:currentStep - 1) } })

# --- Step 1: Browse ---
$c.btnBrowseIso.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "ISO Files (*.iso)|*.iso|All Files (*.*)|*.*"
    $dlg.Title = "Select Windows 11 ISO"
    if ($dlg.ShowDialog() -eq "OK") {
        $c.txtIsoPath.Text = $dlg.FileName
        $c.cmbEdition.Items.Clear(); $c.cmbEdition.IsEnabled = $false
        try {
            $drive = Mount-IsoImage -Path $dlg.FileName
            if ($drive) {
                $script:mountedDrive = $drive
                $editions = Get-IsoEditions -DriveLetter $drive
                foreach ($ed in $editions) { $c.cmbEdition.Items.Add("$($ed.Index): $($ed.Name)") | Out-Null }
                if ($c.cmbEdition.Items.Count -gt 0) { $c.cmbEdition.SelectedIndex = 0; $c.cmbEdition.IsEnabled = $true }
            }
        } catch { [System.Windows.MessageBox]::Show("Failed to mount ISO: $_", "Error", "OK", "Error") }
    }
})
$c.btnBrowseScratch.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog; $dlg.Description = "Select scratch directory"
    if ($dlg.ShowDialog() -eq "OK") { $c.txtScratchDir.Text = $dlg.SelectedPath }
})
$c.btnBrowseOutput.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog; $dlg.Filter = "ISO Files (*.iso)|*.iso"; $dlg.FileName = "tiny11.iso"
    if ($dlg.ShowDialog() -eq "OK") { $c.txtOutputPath.Text = $dlg.FileName }
})

# --- Step 2: Mode ---
$c.cardRegular.Add_MouseLeftButtonDown({ $c.cardRegular.BorderBrush = $bc.ConvertFrom("#94e2d5"); $c.cardCore.BorderBrush = [System.Windows.Media.Brushes]::Transparent; $script:buildMode = "regular" })
$c.cardCore.Add_MouseLeftButtonDown({ $c.cardCore.BorderBrush = $bc.ConvertFrom("#cba6f7"); $c.cardRegular.BorderBrush = [System.Windows.Media.Brushes]::Transparent; $script:buildMode = "core" })

# --- Step 3: Install Type ---
$c.cardStandard.Add_MouseLeftButtonDown({ $c.cardStandard.BorderBrush = $bc.ConvertFrom("#89b4fa"); $c.cardCustom.BorderBrush = [System.Windows.Media.Brushes]::Transparent; $c.customPanel.Visibility = "Collapsed"; $script:installType = "standard" })
$c.cardCustom.Add_MouseLeftButtonDown({ $c.cardCustom.BorderBrush = $bc.ConvertFrom("#89b4fa"); $c.cardStandard.BorderBrush = [System.Windows.Media.Brushes]::Transparent; $c.customPanel.Visibility = "Visible"; $script:installType = "custom"; Update-ItemCount })

$c.lstCategories.Add_SelectionChanged({ $sel = $c.lstCategories.SelectedItem; if ($sel) { Build-ItemsForCategory $sel.Tag } })
$c.txtSearch.Add_TextChanged({ $sel = $c.lstCategories.SelectedItem; if ($sel) { Build-ItemsForCategory $sel.Tag } })

$c.btnSelectAll.Add_Click({ foreach ($k in @($script:selections.Keys)) { $script:selections[$k] = $true }; $sel = $c.lstCategories.SelectedItem; if ($sel) { Build-ItemsForCategory $sel.Tag }; Update-ItemCount })
$c.btnDeselectAll.Add_Click({ foreach ($k in @($script:selections.Keys)) { $script:selections[$k] = $false }; $sel = $c.lstCategories.SelectedItem; if ($sel) { Build-ItemsForCategory $sel.Tag }; Update-ItemCount })

$c.btnLoadProfile.Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog; $dlg.Filter = "JSON Profile (*.json)|*.json"
    $dlg.InitialDirectory = Join-Path $PSScriptRoot "profiles"
    if ($dlg.ShowDialog() -eq "OK") {
        $p = Import-Profile -Path $dlg.FileName
        if ($p) { $script:selections = Merge-ProfileWithCatalog -Profile $p -Catalog $script:catalog -BuildMode $script:buildMode; $sel = $c.lstCategories.SelectedItem; if ($sel) { Build-ItemsForCategory $sel.Tag }; Update-ItemCount }
    }
})
$c.btnSaveProfile.Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog; $dlg.Filter = "JSON Profile (*.json)|*.json"
    $dlg.InitialDirectory = Join-Path $PSScriptRoot "profiles"
    if ($dlg.ShowDialog() -eq "OK") { Save-Profile -Name (Split-Path $dlg.FileName -LeafBase) -Mode $script:buildMode -Selections $script:selections -Path $dlg.FileName; [System.Windows.MessageBox]::Show("Profile saved!", "tiny11 Studio", "OK", "Information") }
})

# --- Step 4: Build ---
$c.btnStartBuild.Add_Click({
    if ($script:buildRunning) { return }
    $script:buildRunning = $true; $c.btnStartBuild.IsEnabled = $false; $c.btnCancelBuild.IsEnabled = $true; $c.btnBack.IsEnabled = $false; $c.txtLog.Text = ""
    $selectedItems = @()
    foreach ($cat in $script:catalog.categories) { foreach ($item in $cat.items) { if ($script:selections.ContainsKey($item.id) -and $script:selections[$item.id]) { $selectedItems += $item } } }
    $edText = $c.cmbEdition.SelectedItem; $edIdx = 1; if ($edText -match '^(\d+):') { $edIdx = [int]$Matches[1] }
    $scratch = $c.txtScratchDir.Text; if (-not $scratch) { $scratch = $PSScriptRoot }
    $out = $c.txtOutputPath.Text; if (-not [System.IO.Path]::IsPathRooted($out)) { $out = Join-Path $PSScriptRoot $out }

    Add-Log "Starting tiny11 Studio build..."
    Add-Log "Mode: $($script:buildMode) | Items: $($selectedItems.Count) | Output: $out"

    $result = Start-Tiny11Build -SourceDrive $script:mountedDrive -EditionIndex $edIdx -SelectedItems $selectedItems -OutputPath $out -ScratchDir $scratch -BuildMode $script:buildMode `
        -OnProgress { param($phase,$step,$total,$msg); $c.progressBar.Dispatcher.Invoke([action]{ $pct = [math]::Round(($step/$total)*100); $c.progressBar.Value = $pct; $c.txtPercent.Text = "$pct%"; $c.txtPhase.Text = $msg }) } `
        -OnLog { param($msg); Add-Log $msg }

    $script:buildRunning = $false; $c.btnCancelBuild.IsEnabled = $false; $c.btnBack.IsEnabled = $true
    if ($result.Success) { $c.txtPhase.Text = "Build Complete!"; $c.progressBar.Value = 100; $c.txtPercent.Text = "100%"; $c.btnOpenFolder.Visibility = "Visible"; Add-Log "BUILD COMPLETE! ISO: $($result.OutputPath)" }
    else { $c.txtPhase.Text = "Build Failed"; $c.btnStartBuild.IsEnabled = $true; Add-Log "BUILD FAILED: $($result.Error)" }
})

$c.btnOpenFolder.Add_Click({ $d = Split-Path $c.txtOutputPath.Text -Parent; if (-not $d) { $d = $PSScriptRoot }; Start-Process explorer.exe $d })

# --- Submodule ---
$c.btnCloneGithub.Add_Click({ $c.txtSubmoduleStatus.Text = "Cloning..."; $ok = Initialize-SubmoduleFromGit; if ($ok) { $c.submodulePanel.Visibility = "Collapsed"; $c.navBar.Visibility = "Visible"; Show-Step 1 } else { $c.txtSubmoduleStatus.Text = "Clone failed." } })
$c.btnUseLocal.Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog; $dlg.Description = "Select tiny11builder folder"
    if ($dlg.ShowDialog() -eq "OK") { $c.txtSubmoduleStatus.Text = "Copying..."; $ok = Copy-LocalScripts -SourcePath $dlg.SelectedPath; if ($ok) { $c.submodulePanel.Visibility = "Collapsed"; $c.navBar.Visibility = "Visible"; Show-Step 1 } else { $c.txtSubmoduleStatus.Text = "Copy failed." } }
})

# --- Init ---
$c.txtScratchDir.Text = $PSScriptRoot
if (Test-SubmodulePresent) { $c.submodulePanel.Visibility = "Collapsed"; Show-Step 1 }
else { $c.step1Panel.Visibility = "Collapsed"; $c.submodulePanel.Visibility = "Visible"; $c.btnNext.IsEnabled = $false; $c.navBar.Visibility = "Collapsed" }

$window.ShowDialog() | Out-Null
if ($script:mountedDrive) { try { Dismount-IsoImage -DriveLetter $script:mountedDrive } catch {} }
