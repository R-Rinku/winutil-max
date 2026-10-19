function Invoke-WPFTakeOwnershipAdd {
    <#
    .SYNOPSIS
        Adds 'Take Full Ownership' to the right-click context menu.
    .DESCRIPTION
        Configures context menu entries for files, directories, and non-system drives
        with safety filters preventing accidental ownership changes on critical system paths.
    #>
    [CmdletBinding()]
    param()

    try {
        # 1. Files (*\shell\TakeOwnership)
        $fileKey = "Registry::HKEY_CLASSES_ROOT\*\shell\TakeOwnership"
        New-Item -Path $fileKey -Force | Out-Null
        Set-ItemProperty -Path $fileKey -Name "(Default)" -Value "Take Ownership"
        Set-ItemProperty -Path $fileKey -Name "HasLUAShield" -Value ""
        Set-ItemProperty -Path $fileKey -Name "NoWorkingDirectory" -Value ""
        Set-ItemProperty -Path $fileKey -Name "NeverDefault" -Value ""
        Remove-ItemProperty -Path $fileKey -Name "Extended" -ErrorAction SilentlyContinue

        $fileCmdKey = "$fileKey\command"
        New-Item -Path $fileCmdKey -Force | Out-Null
        $fileCmd = 'powershell.exe -NoProfile -WindowStyle Hidden -Command "Start-Process cmd.exe -ArgumentList ''/c takeown /f \"%1\" && icacls \"%1\" /grant *S-1-3-4:F /t /c /l'' -Verb runAs"'
        Set-ItemProperty -Path $fileCmdKey -Name "(Default)" -Value $fileCmd
        Set-ItemProperty -Path $fileCmdKey -Name "IsolatedCommand" -Value $fileCmd

        # 2. Directories (Directory\shell\TakeOwnership)
        $dirKey = "Registry::HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership"
        New-Item -Path $dirKey -Force | Out-Null
        Set-ItemProperty -Path $dirKey -Name "(Default)" -Value "Take Ownership"
        Set-ItemProperty -Path $dirKey -Name "HasLUAShield" -Value ""
        Set-ItemProperty -Path $dirKey -Name "NoWorkingDirectory" -Value ""
        Set-ItemProperty -Path $dirKey -Name "Position" -Value "middle"
        Set-ItemProperty -Path $dirKey -Name "AppliesTo" -Value 'NOT (System.ItemPathDisplay:="C:\Users" OR System.ItemPathDisplay:="C:\ProgramData" OR System.ItemPathDisplay:="C:\Windows" OR System.ItemPathDisplay:="C:\Windows\System32" OR System.ItemPathDisplay:="C:\Program Files" OR System.ItemPathDisplay:="C:\Program Files (x86)")'
        Remove-ItemProperty -Path $dirKey -Name "Extended" -ErrorAction SilentlyContinue

        $dirCmdKey = "$dirKey\command"
        New-Item -Path $dirCmdKey -Force | Out-Null
        $dirCmd = 'powershell.exe -NoProfile -WindowStyle Hidden -Command "Start-Process cmd.exe -ArgumentList ''/c takeown /f \"%1\" /r /d y && icacls \"%1\" /grant *S-1-3-4:F /t /c /l /q'' -Verb runAs"'
        Set-ItemProperty -Path $dirCmdKey -Name "(Default)" -Value $dirCmd
        Set-ItemProperty -Path $dirCmdKey -Name "IsolatedCommand" -Value $dirCmd

        # 3. Drives (Drive\shell\runas)
        $driveKey = "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas"
        New-Item -Path $driveKey -Force | Out-Null
        Set-ItemProperty -Path $driveKey -Name "(Default)" -Value "Take Ownership"
        Set-ItemProperty -Path $driveKey -Name "HasLUAShield" -Value ""
        Set-ItemProperty -Path $driveKey -Name "NoWorkingDirectory" -Value ""
        Set-ItemProperty -Path $driveKey -Name "Position" -Value "middle"
        Set-ItemProperty -Path $driveKey -Name "AppliesTo" -Value 'NOT (System.ItemPathDisplay:="C:\")'
        Remove-ItemProperty -Path $driveKey -Name "Extended" -ErrorAction SilentlyContinue

        $driveCmdKey = "$driveKey\command"
        New-Item -Path $driveCmdKey -Force | Out-Null
        $driveCmd = 'cmd.exe /c takeown /f "%1" /r /d y && icacls "%1" /grant *S-1-3-4:F /t /c'
        Set-ItemProperty -Path $driveCmdKey -Name "(Default)" -Value $driveCmd
        Set-ItemProperty -Path $driveCmdKey -Name "IsolatedCommand" -Value $driveCmd

        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] 'Take Full Ownership' added to right-click context menu." -ForegroundColor Green
        Write-WinUtilLog -Component "Config" -Message "Take Full Ownership added to context menu successfully."
        Step-WinUtilJob -Status "'Take Full Ownership' added to context menu" -Percent 100
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to add Take Full Ownership: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Config" -Message "Failed to add Take Full Ownership: $($_.Exception.Message)" -Level "ERROR"
        Step-WinUtilJob -Status "Failed to add Take Full Ownership" -Percent 100 -State "Error"
    }
}

function Invoke-WPFTakeOwnershipRemove {
    <#
    .SYNOPSIS
        Removes 'Take Full Ownership' from the right-click context menu.
    #>
    [CmdletBinding()]
    param()

    try {
        $keys = @(
            "Registry::HKEY_CLASSES_ROOT\*\shell\TakeOwnership",
            "Registry::HKEY_CLASSES_ROOT\Directory\shell\TakeOwnership",
            "Registry::HKEY_CLASSES_ROOT\Drive\shell\runas"
        )

        foreach ($k in $keys) {
            if (Test-Path $k) {
                Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] 'Take Full Ownership' removed from right-click context menu." -ForegroundColor Green
        Write-WinUtilLog -Component "Config" -Message "Take Full Ownership removed from context menu."
        Step-WinUtilJob -Status "'Take Full Ownership' removed from context menu" -Percent 100
    } catch {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [ERROR] Failed to remove Take Full Ownership: $($_.Exception.Message)" -ForegroundColor Red
        Write-WinUtilLog -Component "Config" -Message "Failed to remove Take Full Ownership: $($_.Exception.Message)" -Level "ERROR"
        Step-WinUtilJob -Status "Failed to remove Take Full Ownership" -Percent 100 -State "Error"
    }
}
