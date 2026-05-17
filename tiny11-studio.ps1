# tiny11-studio.ps1 — Main entry point for tiny11 Studio
# Modular Windows 11 Image Builder GUI

#Requires -Version 5.1

# Load WPF assemblies
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# Dot-source all library modules
. "$PSScriptRoot\lib\i18n.ps1"
. "$PSScriptRoot\lib\gui-theme.ps1"
. "$PSScriptRoot\lib\gui-steps.ps1"
. "$PSScriptRoot\lib\submodule-manager.ps1"
. "$PSScriptRoot\lib\scan-iso.ps1"
. "$PSScriptRoot\lib\build-engine.ps1"
. "$PSScriptRoot\lib\profile-manager.ps1"

# Initialize localization
Initialize-Language

# Load catalog
$script:catalog = Import-Catalog
$script:currentStep = 1
$script:buildMode = "regular"
$script:installType = "standard"
$script:selections = @{}
$script:mountedDrive = $null
$script:buildRunning = $false

# Build the main XAML window
$themeXaml = Get-ThemeXaml
$stepIndicator = Get-StepIndicatorXaml
$step1 = Get-Step1Xaml
$step2 = Get-Step2Xaml
$step3 = Get-Step3Xaml
$step4 = Get-Step4Xaml
$submodulePrompt = Get-SubmodulePromptXaml

$windowXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="tiny11 Studio" Width="820" Height="640"
        WindowStartupLocation="CenterScreen"
        Background="#1e1e2e" FontFamily="Segoe UI"
        MinWidth="700" MinHeight="550">
    <Window.Resources>
        $themeXaml
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Title Bar -->
        <Border Grid.Row="0" Background="#181825" Padding="16,10">
            <DockPanel>
                <StackPanel DockPanel.Dock="Right" Orientation="Horizontal">
                    <ComboBox x:Name="cmbLanguage" Width="100" Background="#313244"
                              Foreground="#cdd6f4" FontSize="11" BorderThickness="0"/>
                </StackPanel>
                <StackPanel>
                    <TextBlock x:Name="txtTitle" Text="tiny11 Studio" Foreground="#89b4fa"
                               FontSize="18" FontWeight="Bold"/>
                    <TextBlock x:Name="txtSubtitle" Text="Modular Windows 11 Image Builder"
                               Foreground="#a6adc8" FontSize="11"/>
                </StackPanel>
            </DockPanel>
        </Border>

        <!-- Step Indicator -->
        <Border Grid.Row="1" Padding="0,4">
            $stepIndicator
        </Border>

        <!-- Content Area -->
        <Grid Grid.Row="2">
            $submodulePrompt
            $step1
            $step2
            $step3
            $step4
        </Grid>

        <!-- Navigation Bar -->
        <Border Grid.Row="3" Background="#181825" Padding="16,10">
            <DockPanel x:Name="navBar">
                <Button x:Name="btnBack" Content="Back" DockPanel.Dock="Left"
                        Style="{StaticResource SecondaryButton}" Visibility="Collapsed"/>
                <Button x:Name="btnNext" Content="Next" DockPanel.Dock="Right"
                        Style="{StaticResource PrimaryButton}" HorizontalAlignment="Right"/>
                <TextBlock Text="" />
            </DockPanel>
        </Border>
    </Grid>
</Window>
"@

