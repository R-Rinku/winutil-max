function Invoke-WinUtilBitLockerPolicy {
    <#
    .SYNOPSIS
        Configures Windows Group Policy & Registry to allow BitLocker Startup PINs.
    .DESCRIPTION
        Enables UseAdvancedStartup, EnableBDEWithNoTPM, and TPM startup PIN policies
        so BitLocker can be configured with a PIN at boot on any hardware (TPM or non-TPM).
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "BitLocker" -Message "Configuring BitLocker Startup PIN Group Policy / Registry."
    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Configuring BitLocker Startup PIN policy..." -ForegroundColor Cyan

    try {
        $fveKey = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
        if (-not (Test-Path $fveKey)) {
            New-Item -Path $fveKey -Force | Out-Null
        }

        # Enable advanced startup options (allows PIN / startup key)
        Set-ItemProperty -Path $fveKey -Name "UseAdvancedStartup" -Value 1 -Type DWord -Force
        # Allow BitLocker without a compatible TPM (allows password/startup key on non-TPM devices)
        Set-ItemProperty -Path $fveKey -Name "EnableBDEWithNoTPM" -Value 1 -Type DWord -Force
        # Allow TPM (2 = Allow TPM)
        Set-ItemProperty -Path $fveKey -Name "UseTPM" -Value 2 -Type DWord -Force
        # Allow TPM startup PIN (2 = Allow startup PIN with TPM, 1 = Require)
        Set-ItemProperty -Path $fveKey -Name "UseTPMPIN" -Value 2 -Type DWord -Force
        # Allow TPM startup key
        Set-ItemProperty -Path $fveKey -Name "UseTPMKey" -Value 2 -Type DWord -Force
        # Allow TPM startup key and PIN
        Set-ItemProperty -Path $fveKey -Name "UseTPMKeyPIN" -Value 2 -Type DWord -Force

        # Force Group Policy refresh in background
        Start-Process "gpupdate.exe" -ArgumentList "/target:computer /force" -NoNewWindow -Wait -ErrorAction SilentlyContinue

        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] BitLocker Startup PIN policy enabled!" -ForegroundColor Green
        Write-WinUtilLog -Component "BitLocker" -Message "BitLocker Startup PIN policy configured successfully."

        if (Test-WinUtilUIAlive) {
            Show-WinUtilMessage -Title "BitLocker Startup PIN Policy" -Message "BitLocker Startup PIN policy has been successfully configured and applied!`n`nYou can now set a startup PIN on your system drive (even on non-TPM hardware)." -Button "OK" -Icon "Information"
        }
    } catch {
        Write-WinUtilLog -Level "ERROR" -Component "BitLocker" -Message "Failed to configure BitLocker policy: $_"
        Write-Host "[winutil-MAX] [ERROR] Failed to configure BitLocker policy: $_" -ForegroundColor Red
        if (Test-WinUtilUIAlive) {
            Show-WinUtilMessage -Title "BitLocker Policy Error" -Message "Failed to enable BitLocker policy: $_" -Button "OK" -Icon "Error"
        }
    }
}
