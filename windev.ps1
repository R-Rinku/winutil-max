# Runs the latest development version of winutil-MAX
$prevProgress = $ProgressPreference
$ProgressPreference = 'SilentlyContinue'
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $uri = "https://raw.githubusercontent.com/R-Rinku/winutil-max/main/winutil.ps1"
    $wc = New-Object System.Net.WebClient
    $wc.Encoding = [System.Text.Encoding]::UTF8
    $script = $wc.DownloadString($uri)
    $wc.Dispose()
    Invoke-Expression $script
} finally {
    $ProgressPreference = $prevProgress
}
