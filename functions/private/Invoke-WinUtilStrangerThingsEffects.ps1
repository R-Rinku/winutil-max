function Get-WinUtilVecnaImage {
    <#
        .SYNOPSIS
            Retrieves or downloads the Vecna image and returns a WPF BitmapImage.
    #>
    [CmdletBinding()]
    param()

    if ($null -ne $script:WinUtilVecnaBitmapImage) {
        return $script:WinUtilVecnaBitmapImage
    }

    $candidates = @(
        ".\Vecna.jpg",
        (Join-Path (Get-Location).Path "Vecna.jpg"),
        "c:\Users\Rinku\Github\Windows-Tweaks-Hub\Vecna.jpg",
        (Join-Path $env:LOCALAPPDATA "winutil\Vecna.jpg")
    )
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidates = @(
            (Join-Path $PSScriptRoot "Vecna.jpg"),
            (Join-Path $PSScriptRoot "..\..\Vecna.jpg")
        ) + $candidates
    }

    foreach ($path in $candidates) {
        if (-not [string]::IsNullOrWhiteSpace($path) -and (Test-Path -LiteralPath $path -ErrorAction SilentlyContinue)) {
            try {
                $bytes = [System.IO.File]::ReadAllBytes((Resolve-Path -LiteralPath $path).Path)
                $ms = New-Object System.IO.MemoryStream(,$bytes)
                $img = New-Object System.Windows.Media.Imaging.BitmapImage
                $img.BeginInit()
                $img.StreamSource = $ms
                $img.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $img.EndInit()
                if ($img.CanFreeze) { $img.Freeze() }
                $script:WinUtilVecnaBitmapImage = $img
                return $img
            } catch {
                # Fall through to next candidate
            }
        }
    }

    # Attempt download from remote if running via web
    try {
        $cacheDir = Join-Path $env:LOCALAPPDATA "winutil"
        if (-not (Test-Path -LiteralPath $cacheDir)) {
            New-Item -ItemType Directory -Path $cacheDir -Force | Out-Null
        }
        $cachedPath = Join-Path $cacheDir "Vecna.jpg"
        $urls = @(
            "https://raw.githubusercontent.com/R-Rinku/winutil-max/main/Vecna.jpg",
            "https://rinkurapria.dev/Vecna.jpg"
        )
        foreach ($url in $urls) {
            try {
                Invoke-WebRequest -Uri $url -OutFile $cachedPath -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
                if (Test-Path -LiteralPath $cachedPath) {
                    $bytes = [System.IO.File]::ReadAllBytes($cachedPath)
                    $ms = New-Object System.IO.MemoryStream(,$bytes)
                    $img = New-Object System.Windows.Media.Imaging.BitmapImage
                    $img.BeginInit()
                    $img.StreamSource = $ms
                    $img.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                    $img.EndInit()
                    if ($img.CanFreeze) { $img.Freeze() }
                    $script:WinUtilVecnaBitmapImage = $img
                    return $img
                }
            } catch {}
        }
    } catch {}

    return $null
}

function Invoke-WinUtilVecnaExit {
    <#
        .SYNOPSIS
            Displays the Vecna exit screen when the user closes the window.
            Returns $true if the screen was shown and close was deferred, $false if already handled.
    #>
    [CmdletBinding()]
    param()

    if ($null -eq $sync -or $null -eq $sync.WPFVecnaOverlay) {
        return $false
    }

    if ($script:WinUtilVecnaExitHandled) {
        return $false
    }

    $script:WinUtilVecnaExitHandled = $true

    try {
        $img = Get-WinUtilVecnaImage
        if ($null -ne $img -and $null -ne $sync.WPFVecnaImage) {
            $sync.WPFVecnaImage.Source = $img
        }

        if ($null -ne $sync.WPFVecnaHeader) {
            $sync.WPFVecnaHeader.Text = "VECNA IS WATCHING..."
        }
        if ($null -ne $sync.WPFVecnaMessage) {
            $sync.WPFVecnaMessage.Text = "You cannot escape the Upside Down... Closing WinUtil."
        }
        if ($null -ne $sync.WPFVecnaDismissButton) {
            $sync.WPFVecnaDismissButton.Content = "Exit Now"
            $sync.WPFVecnaDismissButton.Add_Click({
                $sync.Form.Close()
            })
        }

        $sync.WPFVecnaOverlay.Visibility = [System.Windows.Visibility]::Visible

        # Auto close after 2.0 seconds if user does not click Exit Now
        $autoCloseTimer = New-Object System.Windows.Threading.DispatcherTimer
        $autoCloseTimer.Interval = [TimeSpan]::FromSeconds(2.0)
        $autoCloseTimer.Add_Tick({
            $this.Stop()
            if (Test-WinUtilUIAlive) {
                $sync.Form.Close()
            }
        })
        $autoCloseTimer.Start()

        return $true
    } catch {
        return $false
    }
}

function Invoke-WinUtilVecnaCompletion {
    <#
        .SYNOPSIS
            Displays the Vecna screen when operations/scripts finish.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$JobLabel = "Operations"
    )

    if (-not (Test-WinUtilUIAlive) -or $null -eq $sync.WPFVecnaOverlay) {
        return
    }

    Invoke-WPFUIThread -Async -ScriptBlock {
        try {
            $img = Get-WinUtilVecnaImage
            if ($null -ne $img -and $null -ne $sync.WPFVecnaImage) {
                $sync.WPFVecnaImage.Source = $img
            }

            if ($null -ne $sync.WPFVecnaHeader) {
                $sync.WPFVecnaHeader.Text = "RUNNING UP THAT HILL"
            }
            if ($null -ne $sync.WPFVecnaMessage) {
                $sync.WPFVecnaMessage.Text = "$JobLabel completed successfully! You have escaped the Upside Down."
            }
            if ($null -ne $sync.WPFVecnaDismissButton) {
                $sync.WPFVecnaDismissButton.Content = "Continue"
                $sync.WPFVecnaDismissButton.Add_Click({
                    if ($null -ne $sync.WPFVecnaOverlay) {
                        $sync.WPFVecnaOverlay.Visibility = [System.Windows.Visibility]::Collapsed
                    }
                })
            }

            $sync.WPFVecnaOverlay.Visibility = [System.Windows.Visibility]::Visible
        } catch {}
    }
}
