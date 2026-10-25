function Invoke-WPFTakeOwnershipAdd {
    <#
    .SYNOPSIS
        Adds 'Take Full Ownership' to right-click context menu using native registry import.
    .DESCRIPTION
        Configures context menu entries for files, directories, and non-system drives
        with safety filters preventing accidental ownership changes on critical system paths.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "TakeOwnership" -Message "Adding Take Ownership context menu entries."
    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Adding Take Ownership to context menu..." -ForegroundColor Cyan

    $regContent = @"
Windows Registry Editor Version 5.00

; winutil-MAX: Take Ownership Context Menu
[HKEY_CLASSES_ROOT\*\shell\TakeOwnership]
@="Take Ownership"
"HasLUAShield"=""
"NoWorkingDirectory"=""

[HKEY_CLASSES_ROOT\*\shell\TakeOwnership\command]
@="powershell.exe -NoProfile -WindowStyle Hidden -Command \"Start-Process cmd.exe -ArgumentList '/c takeown /f \\\"%1\\\" && icacls \\\"%1\\\" /grant *S-1-3-4:F /c /l' -Verb runAs\""

[HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership]
@="Take Ownership"
"HasLUAShield"=""
"NoWorkingDirectory"=""
"Position"="middle"
"AppliesTo"="NOT (System.ItemPathDisplay:=\"C:\\Users\" OR System.ItemPathDisplay:=\"C:\\ProgramData\" OR System.ItemPathDisplay:=\"C:\\Windows\" OR System.ItemPathDisplay:=\"C:\\Windows\\System32\" OR System.ItemPathDisplay:=\"C:\\Program Files\" OR System.ItemPathDisplay:=\"C:\\Program Files (x86)\")"

[HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership\command]
@="powershell.exe -NoProfile -WindowStyle Hidden -Command \"Start-Process cmd.exe -ArgumentList '/c takeown /f \\\"%1\\\" /r /d y && icacls \\\"%1\\\" /grant *S-1-3-4:F /t /c /l /q' -Verb runAs\""

[HKEY_CLASSES_ROOT\Drive\shell\runas]
@="Take Ownership"
"HasLUAShield"=""
"NoWorkingDirectory"=""
"Position"="middle"
"AppliesTo"="NOT (System.ItemPathDisplay:=\"C:\\\")"

[HKEY_CLASSES_ROOT\Drive\shell\runas\command]
@="cmd.exe /c takeown /f \"%1\" /r /d y && icacls \"%1\" /grant *S-1-3-4:F /t /c"
"@

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidates += Join-Path $PSScriptRoot "..\..\scripts\take-ownership\Add_Take_Ownership_to_context_menu.reg"
        $candidates += Join-Path $PSScriptRoot "scripts\take-ownership\Add_Take_Ownership_to_context_menu.reg"
    }
    $currPath = (Get-Location).Path
    if (-not [string]::IsNullOrWhiteSpace($currPath)) {
        $candidates += Join-Path $currPath "scripts\take-ownership\Add_Take_Ownership_to_context_menu.reg"
    }

    $localReg = $candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path $_) } | Select-Object -First 1

    $isTemp = $false
    if ($localReg) {
        $regFileToImport = $localReg
    } else {
        $regFileToImport = Join-Path ([System.IO.Path]::GetTempPath()) "winutil_max_take_ownership_add_$([guid]::NewGuid().ToString('N')).reg"
        [System.IO.File]::WriteAllText($regFileToImport, $regContent, [System.Text.Encoding]::Unicode)
        $isTemp = $true
    }

    try {
        $process = Start-Process -FilePath "reg.exe" -ArgumentList "import `"$regFileToImport`"" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] 'Take Full Ownership' added to right-click context menu." -ForegroundColor Green
            Write-WinUtilLog -Component "TakeOwnership" -Message "Take Full Ownership added to context menu successfully."
        } else {
            throw "reg.exe import failed with exit code $($process.ExitCode)."
        }
    } finally {
        if ($isTemp -and (Test-Path $regFileToImport)) {
            Remove-Item -Path $regFileToImport -Force -ErrorAction SilentlyContinue
        }
    }
}

function Invoke-WPFTakeOwnershipRemove {
    <#
    .SYNOPSIS
        Removes 'Take Full Ownership' from the right-click context menu.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "TakeOwnership" -Message "Removing Take Ownership context menu entries."
    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Removing Take Ownership from context menu..." -ForegroundColor Cyan

    $regContent = @"
Windows Registry Editor Version 5.00

[-HKEY_CLASSES_ROOT\*\shell\TakeOwnership]
[-HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership]
[-HKEY_CLASSES_ROOT\Drive\shell\runas]
"@

    $candidates = @()
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidates += Join-Path $PSScriptRoot "..\..\scripts\take-ownership\Remove_Take_Ownership_from_context_menu.reg"
        $candidates += Join-Path $PSScriptRoot "scripts\take-ownership\Remove_Take_Ownership_from_context_menu.reg"
    }
    $currPath = (Get-Location).Path
    if (-not [string]::IsNullOrWhiteSpace($currPath)) {
        $candidates += Join-Path $currPath "scripts\take-ownership\Remove_Take_Ownership_from_context_menu.reg"
    }

    $localReg = $candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path $_) } | Select-Object -First 1

    $isTemp = $false
    if ($localReg) {
        $regFileToImport = $localReg
    } else {
        $regFileToImport = Join-Path ([System.IO.Path]::GetTempPath()) "winutil_max_take_ownership_rem_$([guid]::NewGuid().ToString('N')).reg"
        [System.IO.File]::WriteAllText($regFileToImport, $regContent, [System.Text.Encoding]::Unicode)
        $isTemp = $true
    }

    try {
        $process = Start-Process -FilePath "reg.exe" -ArgumentList "import `"$regFileToImport`"" -Wait -PassThru -NoNewWindow
        if ($process.ExitCode -eq 0) {
            Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] 'Take Full Ownership' removed from right-click context menu." -ForegroundColor Green
            Write-WinUtilLog -Component "TakeOwnership" -Message "Take Full Ownership removed from context menu successfully."
        } else {
            throw "reg.exe import failed with exit code $($process.ExitCode)."
        }
    } finally {
        if ($isTemp -and (Test-Path $regFileToImport)) {
            Remove-Item -Path $regFileToImport -Force -ErrorAction SilentlyContinue
        }
    }
}
