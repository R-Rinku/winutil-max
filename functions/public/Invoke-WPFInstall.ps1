function Invoke-WPFInstall {
    <#
    .SYNOPSIS
        Installs the selected programs using winget, if one or more of the selected programs are already installed on the system, winget will try and perform an upgrade if there's a newer version to install.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [PSObject[]]$PackagesToInstall = $($sync.selectedApps | Foreach-Object { $sync.configs.applicationsHashtable.$_ })
    )

    if ($PackagesToInstall.Count -eq 0) {
        $WarningMsg = "Please select the program(s) to install or upgrade."
        Show-WinUtilMessage -Message $WarningMsg -Title "WinUtil" -Button "OK" -Icon "Warning"
        return
    }

    $ManagerPreference = $sync.preferences.packagemanager
    Write-WinUtilLog -Component "Install" -Message "Install requested for $(@($PackagesToInstall).Count) selected package(s) using preference: $ManagerPreference"
    $packageSummary = Get-WinUtilPackageLogSummary -Packages $PackagesToInstall -Preference $ManagerPreference
    Write-WinUtilLog -Component "Install" -Message "Install selected package(s): $($packageSummary -join '; ')"

    Start-WinUtilJob -Name "Install" -Description "Installing apps" -DisableAppList -Parameters @{
        PackagesToInstall = $PackagesToInstall
        ManagerPreference = $ManagerPreference
    } -ScriptBlock {
        param($PackagesToInstall, $ManagerPreference)

        $packagesSorted = Get-WinUtilSelectedPackages -PackageList $PackagesToInstall -Preference $ManagerPreference
        $packagesWinget = $packagesSorted['Winget']
        $packagesChoco = $packagesSorted['Choco']
        $totalPackages = @($packagesWinget).Count + @($packagesChoco).Count
        $completedPackages = 0
        Write-WinUtilLog -Component "Install" -Message "Install package manager split: winget=$(@($packagesWinget).Count), choco=$(@($packagesChoco).Count)"

        $results = @()

        if ($packagesWinget.Count -gt 0 -and $packagesWinget -ne "0") {
            Install-WinUtilWinget
            foreach ($program in $packagesWinget) {
                $position = $completedPackages + 1
                Step-WinUtilJob -Status "Installing $program ($position/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))

                $stepResult = Measure-WinUtilStep -Scope "Install" -Name "winget $program" -ScriptBlock {
                    Install-WinUtilProgramWinget -Action Install -Programs @($program)
                }

                # SMART BACKUP: If WinGet failed, attempt Chocolatey fallback if available
                $failedItem = @($stepResult | Where-Object { $_.Outcome -eq "Failed" })
                if ($failedItem.Count -gt 0) {
                    $matchingApp = @($PackagesToInstall | Where-Object { $_.winget -eq $program })[0]
                    if ($matchingApp -and -not [string]::IsNullOrWhiteSpace($matchingApp.choco) -and $matchingApp.choco -ne "na") {
                        $chocoBackupId = $matchingApp.choco
                        Write-Host "[winutil-MAX] [BACKUP] WinGet failed for $program. Attempting Chocolatey fallback: $chocoBackupId..." -ForegroundColor Yellow
                        Step-WinUtilJob -Status "WinGet failed for $program. Retrying with Chocolatey ($chocoBackupId)..."
                        Install-WinUtilChoco
                        $chocoBackupRes = Install-WinUtilProgramChoco -Action Install -Programs @($chocoBackupId)
                        if (@($chocoBackupRes | Where-Object { $_.Outcome -eq "Succeeded" }).Count -gt 0) {
                            Write-Host "[winutil-MAX] [BACKUP SUCCESS] Successfully installed $program using Chocolatey!" -ForegroundColor Green
                            $stepResult = $chocoBackupRes
                        }
                    }
                }

                $results += $stepResult
                $completedPackages++
                Step-WinUtilJob -Status "Installed $program ($completedPackages/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))
            }
        }

        if ($packagesChoco.Count -gt 0) {
            $position = $completedPackages + 1
            Step-WinUtilJob -Status "Installing Chocolatey packages ($position/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))

            Install-WinUtilChoco
            $chocoBase = [int](($completedPackages / $totalPackages) * 100)
            $chocoSpan = [int]((@($packagesChoco).Count / $totalPackages) * 100)
            $results += Measure-WinUtilStep -Scope "Install" -Name "choco $($packagesChoco -join ', ')" -ScriptBlock {
                Install-WinUtilProgramChoco -Action Install -Programs $packagesChoco -ProgressBase $chocoBase -ProgressSpan $chocoSpan
            }
            $completedPackages += @($packagesChoco).Count
            Step-WinUtilJob -Status "Installed Chocolatey packages ($completedPackages/$totalPackages)" -Percent ([int](($completedPackages / $totalPackages) * 100))
        }

        Complete-WinUtilPackageRun -Action "Install" -Results $results
    }
}
