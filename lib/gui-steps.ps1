# gui-steps.ps1 â€” XAML builders for each wizard step
# Each function returns a XAML string for a wizard panel

function Get-StepIndicatorXaml {
    <#
    .SYNOPSIS
        Returns XAML for the step progress indicator bar at the top.
    #>
    return @'
    <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,10,0,20">
        <Border x:Name="stepDot1" Width="32" Height="32" CornerRadius="16" Background="#89b4fa" Margin="0,0,4,0">
            <TextBlock Text="1" Foreground="#1e1e2e" FontWeight="Bold" FontSize="14"
                       HorizontalAlignment="Center" VerticalAlignment="Center" FontFamily="Segoe UI"/>
        </Border>
        <Border Width="40" Height="2" Background="#45475a" VerticalAlignment="Center" Margin="0,0,4,0"
                x:Name="stepLine1"/>
        <Border x:Name="stepDot2" Width="32" Height="32" CornerRadius="16" Background="#45475a" Margin="0,0,4,0">
            <TextBlock Text="2" Foreground="#a6adc8" FontWeight="Bold" FontSize="14"
                       HorizontalAlignment="Center" VerticalAlignment="Center" FontFamily="Segoe UI"/>
        </Border>
        <Border Width="40" Height="2" Background="#45475a" VerticalAlignment="Center" Margin="0,0,4,0"
                x:Name="stepLine2"/>
        <Border x:Name="stepDot3" Width="32" Height="32" CornerRadius="16" Background="#45475a" Margin="0,0,4,0">
            <TextBlock Text="3" Foreground="#a6adc8" FontWeight="Bold" FontSize="14"
                       HorizontalAlignment="Center" VerticalAlignment="Center" FontFamily="Segoe UI"/>
        </Border>
        <Border Width="40" Height="2" Background="#45475a" VerticalAlignment="Center" Margin="0,0,4,0"
                x:Name="stepLine3"/>
        <Border x:Name="stepDot4" Width="32" Height="32" CornerRadius="16" Background="#45475a" Margin="0,0,4,0">
            <TextBlock Text="4" Foreground="#a6adc8" FontWeight="Bold" FontSize="14"
                       HorizontalAlignment="Center" VerticalAlignment="Center" FontFamily="Segoe UI"/>
        </Border>
    </StackPanel>
'@
}

function Get-Step1Xaml {
    <#
    .SYNOPSIS
        Step 1: Source Configuration â€” ISO path, edition, scratch, output.
    #>
    return @'
    <StackPanel x:Name="step1Panel" Margin="20">
        <TextBlock Text="Source Configuration" Foreground="#cdd6f4" FontSize="22"
                   FontWeight="Bold" FontFamily="Segoe UI" Margin="0,0,0,4"/>
        <TextBlock Text="Configure your Windows 11 ISO source and output paths"
                   Foreground="#a6adc8" FontSize="13" FontFamily="Segoe UI" Margin="0,0,0,20"/>

        <!-- ISO File -->
        <TextBlock Text="Windows 11 ISO File" Foreground="#a6adc8" FontSize="12"
                   FontFamily="Segoe UI" Margin="0,0,0,4"/>
        <DockPanel Margin="0,0,0,16">
            <Button x:Name="btnBrowseIso" Content="Browse..." DockPanel.Dock="Right"
                    Style="{StaticResource SecondaryButton}" Margin="8,0,0,0"/>
            <TextBox x:Name="txtIsoPath" Style="{StaticResource DarkTextBox}"
                     IsReadOnly="True" Text="Select a Windows 11 ISO file..."/>
        </DockPanel>

        <!-- Edition -->
        <TextBlock Text="Select Edition" Foreground="#a6adc8" FontSize="12"
                   FontFamily="Segoe UI" Margin="0,0,0,4"/>
        <ComboBox x:Name="cmbEdition" Style="{StaticResource DarkComboBox}"
                  Margin="0,0,0,16" IsEnabled="False"/>

        <!-- Scratch Directory -->
        <TextBlock Text="Scratch Directory" Foreground="#a6adc8" FontSize="12"
                   FontFamily="Segoe UI" Margin="0,0,0,4"/>
        <DockPanel Margin="0,0,0,16">
            <Button x:Name="btnBrowseScratch" Content="Browse..." DockPanel.Dock="Right"
                    Style="{StaticResource SecondaryButton}" Margin="8,0,0,0"/>
            <TextBox x:Name="txtScratchDir" Style="{StaticResource DarkTextBox}"/>
        </DockPanel>

        <!-- Output ISO -->
        <TextBlock Text="Output ISO Path" Foreground="#a6adc8" FontSize="12"
                   FontFamily="Segoe UI" Margin="0,0,0,4"/>
        <DockPanel Margin="0,0,0,16">
            <Button x:Name="btnBrowseOutput" Content="Browse..." DockPanel.Dock="Right"
                    Style="{StaticResource SecondaryButton}" Margin="8,0,0,0"/>
            <TextBox x:Name="txtOutputPath" Style="{StaticResource DarkTextBox}"
                     Text="tiny11.iso"/>
        </DockPanel>
    </StackPanel>
'@
}

