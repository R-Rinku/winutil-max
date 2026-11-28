function Invoke-WPFImpex {
    <#

    .SYNOPSIS
        Handles importing and exporting of configurations, selections, and WinUtil-MAX settings.

    .PARAMETER type
        Indicates whether to 'import' or 'export'

    .PARAMETER Config
        Path or URL to JSON configuration file

    .PARAMETER Merge
        Add to the current selection instead of replacing it.

    .PARAMETER ThrowOnError
        Fail rather than applying a partial request (for headless runs).

    .EXAMPLE
        Invoke-WPFImpex -type "export"

    #>
    param(
        $type,
        $Config = $null,
        [switch]$Merge,
        [switch]$ThrowOnError
    )

    function ConfigDialog {
        if (!$Config) {
            $FileBrowser = switch ($type) {
                "export" { New-Object Microsoft.Win32.SaveFileDialog }
                "import" { New-Object Microsoft.Win32.OpenFileDialog }
            }
            $FileBrowser.InitialDirectory = [Environment]::GetFolderPath('Desktop')
            $FileBrowser.Filter = "JSON Files (*.json)|*.json"
            $dialogResult = if ($sync.Form) { $FileBrowser.ShowDialog($sync.Form) } else { $FileBrowser.ShowDialog() }

            if ($dialogResult -ne $true -or [string]::IsNullOrWhiteSpace($FileBrowser.FileName)) {
                return $null
            } else {
                return $FileBrowser.FileName
            }
        } else {
            return $Config
        }
    }

    function Export-WinUtilMaxProfileData {
        $profile = [ordered]@{}

        # 1. BitLocker Startup Password Policy (No TPM / Dual Boot)
        $fveKey = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
        $blEnabled = $false
        if (Test-Path -LiteralPath $fveKey) {
            $useAdv = Get-ItemPropertyValue -Path $fveKey -Name "UseAdvancedStartup" -ErrorAction SilentlyContinue
            $noTpm  = Get-ItemPropertyValue -Path $fveKey -Name "EnableBDEWithNoTPM" -ErrorAction SilentlyContinue
            $pass   = Get-ItemPropertyValue -Path $fveKey -Name "OSPassphrase" -ErrorAction SilentlyContinue
            if ($useAdv -eq 1 -and $noTpm -eq 1 -and $pass -eq 1) {
                $blEnabled = $true
            }
        }
        $profile["BitLockerStartupPasswordPolicy"] = [ordered]@{
            Configured             = $blEnabled
            UseAdvancedStartup     = 1
            EnableBDEWithNoTPM     = 1
            OSPassphrase           = 1
            OSPassphraseLength     = 8
            OSPassphraseComplexity = 0
            UseTPM                 = 2
            UseTPMPIN              = 2
            UseTPMKey              = 2
            UseTPMKeyPIN           = 2
        }

        # 2. OneDrive Sync Exclusions
        $odFolderRules = @()
        $odFileRules = @()
        $folderKeys = @(
            "HKCU:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreFolderListFromGPO",
            "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreFolderListFromGPO"
        )
        foreach ($fk in $folderKeys) {
            if (Test-Path -LiteralPath $fk) {
                $item = Get-Item -LiteralPath $fk -ErrorAction SilentlyContinue
                if ($item) {
                    foreach ($prop in $item.Property) {
                        $val = $item.GetValue($prop)
                        $odFolderRules += [ordered]@{ Name = [string]$prop; Value = [string]$val }
                    }
                }
            }
        }
        $fileKeys = @(
            "HKCU:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO",
            "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO"
        )
        foreach ($fk in $fileKeys) {
            if (Test-Path -LiteralPath $fk) {
                $item = Get-Item -LiteralPath $fk -ErrorAction SilentlyContinue
                if ($item) {
                    foreach ($prop in $item.Property) {
                        $val = $item.GetValue($prop)
                        $odFileRules += [ordered]@{ Name = [string]$prop; Value = [string]$val }
                    }
                }
            }
        }
        $profile["OneDriveSyncExclusions"] = [ordered]@{
            FolderPolicies = @($odFolderRules | Select-Object -Unique Name, Value)
            FilePolicies   = @($odFileRules | Select-Object -Unique Name, Value)
        }

        # 3. Take Full Ownership Context Menu
        $profile["TakeOwnershipContextMenu"] = [bool](Test-Path "Registry::HKEY_CLASSES_ROOT\*\shell\TakeOwnership")

        # 4. Desktop Shortcut
        $profile["DesktopShortcut"] = [bool](
            (Test-Path (Join-Path ([Environment]::GetFolderPath('Desktop')) 'WinUtil-MAX.lnk')) -or
            (Test-Path (Join-Path $env:USERPROFILE 'Desktop\WinUtil-MAX.lnk')) -or
            (Test-Path (Join-Path $env:USERPROFILE 'OneDrive\Desktop\WinUtil-MAX.lnk'))
        )

        return $profile
    }

    function Import-WinUtilMaxProfileData {
        param($MaxProfile)

        $restoredItems = [System.Collections.Generic.List[string]]::new()
        if (-not $MaxProfile) { return $restoredItems }

        # 1. Restore BitLocker Startup Password Policy
        $bl = if ($MaxProfile.BitLockerStartupPasswordPolicy) { $MaxProfile.BitLockerStartupPasswordPolicy } else { $MaxProfile.BitLockerPolicy }
        if ($bl -and ($bl.Configured -or $bl.Enabled -or $bl.UseAdvancedStartup -eq 1)) {
            try {
                $fveKey = "HKLM:\SOFTWARE\Policies\Microsoft\FVE"
                if (-not (Test-Path -LiteralPath $fveKey)) {
                    New-Item -Path $fveKey -Force -ErrorAction SilentlyContinue | Out-Null
                }
                Set-ItemProperty -Path $fveKey -Name "UseAdvancedStartup" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $fveKey -Name "EnableBDEWithNoTPM" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $fveKey -Name "UseTPM" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $fveKey -Name "UseTPMPIN" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $fveKey -Name "UseTPMKey" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $fveKey -Name "UseTPMKeyPIN" -Value 2 -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $fveKey -Name "OSPassphrase" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
                $pLen = if ($bl.OSPassphraseLength) { [int]$bl.OSPassphraseLength } else { 8 }
                Set-ItemProperty -Path $fveKey -Name "OSPassphraseLength" -Value $pLen -Type DWord -Force -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $fveKey -Name "OSPassphraseComplexity" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

                Write-WinUtilLog -Component "Impex" -Message "Restored BitLocker Startup Password Policy (No TPM / Dual Boot)."
                $restoredItems.Add("BitLocker Startup Password Policy (No TPM / Dual Boot configured)")
            } catch {
                Write-WinUtilLog -Level "WARN" -Component "Impex" -Message "Failed to restore BitLocker policy: $_"
            }
        }

        # 2. Restore OneDrive Exclusions
        $od = if ($MaxProfile.OneDriveSyncExclusions) { $MaxProfile.OneDriveSyncExclusions } else { $MaxProfile.OneDriveExclusions }
        if ($od) {
            $fCount = 0
            if ($od.FolderPolicies) {
                $uFolderKey = "HKCU:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreFolderListFromGPO"
                if (-not (Test-Path -LiteralPath $uFolderKey)) { New-Item -Path $uFolderKey -Force -ErrorAction SilentlyContinue | Out-Null }
                foreach ($rule in $od.FolderPolicies) {
                    if ($rule.Name -and $rule.Value) {
                        Set-ItemProperty -Path $uFolderKey -Name $rule.Name -Value $rule.Value -Type String -Force -ErrorAction SilentlyContinue
                        $fCount++
                    }
                }
            }
            $fileCount = 0
            if ($od.FilePolicies) {
                $uFileKey = "HKCU:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO"
                if (-not (Test-Path -LiteralPath $uFileKey)) { New-Item -Path $uFileKey -Force -ErrorAction SilentlyContinue | Out-Null }
                foreach ($rule in $od.FilePolicies) {
                    if ($rule.Name -and $rule.Value) {
                        Set-ItemProperty -Path $uFileKey -Name $rule.Name -Value $rule.Value -Type String -Force -ErrorAction SilentlyContinue
                        $fileCount++
                    }
                }
            }
            if ($fCount -gt 0 -or $fileCount -gt 0) {
                Write-WinUtilLog -Component "Impex" -Message "Restored $fCount folder and $fileCount file OneDrive exclusion rules."
                $restoredItems.Add("OneDrive Sync Exclusions ($($fCount + $fileCount) rules restored)")
                Get-Process "OneDrive" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Milliseconds 250
                $odExe = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
                if (Test-Path -LiteralPath $odExe) {
                    Start-Process -FilePath $odExe -ArgumentList "/background" -ErrorAction SilentlyContinue
                }
            }
        }

        # 3. Restore Take Ownership Context Menu
        if ($MaxProfile.TakeOwnershipContextMenu -or $MaxProfile.TakeOwnership) {
            try {
                if (Get-Command "Invoke-WPFTakeOwnershipAdd" -ErrorAction SilentlyContinue) {
                    Invoke-WPFTakeOwnershipAdd
                    $restoredItems.Add("Take Full Ownership Explorer Context Menu")
                }
            } catch {
                Write-WinUtilLog -Level "WARN" -Component "Impex" -Message "Failed to restore Take Ownership context menu: $_"
            }
        }

        # 4. Restore Desktop Shortcut
        if ($MaxProfile.DesktopShortcut) {
            try {
                if (Get-Command "Invoke-WinUtilDesktopShortcut" -ErrorAction SilentlyContinue) {
                    Invoke-WinUtilDesktopShortcut
                    $restoredItems.Add("WinUtil-MAX Desktop Shortcut (Max Mayfield Icon)")
                }
            } catch {
                Write-WinUtilLog -Level "WARN" -Component "Impex" -Message "Failed to restore Desktop Shortcut: $_"
            }
        }

        return $restoredItems
    }

    switch ($type) {
        "export" {
            try {
                $Config = ConfigDialog
                if ($Config) {
                    $selectedMax = if ($sync.selectedMax) { $sync.selectedMax } else { @() }
                    $allConfs = ($sync.selectedApps + $sync.selectedTweaks + $sync.selectedToggles + $sync.selectedFeatures + $sync.selectedAppx + $selectedMax) | ForEach-Object { [string]$_ }

                    $maxProfile = Export-WinUtilMaxProfileData
                    $hasMax = ($maxProfile.BitLockerStartupPasswordPolicy.Configured -or
                              ($maxProfile.OneDriveSyncExclusions.FolderPolicies.Count -gt 0) -or
                              ($maxProfile.OneDriveSyncExclusions.FilePolicies.Count -gt 0) -or
                              $maxProfile.TakeOwnershipContextMenu -or
                              $maxProfile.DesktopShortcut)

                    if ((-not $allConfs -or $allConfs.Count -eq 0) -and -not $hasMax) {
                        Show-WinUtilMessage -Message (
                            "No settings are selected to export. Please select at least one app, tweak, toggle, feature, or AppX package before exporting."
                        ) -Title "Nothing to Export" -Button "OK" -Icon "Warning" | Out-Null
                        return
                    }

                    $exportPayload = [ordered]@{
                        Version    = "winutil-max-2.0"
                        ExportDate = (Get-Date).ToString("o")
                        Selections = @($allConfs)
                        MaxProfile = $maxProfile
                    }

                    $jsonFile = $exportPayload | ConvertTo-Json -Depth 10
                    $jsonFile | Out-File $Config -Force -Encoding utf8
                    "iex ""& { `$(irm https://raw.githubusercontent.com/R-Rinku/winutil-max/main/winutil.ps1) } -Config '$Config'""" | Set-Clipboard

                    if ($sync.Form) {
                        $exportMsg = "WinUtil-MAX Configuration Exported Successfully!`n`n" +
                                     "Saved to:`n$Config`n`n" +
                                     "Included in this backup:`n" +
                                     "- $($allConfs.Count) Selected Apps & Tweaks`n"
                        if ($maxProfile.BitLockerStartupPasswordPolicy.Configured) {
                            $exportMsg += "- BitLocker Dual-Boot Startup Password Policy`n"
                        }
                        $totalOd = $maxProfile.OneDriveSyncExclusions.FolderPolicies.Count + $maxProfile.OneDriveSyncExclusions.FilePolicies.Count
                        if ($totalOd -gt 0) {
                            $exportMsg += "- $totalOd OneDrive Sync Exclusion Rules`n"
                        }
                        if ($maxProfile.TakeOwnershipContextMenu) {
                            $exportMsg += "- Take Full Ownership Explorer Context Menu`n"
                        }
                        if ($maxProfile.DesktopShortcut) {
                            $exportMsg += "- WinUtil-MAX Desktop Shortcut`n"
                        }
                        $exportMsg += "`nThe 1-click restore command has also been copied to your clipboard!"
                        Show-WinUtilMessage -Message $exportMsg -Title "Configuration Exported" -Button "OK" -Icon "Information" | Out-Null
                    }
                }
            } catch {
                Write-Error "An error occurred while exporting: $_"
            }
        }
        "import" {
            $prevImport = $sync.ImportInProgress
            $sync.ImportInProgress = $true
            try {
                $Config = ConfigDialog
                if ($Config) {
                    try {
                        if ($Config -match '^https?://') {
                            $jsonFile = (Invoke-WebRequest "$Config" -ErrorAction Stop).Content | ConvertFrom-Json
                        } else {
                            $jsonFile = Get-Content $Config -ErrorAction Stop | ConvertFrom-Json
                        }
                    } catch {
                        $message = "Failed to load the JSON file from the specified path or URL: $_"
                        if ($ThrowOnError) { throw $message }
                        Write-Error $message
                        return
                    }

                    $flattenedJson = @()
                    $maxProfileData = $null
                    $isLegacyConfig = $false

                    # Case 1: WinUtil-MAX 2.0 structured config
                    if ($jsonFile -is [System.Management.Automation.PSCustomObject] -and
                        ($null -ne $jsonFile.PSObject.Properties["Selections"] -or
                         $null -ne $jsonFile.PSObject.Properties["MaxProfile"] -or
                         $null -ne $jsonFile.PSObject.Properties["MaxSettings"])) {
                        
                        Write-WinUtilLog -Component "Impex" -Message "Detected WinUtil-MAX 2.0 configuration structure."
                        if ($jsonFile.Selections) {
                            $flattenedJson = @($jsonFile.Selections | Where-Object { [string]$_ })
                        }
                        $maxProfileData = if ($jsonFile.MaxProfile) { $jsonFile.MaxProfile } else { $jsonFile.MaxSettings }
                    }
                    # Case 2: Legacy WinUtil config structure (Install & WPFInstall properties)
                    elseif ($jsonFile -is [System.Management.Automation.PSCustomObject] -and
                        $null -ne $jsonFile.PSObject.Properties["Install"] -and
                        $null -ne $jsonFile.PSObject.Properties["WPFInstall"]) {
                        $isLegacyConfig = $true
                        Write-WinUtilLog -Component "Impex" -Message "Detected legacy WinUtil config structure; flattening import object."
                        $flattenedJson = @(
                            foreach ($property in $jsonFile.PSObject.Properties) {
                                if ($property.Name -notmatch '^WPF(?:Install|Tweaks|Toggle|Feature|Appx|Max)') {
                                    continue
                                }
                                foreach ($selection in @($property.Value)) {
                                    if ($selection -is [string] -and -not [string]::IsNullOrWhiteSpace($selection)) {
                                        $selection
                                    }
                                }
                            }
                        )
                    }
                    # Case 3: Flat array of selection strings
                    else {
                        $flattenedJson = @($jsonFile | Where-Object { [string]$_ })
                    }

                    if ((-not $flattenedJson -or $flattenedJson.Count -eq 0) -and -not $maxProfileData) {
                        Show-WinUtilMessage -Message "The selected file contains no settings to import. No changes have been made." -Title "Empty Configuration" -Button "OK" -Icon "Warning" | Out-Null
                        return
                    }

                    # Replace unless this import is merging onto something already selected
                    $replaceMode = @{}
                    if (-not $Merge) { $replaceMode["Replace"] = $true }

                    # Modern configs stay strict. Legacy configs can reference entries that no
                    # longer exist, so restore supported selections and report the retired keys.
                    if ($isLegacyConfig) {
                        $skippedSelections = @(Update-WinUtilSelections -flatJson $flattenedJson @replaceMode -SkipUnknown)

                        if ($skippedSelections.Count -gt 0) {
                            $skippedSummary = $skippedSelections -join ", "
                            Write-WinUtilLog -Component "Impex" -Level "WARN" -Message "Skipped unsupported legacy selections: $skippedSummary"
                        }

                        if ($skippedSelections.Count -eq @($flattenedJson).Count) {
                            if ($sync.Form) {
                                Show-WinUtilMessage -Message "This legacy configuration contains no settings supported by this version of WinUtil. No changes have been made." -Title "Unsupported Legacy Configuration" -Icon "Warning" | Out-Null
                            }
                            return
                        }

                        if ($skippedSelections.Count -gt 0) {
                            $skippedDisplay = @($skippedSelections | Select-Object -First 10) -join ", "
                            if ($skippedSelections.Count -gt 10) {
                                $skippedDisplay += "`n...and $($skippedSelections.Count - 10) more. See the WinUtil log for details."
                            }
                            if ($sync.Form) {
                                Show-WinUtilMessage -Message "Supported settings were imported. The following retired settings were skipped:`n`n$skippedDisplay" -Title "Legacy Configuration Partially Imported" -Icon "Warning" | Out-Null
                            }
                        }
                    } else {
                        # Build and validate every imported selection before replacing the current state.
                        Update-WinUtilSelections -flatJson $flattenedJson @replaceMode
                    }

                    # Restore WinUtil-MAX Profile Settings (BitLocker, OneDrive, Context Menu, Shortcut)
                    $restoredMax = @()
                    if ($maxProfileData) {
                        $restoredMax = Import-WinUtilMaxProfileData -MaxProfile $maxProfileData
                    }

                    if ($sync.Form) {
                        Reset-WPFCheckBoxes -doToggles $true

                        if ($restoredMax.Count -gt 0) {
                            $summaryMsg = "WinUtil-MAX Configuration Imported Successfully!`n`n"
                            if ($flattenedJson.Count -gt 0) {
                                $summaryMsg += "- $($flattenedJson.Count) Selections restored (Apps, Tweaks, Features)`n"
                            }
                            $summaryMsg += "- WinUtil-MAX System Configurations Restored:`n"
                            foreach ($item in $restoredMax) {
                                $summaryMsg += "   * $item`n"
                            }
                            $summaryMsg += "`nYour system and selections are now fully restored!"
                            Show-WinUtilMessage -Message $summaryMsg -Title "Configuration Restored" -Button "OK" -Icon "Information" | Out-Null
                        }
                    }
                }
            } catch {
                if ($ThrowOnError) { throw }
                Write-Error "An error occurred while importing: $_"
            } finally {
                $sync.ImportInProgress = $prevImport
            }
        }
    }
}
