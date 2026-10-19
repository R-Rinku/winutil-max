function Invoke-WPFActivationMAS {
    <#
    .SYNOPSIS
        Launches Microsoft Activation Scripts (MAS) in an interactive standard user console.
    .DESCRIPTION
        MAS (massgrave.dev) is an open-source Windows and Office activator utilizing HWID, Ohook,
        and KMS38 activation methods. Running via MAS_AIO.cmd in a standard shell allows the script
        to prompt for UAC only if required, and completely avoids Windows Defender ClickFix heuristics.
    .LINK
        https://massgrave.dev/
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "Activation" -Message "Preparing Microsoft Activation Scripts (MAS) from massgrave.dev."
    Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Preparing Microsoft Activation Scripts (MAS)..." -ForegroundColor Cyan

    try {
        $masFile = Join-Path $env:TEMP "MAS_AIO.cmd"
        $downloadSuccess = $false

        $urls = @(
            "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd",
            "https://gitlab.com/massgrave/microsoft-activation-scripts/-/raw/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"
        )

        foreach ($url in $urls) {
            try {
                Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] Fetching MAS script from $($url.Split('/')[2])..." -ForegroundColor DarkGray
                [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("User-Agent", "Mozilla/5.0")
                $wc.DownloadFile($url, $masFile)
                if (Test-Path $masFile) {
                    $downloadSuccess = $true
                    break
                }
            } catch {
                Write-WinUtilLog -Component "Activation" -Message "Download failed from $($url): $($_.Exception.Message)" -Level "WARN"
            }
        }

        if (-not $downloadSuccess -or -not (Test-Path $masFile)) {
            throw "Unable to download MAS script from official Massgrave repositories. Please check your internet connection."
        }

        # Launch in standard (unelevated) shell via Shell.Application so UAC is requested on demand
        try {
            $shell = New-Object -ComObject Shell.Application
            $shell.ShellExecute("cmd.exe", "/c `"$masFile`"", $env:TEMP, "open", 1)
        } catch {
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$masFile`"" -WorkingDirectory $env:TEMP
        }

        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] MAS interactive window launched in standard shell (prompts for UAC on demand)." -ForegroundColor Green
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
