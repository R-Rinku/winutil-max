function Invoke-WinUtilInstallClaudeCLI {
    <#
    .SYNOPSIS
        Installs Anthropic's official Claude Code CLI tool globally via npm.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "MAXTools" -Message "Installing Claude Code CLI..."
    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Checking for Node.js / npm environment..." -ForegroundColor Cyan

    $npm = Get-Command "npm" -ErrorAction SilentlyContinue
    if (-not $npm) {
        Write-Host "[winutil-MAX] Node.js / npm was not found. Attempting to install Node.js LTS via winget..." -ForegroundColor Yellow
        $winget = Get-Command "winget" -ErrorAction SilentlyContinue
        if ($winget) {
            Start-Process "winget.exe" -ArgumentList "install OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
            # Refresh PATH in current session
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } else {
            Write-Host "[winutil-MAX] [ERROR] Please install Node.js from https://nodejs.org first." -ForegroundColor Red
            if (Test-WinUtilUIAlive) {
                Show-WinUtilMessage -Title "Node.js Required" -Message "npm was not found. Please install Node.js from https://nodejs.org and rerun this installer." -Button "OK" -Icon "Warning"
            }
            return
        }
    }

    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Running 'npm install -g @anthropic-ai/claude-code'..." -ForegroundColor Cyan
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm install -g @anthropic-ai/claude-code" -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -eq 0) {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] Claude Code CLI installed successfully!" -ForegroundColor Green
        Write-WinUtilLog -Component "MAXTools" -Message "Claude Code CLI installed successfully."
        if (Test-WinUtilUIAlive) {
            Show-WinUtilMessage -Title "Claude CLI Installed" -Message "Claude Code CLI (@anthropic-ai/claude-code) has been installed successfully!`n`nYou can run it from any terminal by typing 'claude'." -Button "OK" -Icon "Information"
        }
    } else {
        Write-Host "[winutil-MAX] [ERROR] Failed to install Claude Code CLI (Exit code: $($p.ExitCode))." -ForegroundColor Red
    }
}

function Invoke-WinUtilLaunchClaudeCLI {
    <#
    .SYNOPSIS
        Opens a new terminal window running Claude Code CLI.
    #>
    [CmdletBinding()]
    param()

    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Launching Claude CLI..." -ForegroundColor Cyan
    Start-Process "cmd.exe" -ArgumentList "/k claude"
}

function Invoke-WinUtilInstallOmniRoute {
    <#
    .SYNOPSIS
        Installs OmniRoute universal AI router & proxy gateway globally via npm.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "MAXTools" -Message "Installing OmniRoute AI Gateway..."
    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Checking for Node.js / npm environment..." -ForegroundColor Cyan

    $npm = Get-Command "npm" -ErrorAction SilentlyContinue
    if (-not $npm) {
        Write-Host "[winutil-MAX] Node.js / npm was not found. Attempting to install Node.js LTS via winget..." -ForegroundColor Yellow
        $winget = Get-Command "winget" -ErrorAction SilentlyContinue
        if ($winget) {
            Start-Process "winget.exe" -ArgumentList "install OpenJS.NodeJS.LTS --silent --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        } else {
            Write-Host "[winutil-MAX] [ERROR] Please install Node.js from https://nodejs.org first." -ForegroundColor Red
            if (Test-WinUtilUIAlive) {
                Show-WinUtilMessage -Title "Node.js Required" -Message "npm was not found. Please install Node.js from https://nodejs.org and rerun this installer." -Button "OK" -Icon "Warning"
            }
            return
        }
    }

    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Running 'npm install -g omniroute'..." -ForegroundColor Cyan
    $p = Start-Process -FilePath "cmd.exe" -ArgumentList "/c npm install -g omniroute" -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -eq 0) {
        Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] [SUCCESS] OmniRoute installed successfully!" -ForegroundColor Green
        Write-WinUtilLog -Component "MAXTools" -Message "OmniRoute installed successfully."
        if (Test-WinUtilUIAlive) {
            Show-WinUtilMessage -Title "OmniRoute Installed" -Message "OmniRoute has been installed successfully!`n`nStart the router by running 'omniroute' in your terminal or clicking the Dashboard button." -Button "OK" -Icon "Information"
        }
    } else {
        Write-Host "[winutil-MAX] [ERROR] Failed to install OmniRoute (Exit code: $($p.ExitCode))." -ForegroundColor Red
    }
}

function Invoke-WinUtilLaunchOmniRoute {
    <#
    .SYNOPSIS
        Opens the OmniRoute dashboard in the default browser.
    #>
    [CmdletBinding()]
    param()

    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Opening OmniRoute dashboard..." -ForegroundColor Cyan
    # Also attempt to ensure omniroute is started
    Start-Process "cmd.exe" -ArgumentList "/c start /min omniroute" -WindowStyle Hidden -ErrorAction SilentlyContinue
    Start-Process "http://localhost:20128/dashboard"
}

function Invoke-WinUtilSuperGodMode {
    <#
    .SYNOPSIS
        Launches ThioJoe's Windows Super God Mode utility.
    #>
    [CmdletBinding()]
    param()

    Write-WinUtilLog -Component "MAXTools" -Message "Launching Windows Super God Mode..."
    Write-Host "[winutil-MAX] [$(Get-Date -Format 'HH:mm:ss')] >> Launching ThioJoe's Windows Super God Mode..." -ForegroundColor Cyan

    $candidates = @()
    if ($sync -and $sync.winutildir) {
        $candidates += Join-Path $sync.winutildir "Super_God_Mode.ps1"
    }
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $candidates += Join-Path $PSScriptRoot "scripts\super-god-mode\Super_God_Mode.ps1"
        $candidates += Join-Path $PSScriptRoot "..\..\scripts\super-god-mode\Super_God_Mode.ps1"
    }
    $currPath = (Get-Location).Path
    if (-not [string]::IsNullOrWhiteSpace($currPath)) {
        $candidates += Join-Path $currPath "scripts\super-god-mode\Super_God_Mode.ps1"
    }
    $candidates += Join-Path ([System.IO.Path]::GetTempPath()) "Super_God_Mode.ps1"

    $scriptPath = $candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path $_) } | Select-Object -First 1

    if (-not $scriptPath) {
        $destDir = if ($sync -and $sync.winutildir) { $sync.winutildir } else { [System.IO.Path]::GetTempPath() }
        $tempPath = Join-Path $destDir "Super_God_Mode.ps1"
        Write-Host "[winutil-MAX] Downloading latest Super_God_Mode.ps1..." -ForegroundColor Cyan
        try {
            Invoke-RestMethod -Uri "https://raw.githubusercontent.com/R-Rinku/winutil-max/main/scripts/super-god-mode/Super_God_Mode.ps1" -OutFile $tempPath
            $scriptPath = $tempPath
        } catch {
            try {
                Invoke-RestMethod -Uri "https://raw.githubusercontent.com/ThioJoe/Windows-Super-God-Mode/main/Super_God_Mode.ps1" -OutFile $tempPath
                $scriptPath = $tempPath
            } catch {
                Write-Host "[winutil-MAX] [ERROR] Failed to download Super God Mode: $($_.Exception.Message)" -ForegroundColor Red
                if (Test-WinUtilUIAlive) {
                    Show-WinUtilMessage -Title "Super God Mode" -Message "Failed to load Super God Mode script.`n`nError: $($_.Exception.Message)" -Button "OK" -Icon "Error"
                }
                return
            }
        }
    }

    Write-Host "[winutil-MAX] Opening Super God Mode from: $scriptPath" -ForegroundColor Green
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -NoNewWindow
}
