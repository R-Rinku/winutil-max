function Invoke-WPFtweaksbutton {
  <#

    .SYNOPSIS
        Invokes the functions associated with each group of checkboxes

  #>

  $Tweaks = $sync.selectedTweaks
  $dnsProvider = $sync["WPFchangedns"].text
  if (-not ($dnsProvider)) {
    $dnsProvider = "Default"
  }

  if ($Tweaks.count -eq 0 -and $dnsProvider -eq "Default") {
    Show-WinUtilMessage -Message "Please check the tweaks you wish to perform." -Title "WinUtil" -Button "OK" -Icon "Warning"
    return
  }

  if ($sync.EnterpriseMode) {
    $enterpriseAllowedTweaks = @(
      "WPFTweaksRestorePoint",
      "WPFTweaksDiskCleanup",
      "WPFTweaksDeleteTempFiles",
      "WPFTweaksDeliveryOptimization",
      "WPFTweaksEndTaskOnTaskbar",
      "WPFTweaksWPBT",
      "WPFTweaksDisableExplorerAutoDiscovery"
    )
    $unsafeTweaks = @($Tweaks | Where-Object { $_ -notin $enterpriseAllowedTweaks })
    if ($unsafeTweaks.Count -gt 0) {
      Write-WinUtilLog -Component "Enterprise" -Message "Enterprise Mode blocked unsafe tweaks: $($unsafeTweaks -join ', ')" -Severity "Warning"
      Show-WinUtilMessage -Message "Enterprise Mode is active. High-risk tweaks are blocked by security policy and will not run:`n`n$($unsafeTweaks -join "`n")" -Title "Enterprise Policy" -Button "OK" -Icon "Warning"
      $Tweaks = @($Tweaks | Where-Object { $_ -in $enterpriseAllowedTweaks })
      if ($Tweaks.Count -eq 0) {
        return
      }
    }
  }

  Write-WinUtilLog -Component "Tweaks" -Message "Tweaks requested: $(@($Tweaks).Count) selected tweak(s), DNS provider: $dnsProvider"

  Start-WinUtilJob -Name "Tweaks" -Description "Applying tweaks" -Parameters @{
    Tweaks = @($Tweaks)
    DnsProvider = $dnsProvider
  } -ScriptBlock {
    param($Tweaks, $DnsProvider)

    # The restore point has to be taken before anything else changes
    $restorePointTweak = "WPFTweaksRestorePoint"
    $diskCleanupTweak = "WPFTweaksDiskCleanup"
    $hasDiskCleanup = $Tweaks -contains $diskCleanupTweak
    $tweaksToRun = @($Tweaks | Where-Object { $_ -ne $restorePointTweak -and $_ -ne $diskCleanupTweak })
    $totalSteps = [Math]::Max(@($Tweaks).Count, 1)
    $completedSteps = 0

    if ($Tweaks -contains $restorePointTweak) {
      Step-WinUtilJob -Status "Creating restore point" -Percent 0
      Write-WinUtilLog -Component "Tweaks" -Message "Creating restore point before applying selected tweaks."
      Measure-WinUtilStep -Scope "Tweaks" -Name $restorePointTweak -ScriptBlock {
        Invoke-WinUtilTweaks $restorePointTweak
      }
      $completedSteps = 1
    }

    if ($DnsProvider -ne "Default") {
      $dnsResult = Measure-WinUtilStep -Scope "Tweaks" -Name "Set DNS to $DnsProvider" -ScriptBlock {
        @(Set-WinUtilDNS -DNSProvider $DnsProvider)
      }

      # Carrying on after the DNS change failed leaves the machine half configured, so the run
      # ends here and the job layer reports it
      if (@($dnsResult)[-1] -ne $true) {
        throw "The DNS change to $DnsProvider failed, so the remaining tweaks were not applied."
      }
    }

    foreach ($tweak in $tweaksToRun) {
      Step-WinUtilJob -Status "Applying $tweak ($($completedSteps + 1)/$totalSteps)" -Percent ([int](($completedSteps / $totalSteps) * 100))
      Measure-WinUtilStep -Scope "Tweaks" -Name $tweak -ScriptBlock {
        Invoke-WinUtilTweaks $tweak
      }
      $completedSteps++
      Step-WinUtilJob -Percent ([int](($completedSteps / $totalSteps) * 100))
    }

    # Run Disk Cleanup at the very end of all tweaks as requested
    if ($hasDiskCleanup) {
      $noticeMsg = "Disk Cleanup: Notice - this may take several minutes depending on temp and update cache size."
      Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [NOTICE] Running Disk Cleanup at the end of tweaks. This may take several minutes depending on system temp and Windows Update cache..." -ForegroundColor Yellow
      Write-WinUtilLog -Component "Tweaks" -Message "Disk Cleanup scheduled at the end of tweaks. Running cleanmgr and component cleanup..."
      Step-WinUtilJob -Status $noticeMsg -Percent ([int](($completedSteps / $totalSteps) * 100))
      Start-Sleep -Seconds 2

      Step-WinUtilJob -Status "Running Disk Cleanup ($diskCleanupTweak)..." -Percent ([int](($completedSteps / $totalSteps) * 100))
      Measure-WinUtilStep -Scope "Tweaks" -Name $diskCleanupTweak -ScriptBlock {
        Invoke-WinUtilTweaks $diskCleanupTweak
      }
      $completedSteps++
      Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Disk Cleanup completed." -ForegroundColor Green
      Step-WinUtilJob -Percent 100
    }
  }
}
