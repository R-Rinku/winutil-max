function Invoke-WPFActivationMASCopy {
    <#
    .SYNOPSIS
        Copies the Microsoft Activation Scripts (MAS) command to clipboard.
    #>
    [CmdletBinding()]
    param()

    $cmd = "irm https://get.activated.win | iex"
    try {
        Set-Clipboard -Value $cmd
        Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Copied MAS command to clipboard: $cmd" -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "Copied MAS command to clipboard: $cmd"
        if ($sync.WPFActivationMASCopy) {
            $sync.WPFActivationMASCopy.Content = "Copied!"
        }
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to copy to clipboard: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Activation" -Message "Failed to copy to clipboard: $($_.Exception.Message)" -Level "ERROR"
    }
}

function Invoke-WPFOpenStandardShell {
    <#
    .SYNOPSIS
        Opens an interactive standard (non-admin / unelevated) PowerShell console.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Opening standard user PowerShell terminal."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Opening standard user PowerShell terminal..." -ForegroundColor Cyan

    try {
        $shell = New-Object -ComObject Shell.Application
        $shell.ShellExecute("powershell.exe", "-NoExit", $env:USERPROFILE, "open", 1)
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Standard user PowerShell terminal opened." -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "Standard PowerShell opened."
    } catch {
        Start-Process powershell.exe -WorkingDirectory $env:USERPROFILE
    }
}

function Invoke-WPFActivationMAS {
    <#
    .SYNOPSIS
        Launches Microsoft Activation Scripts (MAS) in an interactive standard user console.
    .DESCRIPTION
        MAS (massgrave.dev) is an open-source Windows and Office activator utilizing HWID, Ohook,
        and KMS38 activation methods. Running in a standard shell allows the script to prompt for
        UAC only if required.
    .LINK
        https://massgrave.dev/
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Launching Microsoft Activation Scripts (MAS) in standard user shell."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Launching MAS in standard user shell..." -ForegroundColor Cyan

    try {
        # Copy command to clipboard first so user has it immediately if window closes or gets blocked
        $cmd = "irm https://massgrave.dev/get | iex"
        Set-Clipboard -Value "irm https://get.activated.win | iex"

        $arg = "-NoExit -Command `"Write-Host '=========================================' -ForegroundColor Cyan; " +
               "Write-Host '  Microsoft Activation Scripts (MAS)' -ForegroundColor Green; " +
               "Write-Host '  Running in Standard User Shell' -ForegroundColor Gray; " +
               "Write-Host '=========================================`n' -ForegroundColor Cyan; " +
               "irm https://massgrave.dev/get | iex`""

        # Launch strictly in standard (unelevated) shell via Shell.Application
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

        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] MAS interactive window launched in standard shell (command also copied to clipboard)." -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "MAS launched successfully in standard shell."
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to launch MAS: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Activation" -Message "Failed to launch MAS: $($_.Exception.Message)" -Level "ERROR"
    }
}

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