function Get-Step2Xaml {
    <#
    .SYNOPSIS
        Step 2: Build Mode â€” Regular vs Core selection.
    #>
    return @'
    <StackPanel x:Name="step2Panel" Margin="20" Visibility="Collapsed">
        <TextBlock Text="Build Mode" Foreground="#cdd6f4" FontSize="22"
                   FontWeight="Bold" FontFamily="Segoe UI" Margin="0,0,0,4"/>
        <TextBlock Text="Choose how aggressively to trim your Windows image"
                   Foreground="#a6adc8" FontSize="13" FontFamily="Segoe UI" Margin="0,0,0,20"/>

        <Grid>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="16"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <!-- Regular Card -->
            <Border x:Name="cardRegular" Grid.Column="0" Style="{StaticResource SelectableCard}"
                    BorderBrush="#94e2d5" Tag="selected">
                <StackPanel>
                    <TextBlock Text="&#x2713;" Foreground="#94e2d5" FontSize="28" Margin="0,0,0,8"/>
                    <TextBlock Text="Regular" Foreground="#94e2d5" FontSize="18"
                               FontWeight="Bold" FontFamily="Segoe UI" Margin="0,0,0,4"/>
                    <TextBlock Text="Serviceable" Foreground="#a6adc8" FontSize="12"
                               FontFamily="Segoe UI" Margin="0,0,0,12"/>
                    <TextBlock TextWrapping="Wrap" Foreground="#cdd6f4" FontSize="12"
                               FontFamily="Segoe UI" Margin="0,0,0,8"
                               Text="Removes bloatware while keeping the system fully updateable. Windows Update, Defender, and WinSxS remain intact."/>
                    <TextBlock Text="Recommended for daily use" Foreground="#a6e3a1"
                               FontSize="11" FontFamily="Segoe UI" FontStyle="Italic"/>
                </StackPanel>
            </Border>

            <!-- Core Card -->
            <Border x:Name="cardCore" Grid.Column="2" Style="{StaticResource SelectableCard}">
                <StackPanel>
                    <TextBlock Text="&#x26A0;" Foreground="#cba6f7" FontSize="28" Margin="0,0,0,8"/>
                    <TextBlock Text="Core" Foreground="#cba6f7" FontSize="18"
                               FontWeight="Bold" FontFamily="Segoe UI" Margin="0,0,0,4"/>
                    <TextBlock Text="Maximum Reduction" Foreground="#a6adc8" FontSize="12"
                               FontFamily="Segoe UI" Margin="0,0,0,12"/>
                    <TextBlock TextWrapping="Wrap" Foreground="#cdd6f4" FontSize="12"
                               FontFamily="Segoe UI" Margin="0,0,0,8"
                               Text="Removes everything including WinSxS, Defender, and Windows Update. Smallest possible image."/>
                    <Border Background="#45475a" CornerRadius="4" Padding="8,4" Margin="0,4,0,0">
                        <TextBlock Text="&#x26A0; Non-serviceable! For VMs and testing only."
                                   Foreground="#f38ba8" FontSize="11" FontFamily="Segoe UI"
                                   TextWrapping="Wrap"/>
                    </Border>
                </StackPanel>
            </Border>
        </Grid>
    </StackPanel>
'@
}

