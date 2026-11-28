#===========================================================================
# Tests - WinUtil-MAX Desktop Shortcut & Extended Impex
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\public\Invoke-WinUtilDesktopShortcut.ps1")
    . (Join-Path $script:repoRoot "functions\private\Update-WinUtilSelections.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFImpex.ps1")

    function Write-WinUtilLog { param($Message, $Level, $Component) }
    function Test-WinUtilUIAlive { return $false }
    function Show-WinUtilMessage { param($Title, $Message, $Button, $Icon) }
}

Describe "WinUtil-MAX Desktop Shortcut" {
    It "max.json contains WPFMaxDesktopShortcut and WPFMaxDesktopShortcutRemove" {
        $maxJsonPath = Join-Path $script:repoRoot "config\max.json"
        $maxConfig = Get-Content -LiteralPath $maxJsonPath -Raw | ConvertFrom-Json
        
        $shortcutEntry = $maxConfig.WPFMaxDesktopShortcut
        $shortcutEntry | Should -Not -BeNullOrEmpty
        $shortcutEntry.function | Should -Be "Invoke-WinUtilDesktopShortcut"
        $shortcutEntry.Content | Should -Match "Desktop Shortcut"

        $removeEntry = $maxConfig.WPFMaxDesktopShortcutRemove
        $removeEntry | Should -Not -BeNullOrEmpty
        $removeEntry.function | Should -Match "Invoke-WinUtilDesktopShortcut -Remove"
    }

    It "creates shortcut pointing to powershell bypass command with max icon" {
        $mockShortcut = [pscustomobject]@{
            TargetPath = ""
            Arguments = ""
            Description = ""
            WorkingDirectory = ""
            IconLocation = ""
        }
        $mockShortcut | Add-Member -MemberType ScriptMethod -Name "Save" -Value {
            $script:shortcutSaved = $true
        }

        $mockWsh = [pscustomobject]@{}
        $mockWsh | Add-Member -MemberType ScriptMethod -Name "CreateShortcut" -Value {
            param($path)
            $script:capturedPath = $path
            return $mockShortcut
        }

        $script:shortcutSaved = $false
        $script:capturedPath = $null

        Mock New-Object {
            if ($ComObject -eq "WScript.Shell") {
                return $mockWsh
            }
            return (Microsoft.PowerShell.Utility\New-Object @args)
        }

        Invoke-WinUtilDesktopShortcut

        $script:capturedPath | Should -Match "WinUtil-MAX\.lnk"
        $mockShortcut.TargetPath | Should -Match "powershell\.exe"
        $mockShortcut.Arguments | Should -Match "ExecutionPolicy Bypass"
        $mockShortcut.Arguments | Should -Match "winutil-max"
        $mockShortcut.IconLocation | Should -Match "winutil_max\.ico"
        $script:shortcutSaved | Should -Be $true
    }
}

Describe "WinUtil-MAX Extended Profile Impex" {
    BeforeEach {
        $global:sync = [Hashtable]::Synchronized(@{
            selectedApps = [System.Collections.Generic.List[string]]::new()
            selectedTweaks = [System.Collections.Generic.List[string]]::new()
            selectedToggles = [System.Collections.Generic.List[string]]::new()
            selectedFeatures = [System.Collections.Generic.List[string]]::new()
            selectedAppx = [System.Collections.Generic.List[string]]::new()
            selectedMax = [System.Collections.Generic.List[string]]::new()
            configs = @{
                applicationsHashtable = @{ WPFInstallGit = [pscustomobject]@{ Content = "Git" } }
                appxHashtable = @{ WPFAppxSample = [pscustomobject]@{} }
                tweaks = [pscustomobject]@{ WPFTweaksSample = [pscustomobject]@{} }
                feature = [pscustomobject]@{ WPFFeatureSample = [pscustomobject]@{} }
                max = [pscustomobject]@{ WPFMaxBitLockerPolicy = [pscustomobject]@{} }
            }
            ImportInProgress = $false
        })
    }

    It "imports WinUtil-MAX 2.0 structured profile without errors" {
        $tempJson = [System.IO.Path]::GetTempFileName()
        try {
            $testConfig = [ordered]@{
                Version = "winutil-max-2.0"
                Selections = @("WPFInstallGit", "WPFTweaksSample")
                MaxProfile = @{
                    BitLockerStartupPasswordPolicy = @{
                        Configured = $true
                        UseAdvancedStartup = 1
                    }
                    TakeOwnershipContextMenu = $false
                    DesktopShortcut = $false
                }
            }
            $testConfig | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $tempJson -Encoding utf8

            Invoke-WPFImpex -type "import" -Config $tempJson -ThrowOnError

            @($global:sync.selectedApps) | Should -Contain "WPFInstallGit"
            @($global:sync.selectedTweaks) | Should -Contain "WPFTweaksSample"
        } finally {
            if (Test-Path -LiteralPath $tempJson) { Remove-Item -LiteralPath $tempJson -Force }
        }
    }
}
