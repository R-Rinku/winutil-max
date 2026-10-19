function Invoke-WPFActivationMAS {
    <#
    .SYNOPSIS
        Launches Microsoft Activation Scripts (MAS) in an interactive elevated PowerShell console.
    .DESCRIPTION
        MAS (massgrave.dev) is an open-source Windows and Office activator utilizing HWID, Ohook,
        and KMS38 activation methods. Running in an interactive window allows the user to
        select the desired activation method.
    .LINK
        https://massgrave.dev/
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Launching Microsoft Activation Scripts (MAS) from massgrave.dev."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Launching Microsoft Activation Scripts (MAS)..." -ForegroundColor Cyan

    try {
        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName = "powershell.exe"
        $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://get.activated.win | iex`""
        $psi.Verb = "runAs"
        $psi.UseShellExecute = $true
        [System.Diagnostics.Process]::Start($psi) | Out-Null
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] MAS interactive window launched." -ForegroundColor Green
        Write-WinUtilLog -Component "Activation" -Message "MAS launched successfully."
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
