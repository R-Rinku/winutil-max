<#
.SYNOPSIS
    Single-script launcher for winutil-MAX (enhanced WinUtil with Smart Renamer, Take Ownership, Enterprise Mode).
.DESCRIPTION
    Compiles the latest sources into winutil.ps1 and launches the utility.
    Elevation to Administrator is automatically handled with Windows Terminal support.
.EXAMPLE
    .\Run.ps1
.EXAMPLE
    .\Run.ps1 -CompileOnly
#>
[CmdletBinding()]
param(
    [switch]$CompileOnly
)

$repoRoot = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    $repoRoot = (Get-Location).Path
}

# Compile latest sources
$compileScript = Join-Path $repoRoot "Compile.ps1"
if (-not (Test-Path $compileScript)) {
    Write-Error "Compile.ps1 not found in $repoRoot"
    exit 1
}

Write-Host "Compiling winutil-MAX..." -ForegroundColor Cyan
& $compileScript

if ($CompileOnly) {
    Write-Host "Compilation complete. Output: winutil.ps1" -ForegroundColor Green
    exit 0
}

# Launch the compiled script (winutil.ps1 automatically handles elevation and Windows Terminal opening)
$outputScript = Join-Path $repoRoot "winutil.ps1"
if (Test-Path $outputScript) {
    & $outputScript
} else {
    Write-Error "Compiled artifact winutil.ps1 was not generated."
    exit 1
}