# Parse XAML and create window
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($windowXaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

# Find all named elements
$controls = @{}
$namedElements = @(
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
)

foreach ($name in $namedElements) {
    $controls[$name] = $window.FindName($name)
}

# ─── Helper Functions ───

function Update-StepIndicator {
    param([int]$Step)

    $dots = @($controls['stepDot1'], $controls['stepDot2'], $controls['stepDot3'], $controls['stepDot4'])
    $lines = @($controls['stepLine1'], $controls['stepLine2'], $controls['stepLine3'])

    for ($i = 0; $i -lt 4; $i++) {
        if ($i -lt $Step) {
            $dots[$i].Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#89b4fa")
            $dots[$i].Child.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#1e1e2e")
        } else {
            $dots[$i].Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#45475a")
            $dots[$i].Child.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#a6adc8")
        }
        if ($i -lt 3) {
            $lines[$i].Background = if ($i -lt ($Step - 1)) {
                [System.Windows.Media.BrushConverter]::new().ConvertFrom("#89b4fa")
            } else {
                [System.Windows.Media.BrushConverter]::new().ConvertFrom("#45475a")
            }
        }
    }
}

function Show-Step {
    param([int]$Step)

    $script:currentStep = $Step

    $controls['step1Panel'].Visibility = if ($Step -eq 1) { 'Visible' } else { 'Collapsed' }
    $controls['step2Panel'].Visibility = if ($Step -eq 2) { 'Visible' } else { 'Collapsed' }
    $controls['step3Panel'].Visibility = if ($Step -eq 3) { 'Visible' } else { 'Collapsed' }
    $controls['step4Panel'].Visibility = if ($Step -eq 4) { 'Visible' } else { 'Collapsed' }
    $controls['submodulePanel'].Visibility = 'Collapsed'

    $controls['btnBack'].Visibility = if ($Step -gt 1) { 'Visible' } else { 'Collapsed' }
    $controls['btnNext'].Visibility = if ($Step -lt 4) { 'Visible' } else { 'Collapsed' }

    Update-StepIndicator -Step $Step

    # Update summary on step 4
    if ($Step -eq 4) {
        Update-BuildSummary
    }
}

function Update-BuildSummary {
    $controls['txtSummarySource'].Text = $controls['txtIsoPath'].Text
    $controls['txtSummaryOutput'].Text = $controls['txtOutputPath'].Text
    $controls['txtSummaryMode'].Text = if ($script:buildMode -eq "regular") { "Regular (Serviceable)" } else { "Core (Maximum Reduction)" }
    $controls['txtSummaryMode'].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom(
        $(if ($script:buildMode -eq "regular") { "#94e2d5" } else { "#cba6f7" })
    )
    $removeCount = ($script:selections.Values | Where-Object { $_ -eq $true }).Count
    $controls['txtSummaryCount'].Text = "$removeCount items"
}

function Initialize-Selections {
    $script:selections = @{}
    foreach ($category in $script:catalog.categories) {
        foreach ($item in $category.items) {
            if ($item.mode -eq "core_only" -and $script:buildMode -ne "core") { continue }
            $script:selections[$item.id] = [bool]$item.default_remove
        }
    }
}

function Build-CategoryList {
    $controls['lstCategories'].Items.Clear()
    foreach ($category in $script:catalog.categories) {
        if ($category.items.Count -eq 0) { continue }
        $hasVisibleItems = $false
        foreach ($item in $category.items) {
            if ($item.mode -ne "core_only" -or $script:buildMode -eq "core") {
                $hasVisibleItems = $true
                break
            }
        }
        if (-not $hasVisibleItems) { continue }

        $li = New-Object System.Windows.Controls.ListBoxItem
        $li.Content = "$($category.icon) $($category.name)"
        $li.Tag = $category.id
        $li.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#cdd6f4")
        $li.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $li.Padding = [System.Windows.Thickness]::new(8, 6, 8, 6)
        $controls['lstCategories'].Items.Add($li)
    }

    # Select first category
    if ($controls['lstCategories'].Items.Count -gt 0) {
        $controls['lstCategories'].SelectedIndex = 0
    }
}

function Build-ItemsForCategory {
    param([string]$CategoryId)

    $controls['pnlItems'].Children.Clear()
    $searchText = $controls['txtSearch'].Text.ToLower()

    $category = $script:catalog.categories | Where-Object { $_.id -eq $CategoryId }
    if (-not $category) { return }

    foreach ($item in $category.items) {
        if ($item.mode -eq "core_only" -and $script:buildMode -ne "core") { continue }
        if ($searchText -and $item.name.ToLower() -notlike "*$searchText*" -and $item.description.ToLower() -notlike "*$searchText*") { continue }

        $panel = New-Object System.Windows.Controls.StackPanel
        $panel.Orientation = "Horizontal"
        $panel.Margin = [System.Windows.Thickness]::new(0, 3, 0, 3)

        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.IsChecked = if ($script:selections.ContainsKey($item.id)) { $script:selections[$item.id] } else { $item.default_remove }
        $cb.Tag = $item.id
        $cb.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)
        $cb.VerticalAlignment = "Center"

        $cb.Add_Checked({
            $id = $this.Tag
            $script:selections[$id] = $true
            Update-ItemCount
        })
        $cb.Add_Unchecked({
            $id = $this.Tag
            $script:selections[$id] = $false
            Update-ItemCount
        })

        $nameBlock = New-Object System.Windows.Controls.TextBlock
        $nameBlock.Text = $item.name
        $nameBlock.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#cdd6f4")
        $nameBlock.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $nameBlock.FontSize = 13
        $nameBlock.VerticalAlignment = "Center"
        $nameBlock.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)

        $descBlock = New-Object System.Windows.Controls.TextBlock
        $descBlock.Text = "- $($item.description)"
        $descBlock.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#a6adc8")
        $descBlock.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")
        $descBlock.FontSize = 11
        $descBlock.VerticalAlignment = "Center"
        $descBlock.Margin = [System.Windows.Thickness]::new(0, 0, 8, 0)

        # Risk badge
        $badge = New-Object System.Windows.Controls.Border
        $badge.CornerRadius = [System.Windows.CornerRadius]::new(4)
        $badge.Padding = [System.Windows.Thickness]::new(6, 2, 6, 2)
        $badge.VerticalAlignment = "Center"
        $badgeText = New-Object System.Windows.Controls.TextBlock
        $badgeText.FontSize = 10
        $badgeText.FontFamily = [System.Windows.Media.FontFamily]::new("Segoe UI")

        switch ($item.risk) {
            "safe" {
                $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#2d4a2d")
                $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#a6e3a1")
                $badgeText.Text = "Safe"
            }
            "moderate" {
                $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#4a4a2d")
                $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#f9e2af")
                $badgeText.Text = "Moderate"
            }
            "dangerous" {
                $badge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#4a2d2d")
                $badgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom("#f38ba8")
                $badgeText.Text = "Dangerous"
            }
        }
        $badge.Child = $badgeText

        $panel.Children.Add($cb)
        $panel.Children.Add($nameBlock)
        $panel.Children.Add($descBlock)
        $panel.Children.Add($badge)
        $controls['pnlItems'].Children.Add($panel)
    }
}

