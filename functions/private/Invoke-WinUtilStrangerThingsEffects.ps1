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

function Start-WinUtilStrangerThingsAudio {
    <#
        .SYNOPSIS
            Generates and plays a themed Stranger Things horror audio effect in the background.
    #>
    param(
        [Parameter()]
        [ValidateSet("BatLaunch", "VecnaExit", "Victory")]
        [string]$Theme = "BatLaunch"
    )

    [System.Threading.ThreadPool]::QueueUserWorkItem([System.Threading.WaitCallback]{
        try {
            $sampleRate = 11025
            $durationSec = 2.0
            if ($Theme -eq "VecnaExit") { $durationSec = 1.6 }
            elseif ($Theme -eq "Victory") { $durationSec = 1.4 }

            $totalSamples = [int]($sampleRate * $durationSec)
            $data = New-Object byte[] $totalSamples

            for ($i = 0; $i -lt $totalSamples; $i++) {
                $t = $i / $sampleRate
                $sampleVal = 0.0

                if ($Theme -eq "BatLaunch") {
                    # Low Stranger Things drone
                    $drone = [math]::Sin(2 * [math]::PI * 82 * $t) * 0.4
                    # 16Hz Demobat wing fluttering modulation
                    $flutter = (1 + [math]::Sin(2 * [math]::PI * 16 * $t)) * 0.5
                    # High bat screech sweep
                    $chirp = 0.0
                    if ($t -ge 0.3 -and $t -le 1.4) {
                        $chirpTime = $t - 0.3
                        $freq = 1500 - ($chirpTime * 650)
                        $chirp = [math]::Sin(2 * [math]::PI * $freq * $t) * 0.32 * [math]::Sin([math]::PI * ($chirpTime / 1.1))
                    }
                    $env = 1.0
                    if ($t -lt 0.2) { $env = $t / 0.2 }
                    elseif ($t -gt 1.6) { $env = [math]::Max(0.0, (2.0 - $t) / 0.4) }
                    $sampleVal = (($drone * $flutter) + $chirp) * $env
                }
                elseif ($Theme -eq "VecnaExit") {
                    # Deep ominous sub-bass drone with slow warble
                    $sub = [math]::Sin(2 * [math]::PI * 55 * $t) * 0.6
                    $pulse = (1 + [math]::Sin(2 * [math]::PI * 4 * $t)) * 0.5
                    $clockChime = [math]::Sin(2 * [math]::PI * 110 * $t) * 0.3 * [math]::Exp(-2.5 * $t)
                    $env = 1.0
                    if ($t -gt 1.2) { $env = [math]::Max(0.0, (1.6 - $t) / 0.4) }
                    $sampleVal = (($sub * $pulse) + $clockChime) * $env
                }
                else {
                    # Victory synth arpeggio
                    $step = [int]($t * 8) % 4
                    $freqs = @(261.63, 329.63, 392.00, 493.88) # C4, E4, G4, B4 (Stranger Things synth arpeggio)
                    $freq = $freqs[$step]
                    $env = [math]::Max(0.0, 1.0 - ($t / 1.4))
                    $sampleVal = [math]::Sin(2 * [math]::PI * $freq * $t) * 0.45 * $env
                }

                $sampleVal = [math]::Max(-1.0, [math]::Min(1.0, $sampleVal))
                $data[$i] = [byte]([math]::Round(($sampleVal * 120) + 128))
            }

            $ms = New-Object System.IO.MemoryStream
            $bw = New-Object System.IO.BinaryWriter $ms
            $bw.Write([System.Text.Encoding]::ASCII.GetBytes('RIFF'))
            $bw.Write([int](36 + $totalSamples))
            $bw.Write([System.Text.Encoding]::ASCII.GetBytes('WAVE'))
            $bw.Write([System.Text.Encoding]::ASCII.GetBytes('fmt '))
            $bw.Write([int]16)
            $bw.Write([int16]1) # PCM
            $bw.Write([int16]1) # Mono
            $bw.Write([int]$sampleRate)
            $bw.Write([int]$sampleRate)
            $bw.Write([int16]1) # BlockAlign
            $bw.Write([int16]8) # BitsPerSample
            $bw.Write([System.Text.Encoding]::ASCII.GetBytes('data'))
            $bw.Write([int]$totalSamples)
            $bw.Write($data)
            $bw.Flush()
            $ms.Position = 0

            $player = New-Object System.Media.SoundPlayer $ms
            $player.PlaySync()
            $player.Dispose()
            $bw.Dispose()
            $ms.Dispose()
        } catch {
            # Audio is a progressive enhancement; fail silently if sound hardware is unavailable
        }
    }) | Out-Null
}

