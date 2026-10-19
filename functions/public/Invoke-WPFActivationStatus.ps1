function Invoke-WPFActivationStatus {
    <#
    .SYNOPSIS
        Checks Windows license and activation expiration status.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Checking Windows license activation status."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Checking Windows activation status..." -ForegroundColor Cyan

    try {
        Start-Process -FilePath "slmgr.vbs" -ArgumentList "/xpr"
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Activation status dialog requested." -ForegroundColor Green
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to query activation status: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Activation" -Message "Failed to query activation: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Invoke-WPFOpenStandardShell {
    <#
    .SYNOPSIS
        Opens an interactive PowerShell console in the user's home directory.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Opening user PowerShell terminal."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Opening PowerShell terminal in user profile..." -ForegroundColor Cyan

    try {
        Start-Process powershell.exe -ArgumentList "-NoExit" -WorkingDirectory $env:USERPROFILE
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] PowerShell terminal opened." -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "PowerShell opened successfully."
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to open terminal: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Activation" -Message "Failed to open terminal." -Level "ERROR"
    }
}
