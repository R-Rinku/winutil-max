# Runs the latest development version of winutil-MAX
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$uri = "https://raw.githubusercontent.com/R-Rinku/winutil-max/main/winutil.ps1"
Invoke-Expression (Invoke-RestMethod -Uri $uri -UseBasicParsing)