function Update-ItemCount {
    $removeCount = ($script:selections.Values | Where-Object { $_ -eq $true }).Count
    $totalCount = $script:selections.Count
    $controls['txtItemCount'].Text = "$removeCount of $totalCount items selected for removal"
}

function Add-LogMessage {
    param([string]$Message)
    $controls['txtLog'].Dispatcher.Invoke([action]{
        $controls['txtLog'].AppendText("$Message`r`n")
        $controls['txtLog'].ScrollToEnd()
    })
}

# ─── Card Selection Helpers ───

function Set-CardSelected {
    param($Card, [string]$AccentColor)
    $Card.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom($AccentColor)
    $Card.Tag = "selected"
}

function Set-CardUnselected {
    param($Card)
    $Card.BorderBrush = [System.Windows.Media.Brushes]::Transparent
    $Card.Tag = $null
}

# ─── Event Wiring ───

# Language selector
$languages = Get-AvailableLanguages
foreach ($lang in $languages) {
    $controls['cmbLanguage'].Items.Add($lang.Name) | Out-Null
}
$currentLang = Get-CurrentLanguage
$langIndex = switch ($currentLang) { "en" { 0 } "pt-br" { 1 } "es" { 2 } default { 0 } }
if ($langIndex -lt $controls['cmbLanguage'].Items.Count) {
    $controls['cmbLanguage'].SelectedIndex = $langIndex
}

