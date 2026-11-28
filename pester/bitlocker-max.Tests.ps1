#===========================================================================
# Tests - WinUtil-MAX BitLocker Startup Password Policy
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    . (Join-Path $script:repoRoot "functions\public\Invoke-WinUtilBitLocker.ps1")

    function Write-WinUtilLog { param($Message, $Level, $Component) }
    function Test-WinUtilUIAlive { return $false }
    function Show-WinUtilMessage { param($Title, $Message, $Button, $Icon) }
}

Describe "BitLocker Startup Password Policy" {
    It "configures HKLM FVE policy keys for pre-boot startup password and non-TPM" {
        $capturedSetItemProperty = [System.Collections.Generic.List[hashtable]]::new()

        Mock Test-Path { return $true }
        Mock Set-ItemProperty {
            $capturedSetItemProperty.Add(@{
                Path  = $Path
                Name  = $Name
                Value = $Value
                Type  = $Type
            })
        }
        Mock Start-Process { }
        Mock Write-WinUtilLog { }

        Invoke-WinUtilBitLockerPolicy

        $capturedNames = $capturedSetItemProperty | ForEach-Object { $_.Name }
        $capturedNames | Should -Contain "UseAdvancedStartup"
        $capturedNames | Should -Contain "EnableBDEWithNoTPM"
        $capturedNames | Should -Contain "OSPassphrase"
        $capturedNames | Should -Contain "OSPassphraseLength"

        $enableBDE = $capturedSetItemProperty | Where-Object { $_.Name -eq "EnableBDEWithNoTPM" }
        $enableBDE.Value | Should -Be 1

        $osPassphrase = $capturedSetItemProperty | Where-Object { $_.Name -eq "OSPassphrase" }
        $osPassphrase.Value | Should -Be 1
    }

    It "max.json contains WPFMaxBitLockerPolicy pointing to Invoke-WinUtilBitLockerPolicy" {
        $maxJsonPath = Join-Path $script:repoRoot "config\max.json"
        $maxConfig = Get-Content -LiteralPath $maxJsonPath -Raw | ConvertFrom-Json
        $bitlockerEntry = $maxConfig.WPFMaxBitLockerPolicy

        $bitlockerEntry | Should -Not -BeNullOrEmpty
        $bitlockerEntry.function | Should -Be "Invoke-WinUtilBitLockerPolicy"
        $bitlockerEntry.Content | Should -Match "Password"
    }
}
