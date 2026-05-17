# gui-theme.ps1 — WPF Dark Theme (Catppuccin Mocha inspired)
# Returns XAML ResourceDictionary string with all styles

function Get-ThemeXaml {
    return @'
    <ResourceDictionary xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
                        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml">

        <!-- Color Palette -->
        <Color x:Key="BaseColor">#1e1e2e</Color>
        <Color x:Key="MantleColor">#181825</Color>
        <Color x:Key="CrustColor">#11111b</Color>
        <Color x:Key="Surface0Color">#313244</Color>
        <Color x:Key="Surface1Color">#45475a</Color>
        <Color x:Key="Surface2Color">#585b70</Color>
        <Color x:Key="TextColor">#cdd6f4</Color>
        <Color x:Key="SubtextColor">#a6adc8</Color>
        <Color x:Key="BlueColor">#89b4fa</Color>
        <Color x:Key="GreenColor">#a6e3a1</Color>
        <Color x:Key="YellowColor">#f9e2af</Color>
        <Color x:Key="RedColor">#f38ba8</Color>
        <Color x:Key="MauveColor">#cba6f7</Color>
        <Color x:Key="TealColor">#94e2d5</Color>
        <Color x:Key="PeachColor">#fab387</Color>

        <!-- Brushes -->
        <SolidColorBrush x:Key="BaseBrush" Color="{StaticResource BaseColor}"/>
        <SolidColorBrush x:Key="MantleBrush" Color="{StaticResource MantleColor}"/>
        <SolidColorBrush x:Key="CrustBrush" Color="{StaticResource CrustColor}"/>
        <SolidColorBrush x:Key="Surface0Brush" Color="{StaticResource Surface0Color}"/>
        <SolidColorBrush x:Key="Surface1Brush" Color="{StaticResource Surface1Color}"/>
        <SolidColorBrush x:Key="Surface2Brush" Color="{StaticResource Surface2Color}"/>
        <SolidColorBrush x:Key="TextBrush" Color="{StaticResource TextColor}"/>
        <SolidColorBrush x:Key="SubtextBrush" Color="{StaticResource SubtextColor}"/>
        <SolidColorBrush x:Key="BlueBrush" Color="{StaticResource BlueColor}"/>
        <SolidColorBrush x:Key="GreenBrush" Color="{StaticResource GreenColor}"/>
        <SolidColorBrush x:Key="YellowBrush" Color="{StaticResource YellowColor}"/>
        <SolidColorBrush x:Key="RedBrush" Color="{StaticResource RedColor}"/>
        <SolidColorBrush x:Key="MauveBrush" Color="{StaticResource MauveColor}"/>
        <SolidColorBrush x:Key="TealBrush" Color="{StaticResource TealColor}"/>
        <SolidColorBrush x:Key="PeachBrush" Color="{StaticResource PeachColor}"/>

        <!-- Primary Button Style -->
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource BlueBrush}"/>
            <Setter Property="Foreground" Value="{StaticResource CrustBrush}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="20,10"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}"
                                BorderThickness="0">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background">
                                    <Setter.Value><SolidColorBrush Color="#74c7ec"/></Setter.Value>
                                </Setter>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Secondary Button Style -->
        <Style x:Key="SecondaryButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource Surface0Brush}"/>
            <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="{StaticResource Surface1Brush}"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Opacity" Value="0.5"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Danger Button Style -->
        <Style x:Key="DangerButton" TargetType="Button">
            <Setter Property="Background" Value="{StaticResource RedBrush}"/>
            <Setter Property="Foreground" Value="{StaticResource CrustBrush}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="16,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                CornerRadius="6" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background">
                                    <Setter.Value><SolidColorBrush Color="#eba0ac"/></Setter.Value>
                                </Setter>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- TextBox Style -->
        <Style x:Key="DarkTextBox" TargetType="TextBox">
            <Setter Property="Background" Value="{StaticResource Surface0Brush}"/>
            <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
            <Setter Property="CaretBrush" Value="{StaticResource TextBrush}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="{StaticResource Surface1Brush}"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border x:Name="border" Background="{TemplateBinding Background}"
                                CornerRadius="6" BorderThickness="{TemplateBinding BorderThickness}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                Padding="{TemplateBinding Padding}">
                            <ScrollViewer x:Name="PART_ContentHost"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsFocused" Value="True">
                                <Setter TargetName="border" Property="BorderBrush" Value="{StaticResource BlueBrush}"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- ComboBox Style -->
        <Style x:Key="DarkComboBox" TargetType="ComboBox">
            <Setter Property="Background" Value="{StaticResource Surface0Brush}"/>
            <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="BorderBrush" Value="{StaticResource Surface1Brush}"/>
        </Style>

        <!-- CheckBox Style -->
        <Style x:Key="DarkCheckBox" TargetType="CheckBox">
            <Setter Property="Foreground" Value="{StaticResource TextBrush}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="0,2"/>
        </Style>

        <!-- Label Style -->
        <Style x:Key="FieldLabel" TargetType="TextBlock">
            <Setter Property="Foreground" Value="{StaticResource SubtextBrush}"/>
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,0,0,4"/>
        </Style>

        <!-- Card Border Style -->
        <Style x:Key="Card" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource Surface0Brush}"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="16"/>
            <Setter Property="Margin" Value="0,0,0,8"/>
        </Style>

        <!-- Selectable Card Style -->
        <Style x:Key="SelectableCard" TargetType="Border">
            <Setter Property="Background" Value="{StaticResource Surface0Brush}"/>
            <Setter Property="CornerRadius" Value="8"/>
            <Setter Property="Padding" Value="20"/>
            <Setter Property="BorderThickness" Value="2"/>
            <Setter Property="BorderBrush" Value="Transparent"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>

        <!-- Progress Bar Style -->
        <Style x:Key="DarkProgressBar" TargetType="ProgressBar">
            <Setter Property="Background" Value="{StaticResource Surface0Brush}"/>
            <Setter Property="Foreground" Value="{StaticResource BlueBrush}"/>
            <Setter Property="Height" Value="8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="ProgressBar">
                        <Border Background="{TemplateBinding Background}" CornerRadius="4">
                            <Border x:Name="PART_Indicator" HorizontalAlignment="Left"
                                    Background="{TemplateBinding Foreground}" CornerRadius="4"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Scrollbar Style (dark) -->
        <Style TargetType="ScrollBar">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Width" Value="8"/>
        </Style>

    </ResourceDictionary>
'@
}
