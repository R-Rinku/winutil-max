function Invoke-WPFundoall {
    <#

    .SYNOPSIS
        Undoes every selected tweak

    #>

    $tweaks = $sync.selectedTweaks

    if ($tweaks.count -eq 0) {
        Show-WinUtilMessage -Message "Please check the tweaks you wish to undo." -Title "WinUtil" -Button "OK" -Icon "Warning"
        return
    }

    Start-WinUtilJob -Name "Undo tweaks" -Description "Undoing tweaks" -Parameters @{
        Tweaks = @($tweaks)
    } -ScriptBlock {
        param($Tweaks)

        $total = @($Tweaks).Count
        Write-WinUtilLog -Component "Tweaks" -Message "Undo tweaks requested: $total selected tweak(s)."
        $sync.CancelRequested = $false

        for ($i = 0; $i -lt $total; $i++) {
            if ($sync.CancelRequested) {
                Write-Host "`n[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [CANCELLED] Undo tweaks cancelled by user after $i step(s)." -ForegroundColor Yellow
                Write-WinUtilLog -Component "Tweaks" -Message "Undo tweaks cancelled by user after $i steps."
                Step-WinUtilJob -Status "Undo tweaks cancelled by user" -Percent ([int](($i / $total) * 100))
                break
            }

            Step-WinUtilJob -Status "Undoing $($Tweaks[$i]) ($($i + 1)/$total)" -Percent ([int](($i / $total) * 100))
            Measure-WinUtilStep -Scope "Undo tweaks" -Name $Tweaks[$i] -ScriptBlock {
                Invoke-WinUtiltweaks $Tweaks[$i] -undo $true
            }
            Step-WinUtilJob -Percent ([int]((($i + 1) / $total) * 100))
        }
    }
}