function Get-Step3Xaml {
    <#
    .SYNOPSIS
        Step 3: Installation Type â€” Standard vs Custom, with category selection panel.
    #>
    return @'
    <Grid x:Name="step3Panel" Margin="20" Visibility="Collapsed">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0">
            <TextBlock Text="Installation Type" Foreground="#cdd6f4" FontSize="22"
                       FontWeight="Bold" FontFamily="Segoe UI" Margin="0,0,0,4"/>
            <TextBlock Text="Choose standard removals or customize each item"
                       Foreground="#a6adc8" FontSize="13" FontFamily="Segoe UI" Margin="0,0,0,16"/>
        </StackPanel>

        <!-- Standard / Custom Toggle -->
        <Grid Grid.Row="1" Margin="0,0,0,16">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="16"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <Border x:Name="cardStandard" Grid.Column="0" Style="{StaticResource SelectableCard}"
                    BorderBrush="#89b4fa" Tag="selected" Padding="12">
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="&#x2611;" Foreground="#89b4fa" FontSize="20" Margin="0,0,8,0"
                               VerticalAlignment="Center"/>
                    <StackPanel>
                        <TextBlock Text="Standard" Foreground="#89b4fa" FontSize="15"
                                   FontWeight="Bold" FontFamily="Segoe UI"/>
                        <TextBlock Text="Apply recommended removals" Foreground="#a6adc8"
                                   FontSize="11" FontFamily="Segoe UI"/>
                    </StackPanel>
                </StackPanel>
            </Border>

            <Border x:Name="cardCustom" Grid.Column="2" Style="{StaticResource SelectableCard}"
                    Padding="12">
                <StackPanel Orientation="Horizontal">
                    <TextBlock Text="&#x2699;" Foreground="#a6adc8" FontSize="20" Margin="0,0,8,0"
                               VerticalAlignment="Center"/>
                    <StackPanel>
                        <TextBlock Text="Custom" Foreground="#cdd6f4" FontSize="15"
                                   FontWeight="Bold" FontFamily="Segoe UI"/>
                        <TextBlock Text="Choose what to keep and remove" Foreground="#a6adc8"
                                   FontSize="11" FontFamily="Segoe UI"/>
                    </StackPanel>
                </StackPanel>
            </Border>
        </Grid>

        <!-- Custom Selection Panel (hidden by default) -->
        <Grid x:Name="customPanel" Grid.Row="2" Visibility="Collapsed">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Toolbar -->
            <DockPanel Grid.Row="0" Margin="0,0,0,8">
                <StackPanel Orientation="Horizontal" DockPanel.Dock="Right">
                    <Button x:Name="btnSelectAll" Content="Select All"
                            Style="{StaticResource SecondaryButton}" Margin="4,0"/>
                    <Button x:Name="btnDeselectAll" Content="Deselect All"
                            Style="{StaticResource SecondaryButton}" Margin="4,0"/>
                    <Button x:Name="btnLoadProfile" Content="Load Profile"
                            Style="{StaticResource SecondaryButton}" Margin="4,0"/>
                    <Button x:Name="btnSaveProfile" Content="Save Profile"
                            Style="{StaticResource SecondaryButton}" Margin="4,0"/>
                </StackPanel>
                <TextBox x:Name="txtSearch" Style="{StaticResource DarkTextBox}"
                         Text="" Margin="0,0,8,0"/>
            </DockPanel>

            <!-- Category + Items -->
            <Grid Grid.Row="1">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="200"/>
                    <ColumnDefinition Width="8"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>

                <!-- Category List -->
                <Border Grid.Column="0" Background="#313244" CornerRadius="8" Padding="4">
                    <ListBox x:Name="lstCategories" Background="Transparent" BorderThickness="0"
                             Foreground="#cdd6f4" FontFamily="Segoe UI" FontSize="13"/>
                </Border>

                <!-- Items List -->
                <Border Grid.Column="2" Background="#313244" CornerRadius="8" Padding="8">
                    <ScrollViewer VerticalScrollBarVisibility="Auto">
                        <StackPanel x:Name="pnlItems"/>
                    </ScrollViewer>
                </Border>
            </Grid>

            <!-- Status Bar -->
            <Border Grid.Row="2" Margin="0,8,0,0" Background="#313244" CornerRadius="6" Padding="12,6">
                <TextBlock x:Name="txtItemCount" Text="0 items selected for removal"
                           Foreground="#a6adc8" FontSize="12" FontFamily="Segoe UI"/>
            </Border>
        </Grid>
    </Grid>
'@
}