function Start-WinUtilBatLaunchAnimation {
    <#
        .SYNOPSIS
            Animates the Demobats flying across the launching overlay, plays sound, and fades out.
    #>
    [CmdletBinding()]
    param()

    if ($null -eq $sync -or $null -eq $sync.WPFLaunchOverlay) {
        return
    }

    # Start the sound effect in the background
    Start-WinUtilStrangerThingsAudio -Theme "BatLaunch"

    # Smooth animation timer
    $clock = [System.Diagnostics.Stopwatch]::StartNew()
    $timer = New-Object System.Windows.Threading.DispatcherTimer
    $timer.Interval = [TimeSpan]::FromMilliseconds(20)

    $timer.Add_Tick({
        $elapsed = $clock.Elapsed.TotalSeconds

        # Demobat 1 (Large leader bat flying from top-left across screen)
        if ($null -ne $sync.WPFDemobat1 -and $null -ne $sync.WPFDemobat1.RenderTransform) {
            $tg1 = $sync.WPFDemobat1.RenderTransform
            $flap1 = $tg1.Children[0]
            $pos1 = $tg1.Children[2]
            $flap1.ScaleY = 0.5 + 0.5 * [math]::Abs([math]::Sin($elapsed * 26))
            $pos1.X = -120 + ($elapsed / 2.2) * 1450
            $pos1.Y = 80 + 35 * [math]::Sin($elapsed * 5)
        }

        # Demobat 2 (Swarm bat 2 flying from top-right towards bottom-left)
        if ($null -ne $sync.WPFDemobat2 -and $null -ne $sync.WPFDemobat2.RenderTransform) {
            $tg2 = $sync.WPFDemobat2.RenderTransform
            $flap2 = $tg2.Children[0]
            $pos2 = $tg2.Children[2]
            $flap2.ScaleY = 0.5 + 0.5 * [math]::Abs([math]::Cos($elapsed * 22))
            $pos2.X = 1250 - ($elapsed / 2.2) * 1400
            $pos2.Y = 240 + 45 * [math]::Cos($elapsed * 6)
        }

        # Demobat 3 (Swarm bat 3 darting across)
        if ($null -ne $sync.WPFDemobat3 -and $null -ne $sync.WPFDemobat3.RenderTransform) {
            $tg3 = $sync.WPFDemobat3.RenderTransform
            $flap3 = $tg3.Children[0]
            $pos3 = $tg3.Children[2]
            $flap3.ScaleY = 0.4 + 0.6 * [math]::Abs([math]::Sin($elapsed * 30))
            $pos3.X = -150 + ($elapsed / 1.9) * 1350
            $pos3.Y = 320 - 30 * [math]::Sin($elapsed * 7)
        }

        # Fade out overlay in the final 0.6 seconds
        if ($elapsed -ge 1.6) {
            $opacity = [math]::Max(0.0, 1.0 - (($elapsed - 1.6) / 0.55))
            $sync.WPFLaunchOverlay.Opacity = $opacity
        }

        # Complete and dismiss
        if ($elapsed -ge 2.2) {
            $timer.Stop()
            $clock.Stop()
            $sync.WPFLaunchOverlay.Visibility = [System.Windows.Visibility]::Collapsed
        }
    })

    $timer.Start()
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
        Start-WinUtilStrangerThingsAudio -Theme "VecnaExit"

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
            Start-WinUtilStrangerThingsAudio -Theme "Victory"
        } catch {}
    }
}
