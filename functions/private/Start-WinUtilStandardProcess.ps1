function Start-WinUtilStandardProcess {
    <#
    .SYNOPSIS
        Launches an interactive process strictly under the standard (non-elevated) desktop user token.
    .DESCRIPTION
        From an elevated administrator session, standard Start-Process or Shell.Application creates
        child processes that inherit the administrator token. This function queries the ShellWindows
        desktop COM interface (IShellDispatch2 on explorer.exe) to spawn child processes strictly
        under the interactive user's medium integrity token (IsInRole(Administrator) = False).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [string]$Arguments = "",

        [string]$WorkingDirectory = $env:USERPROFILE
    )

    # Method 1: Desktop ShellWindows COM dispatch (Guaranteed Medium Integrity / Non-Admin)
    try {
        $type = [Type]::GetTypeFromCLSID([Guid]'{9BA05972-F6A8-11CF-A442-00A0C90A8F39}')
        $sw = [Activator]::CreateInstance($type)
        $loc = [int]0; $root = [int]0; $hwnd = [int]0
        $disp = $sw.FindWindowSW([ref]$loc, [ref]$root, 8, [ref]$hwnd, 1)
        if ($null -ne $disp -and $null -ne $disp.Document -and $null -ne $disp.Document.Application) {
            $disp.Document.Application.ShellExecute($FilePath, $Arguments, $WorkingDirectory, "open", 1)
            Write-WinUtilLog -Component "Process" -Message "Launched $FilePath via ShellWindows desktop dispatch (non-elevated)."
            return $true
        }
    } catch {
        Write-WinUtilLog -Component "Process" -Message "Desktop dispatch failed: $($_.Exception.Message)" -Level "WARN"
    }

    # Method 2: In-Process Shell.Application COM fallback
    try {
        $sh = New-Object -ComObject Shell.Application
        $sh.ShellExecute($FilePath, $Arguments, $WorkingDirectory, "open", 1)
        Write-WinUtilLog -Component "Process" -Message "Launched $FilePath via Shell.Application fallback."
        return $true
    } catch {
        Write-WinUtilLog -Component "Process" -Message "Shell.Application fallback failed: $($_.Exception.Message)" -Level "WARN"
    }

    # Method 3: Direct Start-Process fallback
    try {
        Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory
        Write-WinUtilLog -Component "Process" -Message "Launched $FilePath via Start-Process fallback."
        return $true
    } catch {
        Write-WinUtilLog -Component "Process" -Message "Start-Process fallback failed: $($_.Exception.Message)" -Level "ERROR"
        return $false
    }
}