# Navigation buttons
$controls['btnNext'].Add_Click({
    if ($script:currentStep -lt 4) {
        if ($script:currentStep -eq 1) {
            if (-not $controls['txtIsoPath'].Text -or $controls['txtIsoPath'].Text -eq "Select a Windows 11 ISO file...") {
                [System.Windows.MessageBox]::Show("Please select a Windows 11 ISO file.", "tiny11 Studio", "OK", "Warning")
                return
            }
        }
        if ($script:currentStep -eq 2) {
            Initialize-Selections
            Build-CategoryList
        }
        Show-Step ($script:currentStep + 1)
    }
})

$controls['btnBack'].Add_Click({
    if ($script:currentStep -gt 1) {
        Show-Step ($script:currentStep - 1)
    }
})

# Step 1: Browse buttons
$controls['btnBrowseIso'].Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "ISO Files (*.iso)|*.iso|All Files (*.*)|*.*"
    $dlg.Title = "Select Windows 11 ISO"
    if ($dlg.ShowDialog() -eq "OK") {
        $controls['txtIsoPath'].Text = $dlg.FileName

        # Mount ISO and populate editions
        $controls['cmbEdition'].Items.Clear()
        $controls['cmbEdition'].IsEnabled = $false

        try {
            $drive = Mount-IsoImage -Path $dlg.FileName
            if ($drive) {
                $script:mountedDrive = $drive
                $editions = Get-IsoEditions -DriveLetter $drive
                foreach ($ed in $editions) {
                    $controls['cmbEdition'].Items.Add("$($ed.Index): $($ed.Name)") | Out-Null
                }
                if ($controls['cmbEdition'].Items.Count -gt 0) {
                    $controls['cmbEdition'].SelectedIndex = 0
                    $controls['cmbEdition'].IsEnabled = $true
                }
            }
        } catch {
            [System.Windows.MessageBox]::Show("Failed to mount ISO: $_", "Error", "OK", "Error")
        }
    }
})

$controls['btnBrowseScratch'].Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select scratch directory"
    if ($dlg.ShowDialog() -eq "OK") {
        $controls['txtScratchDir'].Text = $dlg.SelectedPath
    }
})

$controls['btnBrowseOutput'].Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "ISO Files (*.iso)|*.iso"
    $dlg.FileName = "tiny11.iso"
    $dlg.Title = "Save output ISO"
    if ($dlg.ShowDialog() -eq "OK") {
        $controls['txtOutputPath'].Text = $dlg.FileName
    }
})

# Step 2: Mode selection
$controls['cardRegular'].Add_MouseLeftButtonDown({
    Set-CardSelected $controls['cardRegular'] "#94e2d5"
    Set-CardUnselected $controls['cardCore']
    $script:buildMode = "regular"
})

$controls['cardCore'].Add_MouseLeftButtonDown({
    Set-CardSelected $controls['cardCore'] "#cba6f7"
    Set-CardUnselected $controls['cardRegular']
    $script:buildMode = "core"
})

# Step 3: Install type selection
$controls['cardStandard'].Add_MouseLeftButtonDown({
    Set-CardSelected $controls['cardStandard'] "#89b4fa"
    Set-CardUnselected $controls['cardCustom']
    $controls['customPanel'].Visibility = "Collapsed"
    $script:installType = "standard"
})

$controls['cardCustom'].Add_MouseLeftButtonDown({
    Set-CardSelected $controls['cardCustom'] "#89b4fa"
    Set-CardUnselected $controls['cardStandard']
    $controls['customPanel'].Visibility = "Visible"
    $script:installType = "custom"
    Update-ItemCount
})

