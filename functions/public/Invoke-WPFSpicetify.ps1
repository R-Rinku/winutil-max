function Invoke-WPFSpicetifyInstall {
    <#
    .SYNOPSIS
        Installs Spicetify CLI for customizing and modding the Spotify Desktop client.
    .DESCRIPTION
        Spicetify (https://spicetify.app/) is a multi-platform command-line tool to customize
        the official Spotify client, supporting themes, extensions, custom apps, and ad-blocking.
    .LINK
        https://spicetify.app/
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Launching Spicetify CLI installation."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Launching Spicetify CLI installation..." -ForegroundColor Cyan

    try {
        $cmd = "Write-Host '========================================' -ForegroundColor Green; " +
               "Write-Host '   Installing Spicetify CLI for Spotify' -ForegroundColor Cyan; " +
               "Write-Host '========================================`n' -ForegroundColor Green; " +
               "iwr -useb https://raw.githubusercontent.com/spicetify/cli/main/install.ps1 | iex; " +
               "Write-Host '`n[Done] Press any key to close this window...' -ForegroundColor Yellow; " +
               "`$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Spicetify installation launched." -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "Spicetify installer launched successfully."
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

    Write-WinUtilLog -Component "Activation" -Message "Launching Spicetify Marketplace installation."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Launching Spicetify Marketplace installation..." -ForegroundColor Cyan

    try {
        $cmd = "Write-Host '============================================' -ForegroundColor Green; " +
               "Write-Host '   Installing Spicetify Marketplace Extension' -ForegroundColor Cyan; " +
               "Write-Host '============================================`n' -ForegroundColor Green; " +
               "iwr -useb https://raw.githubusercontent.com/spicetify/spicetify-marketplace/main/resources/install.ps1 | iex; " +
               "Write-Host '`n[Done] Press any key to close this window...' -ForegroundColor Yellow; " +
               "`$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"$cmd`""
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Spicetify Marketplace installer launched." -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "Spicetify Marketplace installer launched."
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to start Spicetify Marketplace installer: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Activation" -Message "Failed to start Marketplace: $($_.Exception.Message)" -Level "ERROR"
    }
}