function Get-Step4Xaml {
    <#
    .SYNOPSIS
        Step 4: Build â€” Summary, progress, and log output.
    #>
    return @'
    <Grid x:Name="step4Panel" Margin="20" Visibility="Collapsed">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0">
            <TextBlock Text="Build" Foreground="#cdd6f4" FontSize="22"
                       FontWeight="Bold" FontFamily="Segoe UI" Margin="0,0,0,4"/>
            <TextBlock Text="Review your configuration and start the build"
                       Foreground="#a6adc8" FontSize="13" FontFamily="Segoe UI" Margin="0,0,0,16"/>
        </StackPanel>

        <!-- Summary Card -->
        <Border Grid.Row="1" Style="{StaticResource Card}" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="Source" Foreground="#a6adc8" FontSize="11" FontFamily="Segoe UI"/>
                    <TextBlock x:Name="txtSummarySource" Text="-" Foreground="#cdd6f4"
                               FontSize="13" FontFamily="Segoe UI" Margin="0,0,0,8"
                               TextTrimming="CharacterEllipsis"/>
                    <TextBlock Text="Mode" Foreground="#a6adc8" FontSize="11" FontFamily="Segoe UI"/>
                    <TextBlock x:Name="txtSummaryMode" Text="Regular" Foreground="#94e2d5"
                               FontSize="13" FontWeight="SemiBold" FontFamily="Segoe UI"/>
                </StackPanel>
                <StackPanel Grid.Column="1">
                    <TextBlock Text="Output" Foreground="#a6adc8" FontSize="11" FontFamily="Segoe UI"/>
                    <TextBlock x:Name="txtSummaryOutput" Text="-" Foreground="#cdd6f4"
                               FontSize="13" FontFamily="Segoe UI" Margin="0,0,0,8"
                               TextTrimming="CharacterEllipsis"/>
                    <TextBlock Text="Items to Remove" Foreground="#a6adc8" FontSize="11" FontFamily="Segoe UI"/>
                    <TextBlock x:Name="txtSummaryCount" Text="0" Foreground="#f9e2af"
                               FontSize="13" FontWeight="SemiBold" FontFamily="Segoe UI"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Progress -->
        <StackPanel Grid.Row="2" Margin="0,0,0,8">
            <DockPanel Margin="0,0,0,4">
                <TextBlock x:Name="txtPhase" Text="Ready to build" Foreground="#a6adc8"
                           FontSize="12" FontFamily="Segoe UI"/>
                <TextBlock x:Name="txtPercent" Text="" Foreground="#89b4fa"
                           FontSize="12" FontFamily="Segoe UI" DockPanel.Dock="Right"
                           HorizontalAlignment="Right"/>
            </DockPanel>
            <ProgressBar x:Name="progressBar" Style="{StaticResource DarkProgressBar}"
                         Minimum="0" Maximum="100" Value="0"/>
        </StackPanel>

        <!-- Log Output -->
        <Border Grid.Row="3" Background="#181825" CornerRadius="8" Padding="8" Margin="0,4,0,0">
            <TextBox x:Name="txtLog" Background="Transparent" Foreground="#a6adc8"
                     FontFamily="Cascadia Mono,Consolas,Courier New" FontSize="11"
                     IsReadOnly="True" TextWrapping="Wrap" AcceptsReturn="True"
                     VerticalScrollBarVisibility="Auto" BorderThickness="0"
                     CaretBrush="#a6adc8"/>
        </Border>

        <!-- Build Actions -->
        <StackPanel Grid.Row="4" Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,12,0,0">
            <Button x:Name="btnStartBuild" Content="Start Build"
                    Style="{StaticResource PrimaryButton}" Margin="0,0,8,0" Padding="32,12"/>
            <Button x:Name="btnCancelBuild" Content="Cancel" IsEnabled="False"
                    Style="{StaticResource DangerButton}" Margin="8,0,0,0"/>
            <Button x:Name="btnOpenFolder" Content="Open Output Folder" Visibility="Collapsed"
                    Style="{StaticResource SecondaryButton}" Margin="8,0,0,0"/>
        </StackPanel>
    </Grid>
'@
}

function Get-SubmodulePromptXaml {
    <#
    .SYNOPSIS
        First-run dialog when tiny11builder scripts are not found.
    #>
    return @'
    <StackPanel x:Name="submodulePanel" Margin="40" VerticalAlignment="Center"
                HorizontalAlignment="Center" Width="400">
        <TextBlock Text="&#x1F50D;" FontSize="36" HorizontalAlignment="Center" Margin="0,0,0,12"/>
        <TextBlock Text="tiny11builder scripts not found" Foreground="#cdd6f4" FontSize="18"
                   FontWeight="Bold" FontFamily="Segoe UI" HorizontalAlignment="Center"
                   Margin="0,0,0,8"/>
        <TextBlock Text="tiny11 Studio needs the tiny11builder scripts to function. Choose how to set them up:"
                   Foreground="#a6adc8" FontSize="12" FontFamily="Segoe UI" TextWrapping="Wrap"
                   TextAlignment="Center" Margin="0,0,0,20"/>

        <Button x:Name="btnCloneGithub" Content="Clone from GitHub (recommended)"
                Style="{StaticResource PrimaryButton}" Margin="0,0,0,8" HorizontalAlignment="Stretch"/>
        <Button x:Name="btnUseLocal" Content="Use local copy..."
                Style="{StaticResource SecondaryButton}" HorizontalAlignment="Stretch"/>

        <TextBlock x:Name="txtSubmoduleStatus" Text="" Foreground="#a6adc8" FontSize="11"
                   FontFamily="Segoe UI" HorizontalAlignment="Center" Margin="0,12,0,0"/>
    </StackPanel>
'@
}