# Category list selection changed
$controls['lstCategories'].Add_SelectionChanged({
    $selected = $controls['lstCategories'].SelectedItem
    if ($selected) {
        Build-ItemsForCategory -CategoryId $selected.Tag
    }
})

# Search filter
$controls['txtSearch'].Add_TextChanged({
    $selected = $controls['lstCategories'].SelectedItem
    if ($selected) {
        Build-ItemsForCategory -CategoryId $selected.Tag
    }
})

# Select All / Deselect All
$controls['btnSelectAll'].Add_Click({
    foreach ($key in @($script:selections.Keys)) {
        $script:selections[$key] = $true
    }
    $selected = $controls['lstCategories'].SelectedItem
    if ($selected) { Build-ItemsForCategory -CategoryId $selected.Tag }
    Update-ItemCount
})

$controls['btnDeselectAll'].Add_Click({
    foreach ($key in @($script:selections.Keys)) {
        $script:selections[$key] = $false
    }
    $selected = $controls['lstCategories'].SelectedItem
    if ($selected) { Build-ItemsForCategory -CategoryId $selected.Tag }
    Update-ItemCount
})

# Load / Save Profile
$controls['btnLoadProfile'].Add_Click({
    $dlg = New-Object System.Windows.Forms.OpenFileDialog
    $dlg.Filter = "JSON Profile (*.json)|*.json"
    $dlg.InitialDirectory = Join-Path $PSScriptRoot "profiles"
    if ($dlg.ShowDialog() -eq "OK") {
        $profile = Import-Profile -Path $dlg.FileName
        if ($profile) {
            $merged = Merge-ProfileWithCatalog -Profile $profile -Catalog $script:catalog -BuildMode $script:buildMode
            $script:selections = $merged
            $selected = $controls['lstCategories'].SelectedItem
            if ($selected) { Build-ItemsForCategory -CategoryId $selected.Tag }
            Update-ItemCount
        }
    }
})

$controls['btnSaveProfile'].Add_Click({
    $dlg = New-Object System.Windows.Forms.SaveFileDialog
    $dlg.Filter = "JSON Profile (*.json)|*.json"
    $dlg.InitialDirectory = Join-Path $PSScriptRoot "profiles"
    if ($dlg.ShowDialog() -eq "OK") {
        Save-Profile -Name (Split-Path $dlg.FileName -LeafBase) -Mode $script:buildMode -Selections $script:selections -Path $dlg.FileName
        [System.Windows.MessageBox]::Show("Profile saved!", "tiny11 Studio", "OK", "Information")
    }
})

