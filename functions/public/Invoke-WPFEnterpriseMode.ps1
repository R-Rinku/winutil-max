function Set-WinUtilEnterpriseLock {
    <#
    .SYNOPSIS
        Enables or disables Enterprise Security Mode across the UI and runtime state.
    #>
    param(
        [bool]$Enabled
    )

    $sync.EnterpriseMode = $Enabled

    # Update button appearance
    if ($sync.WPFEnterprise) {
        if ($Enabled) {
            $sync.WPFEnterprise.Content = " [ACTIVE] Enterprise "
            $sync.WPFEnterprise.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#005A9E")
            $sync.WPFEnterprise.Foreground = [System.Windows.Media.Brushes]::White
        } else {
            $sync.WPFEnterprise.Content = " Enterprise "
            $sync.WPFEnterprise.ClearValue([System.Windows.Controls.Button]::BackgroundProperty)
            $sync.WPFEnterprise.ClearValue([System.Windows.Controls.Button]::ForegroundProperty)
        }
    }

    # Restrict/unrestrict high-risk buttons and sections
    $restrictedButtons = @(
        $sync.WPFAppxRemoval,
        $sync.WPFUpdatesdisable
    )

    foreach ($btn in $restrictedButtons) {
        if ($null -ne $btn) {
            $btn.IsEnabled = (-not $Enabled)
        }
    }

    # Restrict high-risk tweak checkboxes
    $restrictedTweaks = @(
        "WPFTweaksRemoveEdge",
        "WPFTweaksRemoveOneDrive",
        "WPFTweaksDisableTelemetry",
        "WPFTweaksDisableCortana",
        "WPFTweaksWindowsAI",
        "WPFTweaksRightClickMenu",
        "WPFTweaksRevertStartMenu"
    )

    foreach ($tweakKey in $restrictedTweaks) {
        $control = $sync[$tweakKey]
        if ($null -ne $control) {
            if ($Enabled) {
                $control.IsChecked = $false
                $control.IsEnabled = $false
            } else {
                $control.IsEnabled = $true
            }
        }
    }
}

function Invoke-WPFEnterpriseMode {
    <#
    .SYNOPSIS
        Activates Enterprise Mode: applies enterprise-safe preset and enforces security lockdown.
    #>
    [CmdletBinding()]
    param()

    # Apply the Enterprise Preset
    Invoke-WPFPresets "Enterprise" -checkboxfilterpattern "WPFTweak*"

    # Enable security lock
    Set-WinUtilEnterpriseLock -Enabled $true

    Write-WinUtilLog -Component "Enterprise" -Message "Enterprise Mode activated: Applied safe tweaks preset and locked high-risk actions."
}
