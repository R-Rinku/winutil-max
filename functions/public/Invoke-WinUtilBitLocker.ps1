function Invoke-WinUtilBitLockerPolicy {
    <#
    .SYNOPSIS
        Configures Windows Group Policy & Registry to allow BitLocker Startup Passwords without TPM.
    .DESCRIPTION
        Enables UseAdvancedStartup, EnableBDEWithNoTPM, and OSPassphrase policies so BitLocker
        can be configured with a pre-boot Startup Password without requiring TPM.
        This is essential for dual-boot systems where another Windows installation is already
        using the hardware TPM, preventing PCR invalidation and BitLocker recovery prompts.
    #>
    [CmdletBinding()]
    param()

    Write-Warning "BitLocker & encryption changes can cause data lockout if recovery keys are missing. Back up recovery keys for ALL OS drives (both devices/OSes on dual-boot) before encrypting."

    if (Test-WinUtilUIAlive) {
        $warnMsg = "WARNING: BitLocker & Dual-Boot Safety Check`n`n" +
                   "Modifying BitLocker or disk encryption policies can cause data loss or drive lockouts if a recovery key is lost.`n`n" +
                   "BEFORE PROCEEDING:`n" +
                   "1. Back up your BitLocker Recovery Key for BOTH Windows installations / drives if you are running Dual-Boot.`n" +
                   "2. You can view existing recovery keys anytime in an Admin terminal with:`n" +
                   "   manage-bde -protectors -get C:`n`n" +
                   "Do you want to apply the BitLocker Startup Password (No-TPM) policy now?"

        $confirm = Show-WinUtilMessage -Title "BitLocker Dual-Boot & Recovery Key Warning" -Message $warnMsg -Button "YesNo" -Icon "Warning"
        if ("$confirm" -ne "Yes") {
            Write-WinUtilLog -Level "INFO" -Component "BitLocker" -Message "User cancelled BitLocker Startup Password policy configuration."
            Write-Host "[winutil-MAX] [INFO] BitLocker policy configuration cancelled by user." -ForegroundColor Yellow
            return
        }
    }

    Write-WinUtilLog -Component "BitLocker" -Message "Configuring BitLocker Startup Password Policy (No-TPM / Dual-Boot Friendly)."
    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Configuring BitLocker Startup Password policy..." -ForegroundColor Cyan

    try {
        $fveKey = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
        if (-not (Test-Path $fveKey)) {
            New-Item -Path $fveKey -Force | Out-Null
        }

        # Enable advanced startup authentication options
        Set-ItemProperty -Path $fveKey -Name "UseAdvancedStartup" -Value 1 -Type DWord -Force

        # Allow BitLocker without a compatible TPM (requires password or startup key)
        Set-ItemProperty -Path $fveKey -Name "EnableBDEWithNoTPM" -Value 1 -Type DWord -Force

        # Enable pre-boot Startup Passwords (passphrase) for Operating System drives
        Set-ItemProperty -Path $fveKey -Name "OSPassphrase" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $fveKey -Name "OSPassphraseLength" -Value 8 -Type DWord -Force
        Set-ItemProperty -Path $fveKey -Name "OSPassphraseComplexity" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $fveKey -Name "OSPassphraseASCIIOnly" -Value 0 -Type DWord -Force

        # TPM configuration: set to 2 (Allow), not 1 (Require), so systems can choose password without TPM
        Set-ItemProperty -Path $fveKey -Name "UseTPM" -Value 2 -Type DWord -Force
        Set-ItemProperty -Path $fveKey -Name "UseTPMPIN" -Value 2 -Type DWord -Force
        Set-ItemProperty -Path $fveKey -Name "UseTPMKey" -Value 2 -Type DWord -Force
        Set-ItemProperty -Path $fveKey -Name "UseTPMKeyPIN" -Value 2 -Type DWord -Force

        # Force Group Policy refresh in background
        Start-Process "gpupdate.exe" -ArgumentList "/target:computer /force" -NoNewWindow -Wait -ErrorAction SilentlyContinue

        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] BitLocker Startup Password policy enabled!" -ForegroundColor Green
        Write-WinUtilLog -Component "BitLocker" -Message "BitLocker Startup Password policy configured successfully."

        # Validate local system state for user guidance
        $systemDrive = if ($env:SystemDrive) { $env:SystemDrive } else { "C:" }
        $tpmPresent = $false
        try {
            $tpm = Get-Tpm -ErrorAction SilentlyContinue
            if ($tpm -and $tpm.TpmPresent) { $tpmPresent = $true }
        } catch {}

        Write-Host "[winutil-MAX] [INFO] System Drive: $systemDrive" -ForegroundColor Gray
        Write-Host "[winutil-MAX] [INFO] Hardware TPM Detected: $(if ($tpmPresent) { 'Yes' } else { 'No' })" -ForegroundColor Gray
        if ($tpmPresent) {
            Write-Host "[winutil-MAX] [DUAL-BOOT TIP] A hardware TPM is present on this machine." -ForegroundColor Yellow
            Write-Host "[winutil-MAX] [DUAL-BOOT TIP] If your other OS already uses the TPM, configure BitLocker with a PASSWORD on this OS." -ForegroundColor Yellow
            Write-Host "[winutil-MAX] [DUAL-BOOT TIP] This prevents PCR measurement conflicts and recovery key lockouts between OSes." -ForegroundColor Yellow
        }
        Write-Host "[winutil-MAX] [NEXT STEPS] To enable BitLocker with a Startup Password on $systemDrive run:" -ForegroundColor Cyan
        Write-Host "    manage-bde -on $systemDrive -pw" -ForegroundColor White
        Write-Host "[winutil-MAX] [NEXT STEPS] And save your recovery password key with:" -ForegroundColor Cyan
        Write-Host "    manage-bde -protectors -add $systemDrive -rp" -ForegroundColor White

        if (Test-WinUtilUIAlive) {
            $uiMsg = "BitLocker Startup Password policy has been applied successfully!`n`n" +
                     "Dual-Boot Safeguard:`n" +
                     "Your system drive ($systemDrive) can now be encrypted using a pre-boot Startup Password without requiring TPM.`n`n" +
                     "Why this matters for Dual-Boot:`n" +
                     "If another Windows install on this PC uses the TPM, encrypting this installation with a Password prevents TPM PCR conflicts, PCR reseal mismatches, and recovery screen prompts.`n`n" +
                     "To activate encryption with a password, open an Administrator terminal and run:`n" +
                     "manage-bde -on $systemDrive -pw"

            Show-WinUtilMessage -Title "BitLocker Startup Password Policy" -Message $uiMsg -Button "OK" -Icon "Information"
        }
    } catch {
        Write-WinUtilLog -Level "ERROR" -Component "BitLocker" -Message "Failed to configure BitLocker policy: $_"
        Write-Host "[winutil-MAX] [ERROR] Failed to configure BitLocker policy: $_" -ForegroundColor Red
        if (Test-WinUtilUIAlive) {
            Show-WinUtilMessage -Title "BitLocker Policy Error" -Message "Failed to enable BitLocker policy: $_" -Button "OK" -Icon "Error"
        }
    }
}
