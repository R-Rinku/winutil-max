function Get-WinUtilVecnaImage {
    [CmdletBinding()]
    param()
    return $null
}

function Invoke-WinUtilVecnaExit {
    [CmdletBinding()]
    param()
    return $false
}

function Invoke-WinUtilVecnaCompletion {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$JobLabel = "Operations"
    )
}