# Step 4: Build button
$controls['btnStartBuild'].Add_Click({
    if ($script:buildRunning) { return }
    $script:buildRunning = $true
    $controls['btnStartBuild'].IsEnabled = $false
    $controls['btnCancelBuild'].IsEnabled = $true
    $controls['btnBack'].IsEnabled = $false
    $controls['txtLog'].Text = ""

    # Gather selected items from catalog
    $selectedItems = @()
    foreach ($category in $script:catalog.categories) {
        foreach ($item in $category.items) {
            if ($script:selections.ContainsKey($item.id) -and $script:selections[$item.id]) {
                $selectedItems += $item
            }
        }
    }

    # Get edition index from combobox
    $editionText = $controls['cmbEdition'].SelectedItem
    $editionIndex = 1
    if ($editionText -match '^(\d+):') { $editionIndex = [int]$Matches[1] }

    $scratchDir = $controls['txtScratchDir'].Text
    if (-not $scratchDir) { $scratchDir = $PSScriptRoot }

    $outputPath = $controls['txtOutputPath'].Text
    if (-not [System.IO.Path]::IsPathRooted($outputPath)) {
        $outputPath = Join-Path $PSScriptRoot $outputPath
    }

    Add-LogMessage "Starting tiny11 Studio build..."
    Add-LogMessage "Mode: $($script:buildMode) | Items: $($selectedItems.Count) | Output: $outputPath"
    Add-LogMessage "─────────────────────────────────────────"

    # Run build in background
    $result = Start-Tiny11Build `
        -SourceDrive $script:mountedDrive `
        -EditionIndex $editionIndex `
        -SelectedItems $selectedItems `
        -OutputPath $outputPath `
        -ScratchDir $scratchDir `
        -BuildMode $script:buildMode `
        -OnProgress {
            param($phase, $step, $total, $msg)
            $controls['progressBar'].Dispatcher.Invoke([action]{
                $pct = [math]::Round(($step / $total) * 100)
                $controls['progressBar'].Value = $pct
                $controls['txtPercent'].Text = "$pct%"
                $controls['txtPhase'].Text = $msg
            })
        } `
        -OnLog {
            param($msg)
            Add-LogMessage $msg
        }

    $script:buildRunning = $false
    $controls['btnCancelBuild'].IsEnabled = $false
    $controls['btnBack'].IsEnabled = $true

    if ($result.Success) {
        $controls['txtPhase'].Text = "Build Complete!"
        $controls['progressBar'].Value = 100
        $controls['txtPercent'].Text = "100%"
        $controls['btnOpenFolder'].Visibility = "Visible"
        Add-LogMessage "═══════════════════════════════════════"
        Add-LogMessage "BUILD COMPLETE! ISO saved to: $($result.OutputPath)"
    } else {
        $controls['txtPhase'].Text = "Build Failed"
        $controls['btnStartBuild'].IsEnabled = $true
        Add-LogMessage "═══════════════════════════════════════"
        Add-LogMessage "BUILD FAILED: $($result.Error)"
    }
})

$controls['btnOpenFolder'].Add_Click({
    $outputDir = Split-Path $controls['txtOutputPath'].Text -Parent
    if (-not $outputDir) { $outputDir = $PSScriptRoot }
    Start-Process explorer.exe $outputDir
})

# Submodule prompt buttons
$controls['btnCloneGithub'].Add_Click({
    $controls['txtSubmoduleStatus'].Text = "Cloning from GitHub..."
    $success = Initialize-SubmoduleFromGit
    if ($success) {
        $controls['submodulePanel'].Visibility = "Collapsed"
        Show-Step 1
    } else {
        $controls['txtSubmoduleStatus'].Text = "Clone failed. Check your internet connection."
    }
})

$controls['btnUseLocal'].Add_Click({
    $dlg = New-Object System.Windows.Forms.FolderBrowserDialog
    $dlg.Description = "Select your tiny11builder folder"
    if ($dlg.ShowDialog() -eq "OK") {
        $controls['txtSubmoduleStatus'].Text = "Copying scripts..."
        $success = Copy-LocalScripts -SourcePath $dlg.SelectedPath
        if ($success) {
            $controls['submodulePanel'].Visibility = "Collapsed"
            Show-Step 1
        } else {
            $controls['txtSubmoduleStatus'].Text = "Copy failed. Check the folder path."
        }
    }
})

# ─── Initial State ───

# Set default scratch directory
$controls['txtScratchDir'].Text = $PSScriptRoot

# Check if scripts are present
if (Test-SubmodulePresent) {
    $controls['submodulePanel'].Visibility = "Collapsed"
    Show-Step 1
} else {
    $controls['step1Panel'].Visibility = "Collapsed"
    $controls['submodulePanel'].Visibility = "Visible"
    $controls['btnNext'].IsEnabled = $false
    $controls['navBar'].Visibility = "Collapsed"
}

# Show window
$window.ShowDialog() | Out-Null

# Cleanup: dismount ISO if still mounted
if ($script:mountedDrive) {
    try { Dismount-IsoImage -DriveLetter $script:mountedDrive } catch {}
}
