function Invoke-WPFSpicetifyInstall {
    <#
    .SYNOPSIS
        Installs Spicetify CLI for customizing and modding the Spotify Desktop client.
    .DESCRIPTION
        Spicetify (https://spicetify.app/) is a multi-platform command-line tool to customize
        the official Spotify client, supporting themes, extensions, custom apps, and ad-blocking.
        Runs in standard (unelevated) user context to install directly under the user's Spotify directory.
    .LINK
        https://spicetify.app/
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Launching Spicetify CLI installation in standard user shell."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Launching Spicetify CLI installation..." -ForegroundColor Cyan

    try {
        $cmd = "Write-Host '========================================' -ForegroundColor Green; " +
               "Write-Host '   Installing Spicetify CLI for Spotify' -ForegroundColor Cyan; " +
               "Write-Host '   Running in Standard User Shell' -ForegroundColor Gray; " +
               "Write-Host '========================================`n' -ForegroundColor Green; " +
               "iwr -useb https://raw.githubusercontent.com/spicetify/cli/main/install.ps1 | iex; " +
               "Write-Host '`n[Done] Press any key to close this window...' -ForegroundColor Yellow; " +
               "`$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"

        $arg = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""

        # Launch in standard unelevated shell via Shell.Application
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.ShellExecute("powershell.exe", $arg, $env:USERPROFILE, "open", 1)
        } catch {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "powershell.exe"
            $psi.Arguments = $arg
            $psi.UseShellExecute = $true
            [System.Diagnostics.Process]::Start($psi) | Out-Null
        }

        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Spicetify installer launched in standard user shell." -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "Spicetify installer launched successfully in standard shell."
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to start Spicetify installer: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Activation" -Message "Failed to start Spicetify installer: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Invoke-WPFSpicetifyMarketplace {
    <#
    .SYNOPSIS
        Installs Spicetify Marketplace into Spotify for easy downloading of themes and extensions.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Launching Spicetify Marketplace installation in standard user shell."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Launching Spicetify Marketplace installation..." -ForegroundColor Cyan

    try {
        $cmd = "Write-Host '============================================' -ForegroundColor Green; " +
               "Write-Host '   Installing Spicetify Marketplace Extension' -ForegroundColor Cyan; " +
               "Write-Host '   Running in Standard User Shell' -ForegroundColor Gray; " +
               "Write-Host '============================================`n' -ForegroundColor Green; " +
               "iwr -useb https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.ps1 | iex; " +
               "Write-Host '`n[Done] Press any key to close this window...' -ForegroundColor Yellow; " +
               "`$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"

        $arg = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""

        # Launch in standard unelevated shell via Shell.Application
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.ShellExecute("powershell.exe", $arg, $env:USERPROFILE, "open", 1)
        } catch {
            $psi = New-Object System.Diagnostics.ProcessStartInfo
            $psi.FileName = "powershell.exe"
            $psi.Arguments = $arg
            $psi.UseShellExecute = $true
            [System.Diagnostics.Process]::Start($psi) | Out-Null
        }

        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Spicetify Marketplace installer launched in standard user shell." -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "Spicetify Marketplace installer launched in standard shell."
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to start Spicetify Marketplace installer: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Activation" -Message "Failed to start Marketplace: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Invoke-WPFSpicetifyCopy {
    <#
    .SYNOPSIS
        Copies the Spicetify CLI install command to clipboard.
    #>
    [CmdletBinding()]
    param()

    $cmd = "iwr -useb https://raw.githubusercontent.com/spicetify/cli/main/install.ps1 | iex"
    try {
        Set-Clipboard -Value $cmd
        Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Copied Spicetify command to clipboard: $cmd" -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "Copied Spicetify command to clipboard: $cmd"
        if ($sync.WPFSpicetifyCopy) {
            $sync.WPFSpicetifyCopy.Content = "Copied!"
        }
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to copy to clipboard: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Activation" -Message "Failed to copy to clipboard: $($_.Exception.Message)" -Level "ERROR"
    }
}

