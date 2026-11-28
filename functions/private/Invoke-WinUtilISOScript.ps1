function Invoke-WinUtilISOScript {
    <#
    .SYNOPSIS
        Prepares copied Windows setup media without modifying its install image.

    .DESCRIPTION
        Stages WinUtil's AppX removal, registry tweaks, and scheduled-task cleanup
        in the answer file for first logon, writes sources\ei.cfg for the selected
        edition, and optionally adds current-system drivers to boot.wim index 2 and
        one install.wim index.

    .PARAMETER ISOContentsDir
        Root directory of the copied ISO contents.

    .PARAMETER AutoUnattendXml
        Full XML content for autounattend.xml.

    .PARAMETER InstallEditionId
        Windows setup EditionID for sources\ei.cfg, for example Professional or Core.

    .PARAMETER InstallImagePath
        Copied install.wim to service when current-system driver injection is enabled.

    .PARAMETER InstallImageIndex
        Selected edition index in install.wim.

    .PARAMETER Log
        Optional ScriptBlock for progress/status logging. Receives a single [string] argument.

    .PARAMETER DriversInjected
        Optional [ref] set to $true only if driver injection actually mounted and committed
        install.wim; stays $false if injection was skipped or no package was added successfully.
    #>
    param (
        [Parameter(Mandatory)][string]$ISOContentsDir,
        [string]$AutoUnattendXml = "",
        [bool]$InjectCurrentSystemDrivers = $false,
        [string]$InstallEditionId = "",
        [string]$InstallImagePath = "",
        [int]$InstallImageIndex = 1,
        [scriptblock]$Log = { param($m) Write-Output $m },
        [ref]$DriversInjected = [ref]$false
    )

    function Add-WinUtilISOStagedDrivers {
        param (
            [Parameter(Mandatory)][string]$ContentRoot,
            [Parameter(Mandatory)][string]$InstallImagePath,
            [Parameter(Mandatory)][int]$InstallImageIndex,
            [scriptblock]$Logger,
            [ref]$DriversInjected = [ref]$false
        )
        $DriversInjected.Value = $false

        function Test-WinUtilISOStorageDriver {
            param ([Parameter(Mandatory)][System.IO.FileInfo]$InfFile)

            try {
                return (Get-Content -LiteralPath $InfFile.FullName -Raw -ErrorAction Stop) -match '(?im)^\s*Class\s*=\s*(SCSIAdapter|HDC)\s*(?:;.*)?$'
            } catch {
                & $Logger "Warning: could not classify storage driver '$($InfFile.FullName)': $_"
                return $false
            }
        }

        function Get-WinUtilISODriverPackageVersion {
            param ([Parameter(Mandatory)][System.IO.FileInfo]$InfFile)

            try {
                $infText = Get-Content -LiteralPath $InfFile.FullName -Raw -ErrorAction Stop
            } catch {
                $null = & $Logger "Warning: could not read '$($InfFile.FullName)' to determine its driver version: $_"
                return $null
            }

            # The version component of DriverVer is optional per the INF spec (date-only entries
            # are valid); treat a missing version as 0.0 so date-only entries still rank correctly
            # instead of being discarded as unparseable.
            $match = [regex]::Match($infText, '(?im)^\s*DriverVer\s*=\s*(?<date>\d{1,2}/\d{1,2}/\d{4})\s*(?:,\s*(?<version>\d+(?:\.\d+){0,3}))?\s*(?:;.*)?$')
            if (-not $match.Success) {
                return $null
            }

            try {
                $date = [datetime]::ParseExact($match.Groups['date'].Value, 'M/d/yyyy', [System.Globalization.CultureInfo]::InvariantCulture)
                $versionText = if ($match.Groups['version'].Success) { $match.Groups['version'].Value } else { '0' }
                if (($versionText.Split('.')).Count -lt 2) {
                    $versionText = "$versionText.0"
                }
                $version = [version]$versionText
            } catch {
                $null = & $Logger "Warning: could not parse DriverVer '$($match.Value.Trim())' in '$($InfFile.FullName)': $_"
                return $null
            }

            return [pscustomobject]@{
                Date    = $date
                Version = $version
                Raw     = if ($match.Groups['version'].Success) { "$($match.Groups['date'].Value),$($match.Groups['version'].Value)" } else { $match.Groups['date'].Value }
            }
        }

        function Get-WinUtilISODriverProvider {
            param ([Parameter(Mandatory)][System.IO.FileInfo]$InfFile)

            try {
                $infText = Get-Content -LiteralPath $InfFile.FullName -Raw -ErrorAction Stop
            } catch {
                $null = & $Logger "Warning: could not read '$($InfFile.FullName)' to determine its provider: $_"
                return ''
            }

            $match = [regex]::Match($infText, '(?im)^\s*Provider\s*=\s*(?<provider>.+?)\s*(?:;.*)?$')
            if (-not $match.Success) {
                return ''
            }
            return $match.Groups['provider'].Value.ToLowerInvariant()
        }

        function Select-WinUtilISOStagedDriverPackages {
            param (
                [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$DriverFolderGroups,
                [scriptblock]$Logger
            )

            $survivingFolders = [System.Collections.Generic.List[string]]::new()
            $dedupGroups = @{}

            foreach ($driverFolderGroup in $DriverFolderGroups) {
                $driverFolder = [string]$driverFolderGroup.Name

                # DISM names exported package folders <infname>_<arch>_<hash>; grouping on infname+arch
                # (dropping the hash) is what lets us recognize two exports of the same driver. When a
                # folder doesn't match that pattern, fall back to the full path rather than the leaf name:
                # two unrelated folders at different depths (e.g. group_a\duplicate and group_b\duplicate)
                # can share a leaf name, and the full path is guaranteed unique per group.
                $leafName = Split-Path -Path $driverFolder -Leaf
                $dedupKey = $driverFolder
                $nameMatch = [regex]::Match($leafName, '(?i)^(?<infname>.+)_(?<arch>x86|amd64|arm64|arm|wow)_[0-9a-f]{16}$')
                if ($nameMatch.Success) {
                    $provider = Get-WinUtilISODriverProvider -InfFile $driverFolderGroup.Group[0]
                    $dedupKey = "$($nameMatch.Groups['infname'].Value.ToLowerInvariant())_$($nameMatch.Groups['arch'].Value.ToLowerInvariant())_$provider"
                }

                if (-not $dedupGroups.ContainsKey($dedupKey)) {
                    $dedupGroups[$dedupKey] = [System.Collections.Generic.List[object]]::new()
                }
                $dedupGroups[$dedupKey].Add($driverFolderGroup)
            }

            foreach ($dedupKey in $dedupGroups.Keys) {
                $candidates = $dedupGroups[$dedupKey]
                if ($candidates.Count -eq 1) {
                    $survivingFolders.Add([string]$candidates[0].Name)
                    continue
                }

                $ranked = @($candidates | ForEach-Object {
                    $primaryVersion = ($_.Group | ForEach-Object { Get-WinUtilISODriverPackageVersion -InfFile $_ } | Where-Object { $_ }) |
                        Sort-Object -Property Date, Version -Descending | Select-Object -First 1
                    [pscustomobject]@{ Folder = [string]$_.Name; Version = $primaryVersion }
                })

                $withVersion = @($ranked | Where-Object { $_.Version })
                if ($withVersion.Count -eq 0) {
                    $null = & $Logger "Warning: could not determine DriverVer for any duplicate of '$dedupKey'; keeping all $($ranked.Count) package(s) rather than guessing."
                    foreach ($candidate in $ranked) {
                        $survivingFolders.Add($candidate.Folder)
                    }
                    continue
                }

                $kept = $withVersion | Sort-Object -Property @{ Expression = { $_.Version.Date } }, @{ Expression = { $_.Version.Version } } -Descending | Select-Object -First 1
                $survivingFolders.Add($kept.Folder)

                foreach ($candidate in $ranked) {
                    if ($candidate.Folder -eq $kept.Folder) {
                        continue
                    }
                    $droppedVersion = if ($candidate.Version) { $candidate.Version.Raw } else { 'unknown' }
                    $null = & $Logger "Excluding stale duplicate driver package '$($candidate.Folder)' (DriverVer $droppedVersion) superseded by '$($kept.Folder)' (DriverVer $($kept.Version.Raw))."
                }
            }

            return @($survivingFolders)
        }

        $knownExitCode = @{
            112 = "Disk is full"
            5 = "Access denied"
            2 = "File not found"
            3 = "Path not found"
            87 = "Invalid parameter"
            1168 = "Element not found"
            1392 = "File or directory is corrupted"
            32 = "File in use / sharing violation"
            21 = "Device not ready"
            1460 = "Operation timed out"
            1223 = "Operation cancelled by user"
            50 = "Request not supported"
        }

        function Invoke-WinUtilISODism {
            param (
                [Parameter(Mandatory)][string[]]$Arguments,
                [Parameter(Mandatory)][string]$Operation
            )

            $output = @(& dism.exe @Arguments 2>&1)
            $exitCode = $LASTEXITCODE
            if ($exitCode -ne 0) {
                foreach ($line in @($output | Select-Object -Last 20)) {
                    if (-not [string]::IsNullOrWhiteSpace([string]$line)) {
                        & $Logger "  dism[$Operation]: $line"
                    }
                }
                if ($knownExitCode.ContainsKey($exitCode)) {
                    throw "DISM $Operation failed with exit code $exitCode ($($knownExitCode[$exitCode]))."
                } else {
                    throw "DISM $Operation failed with exit code $exitCode."
                }
            }
            if ($Operation -ne 'metadata') {
                & $Logger "DISM $Operation completed."
            }
            return $output
        }

        function Get-WinUtilISOWimMetadata {
            param ([Parameter(Mandatory)][string]$ImagePath, [Parameter(Mandatory)][int]$Index)

            $metadata = @{}
            $output = Invoke-WinUtilISODism -Arguments @('/English', '/Get-WimInfo', "/WimFile:$ImagePath", "/Index:$Index") -Operation 'metadata'
            foreach ($line in $output) {
                if ([string]$line -match '^\s*([^:]+?)\s*:\s*(.*?)\s*$') {
                    $metadata[$Matches[1].Trim()] = $Matches[2].Trim()
                }
            }
            return $metadata
        }

        function Assert-WinUtilISOWimMetadata {
            param (
                [Parameter(Mandatory)][hashtable]$Before,
                [hashtable]$After
            )

            foreach ($key in 'Languages', 'Installation', 'Edition', 'ProductSuite', 'ProductType') {
                $beforeValue = [string]$Before[$key]
                if ($beforeValue -eq '<undefined>' -or ($key -in 'Installation', 'Edition', 'ProductType' -and [string]::IsNullOrWhiteSpace($beforeValue))) {
                    throw "install.wim metadata is already invalid: $key is undefined. Driver injection was not attempted."
                }
                if ($After) {
                    $afterValue = [string]$After[$key]
                    if ($afterValue -eq '<undefined>' -or ($beforeValue -and $afterValue -ne $beforeValue)) {
                        throw "install.wim metadata validation failed after driver injection: $key changed from '$beforeValue' to '$afterValue'."
                    }
                }
            }
        }

        function Test-WinUtilISOMountedImage {
            param ([Parameter(Mandatory)][string]$Path)

            return @(& dism.exe /English /Get-MountedImageInfo 2>$null) -match [regex]::Escape($Path)
        }

        function Get-WinUtilISODriverFolderName {
            param ([Parameter(Mandatory)][string]$DriverFolder)

            if ($DriverFolder.StartsWith($driverExportRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
                return $DriverFolder.Substring($driverExportRoot.Length).TrimStart('\')
            }
            return $DriverFolder
        }

        function Get-WinUtilISORootDriverFolders {
            param ([Parameter(Mandatory)][AllowEmptyCollection()][string[]]$DriverFolders)

            return @($DriverFolders | Where-Object {
                $candidate = $_
                -not ($DriverFolders | Where-Object { $candidate.StartsWith("$_\", [System.StringComparison]::OrdinalIgnoreCase) })
            })
        }

        function Add-WinUtilISODriversToImage {
            param (
                [Parameter(Mandatory)][string]$ImagePath,
                [Parameter(Mandatory)][int]$ImageIndex,
                [Parameter(Mandatory)][string]$MountDir,
                [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$DriverFolders,
                [Parameter(Mandatory)][string]$ImageLabel,
                [Parameter(Mandatory)][ref]$ImageMounted
            )

            if ($DriverFolders.Count -eq 0) {
                & $Logger "No driver packages to add to ${ImageLabel}."
                return 0
            }

            Set-ItemProperty -LiteralPath $ImagePath -Name IsReadOnly -Value $false
            New-Item -Path $MountDir -ItemType Directory -Force | Out-Null

            $remainingDriverFolders = @($DriverFolders)
            while ($remainingDriverFolders.Count -gt 0) {
                & $Logger "Mounting $ImageLabel index $ImageIndex for driver injection..."
                Invoke-WinUtilISODism -Arguments @('/English', '/Mount-Image', "/ImageFile:$ImagePath", "/Index:$ImageIndex", "/MountDir:$MountDir") -Operation 'mount' | Out-Null
                $ImageMounted.Value = $true

                $failedDriverFolder = $null
                $driverName = $null
                foreach ($driverFolder in $remainingDriverFolders) {
                    $driverName = Get-WinUtilISODriverFolderName -DriverFolder $driverFolder
                    try {
                        Invoke-WinUtilISODism -Arguments @('/English', "/Image:$MountDir", '/Add-Driver', "/Driver:$driverFolder", '/Recurse') -Operation "add-driver:$driverName" | Out-Null
                    } catch {
                        & $Logger "Warning: failed to add driver package '$driverName': $_"
                        $failedDriverFolder = $driverFolder
                        break
                    }
                }

                if (-not $failedDriverFolder) {
                    break
                }

                & $Logger "Discarding the potentially partial $ImageLabel mount before continuing without '$driverName'."
                try {
                    Invoke-WinUtilISODism -Arguments @('/English', '/Unmount-Image', "/MountDir:$MountDir", '/Discard') -Operation 'discard' | Out-Null
                    $ImageMounted.Value = $false
                } catch {
                    throw "Failed to discard the potentially partial $ImageLabel mount after driver package '$driverName' failed: $_"
                }

                $remainingDriverFolders = @($remainingDriverFolders | Where-Object { $_ -ne $failedDriverFolder })
            }

            $addedCount = $remainingDriverFolders.Count
            if ($addedCount -eq 0) {
                if ($ImageLabel -eq 'install.wim') {
                    & $Logger "Warning: none of the $($DriverFolders.Count) exported driver packages could be added; continuing with an unmodified install.wim."
                } else {
                    & $Logger "Warning: none of the $($DriverFolders.Count) driver packages could be added to ${ImageLabel}."
                }
                return 0
            }

            & $Logger "Added $addedCount of $($DriverFolders.Count) driver packages to ${ImageLabel}."
            & $Logger "Committing the driver-only $ImageLabel change..."
            Invoke-WinUtilISODism -Arguments @('/English', '/Unmount-Image', "/MountDir:$MountDir", '/Commit') -Operation 'commit' | Out-Null
            $ImageMounted.Value = $false
            return $addedCount
        }

        if ([IO.Path]::GetExtension($InstallImagePath) -ne '.wim') {
            throw 'Current-system driver injection requires install.wim; install.esd cannot be serviced in place.'
        }
        if (-not (Test-Path -LiteralPath $InstallImagePath)) {
            throw "install.wim was not found: $InstallImagePath"
        }
        if ($InstallImageIndex -lt 1) {
            throw 'Current-system driver injection requires a valid install.wim image index.'
        }

        $driverExportRoot = Join-Path $env:TEMP "WinUtil_DriverExport_$(Get-Date -Format 'yyyyMMdd_HHmmss')_$(([guid]::NewGuid()).ToString('N').Substring(0, 8))"
        $mountDir = Join-Path (Split-Path -Path $ContentRoot -Parent) 'wim_mount'
        New-Item -Path $driverExportRoot -ItemType Directory -Force | Out-Null

        # %TEMP% can be an 8.3 alias, but Get-ChildItem below reports long paths, so the
        # exported folders would not share this prefix unless it is expanded first.
        $driverExportRoot = (Get-Item -LiteralPath $driverExportRoot).FullName
        $imageMounted = $false

        try {
            & $Logger "Exporting current system drivers before WIM driver injection..."
            $dismLog = Join-Path $env:TEMP "WinUtil_DismDriverExport_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
            Invoke-WinUtilISODism -Arguments @('/English', '/Online', '/Export-Driver', "/Destination:$driverExportRoot", "/LogPath:$dismLog") -Operation 'export-driver' | Out-Null

            $driverInfs = @(Get-ChildItem -LiteralPath $driverExportRoot -Filter '*.inf' -Recurse -File)
            if ($driverInfs.Count -eq 0) {
                throw 'DISM exported no driver INF files.'
            }
            $driverFolders = @($driverInfs | Group-Object { $_.Directory.FullName })
            $stagedDriverFolders = @(Select-WinUtilISOStagedDriverPackages -DriverFolderGroups $driverFolders -Logger $Logger)
            $metadataBefore = Get-WinUtilISOWimMetadata -ImagePath $InstallImagePath -Index $InstallImageIndex
            Assert-WinUtilISOWimMetadata -Before $metadataBefore

            $excludedDriverFolderGroups = @($driverFolders | Where-Object { $_.Name -notin $stagedDriverFolders })
            foreach ($excludedDriverFolderGroup in $excludedDriverFolderGroups) {
                $excludedFolder = [string]$excludedDriverFolderGroup.Name
                $hasRetainedDescendant = [bool]@($stagedDriverFolders | Where-Object {
                    $_.StartsWith("$excludedFolder\", [System.StringComparison]::OrdinalIgnoreCase)
                }).Count
                if ($hasRetainedDescendant) {
                    try {
                        foreach ($excludedInf in $excludedDriverFolderGroup.Group) {
                            Remove-Item -LiteralPath $excludedInf.FullName -Force -ErrorAction Stop
                        }
                    } catch {
                        throw "Failed to remove excluded driver INF files from package '$excludedFolder' before injection: $_"
                    }

                    & $Logger "Keeping excluded driver package directory '$excludedFolder' because it contains a retained nested package, after removing its excluded INF files."
                    continue
                }

                try {
                    Remove-Item -LiteralPath $excludedFolder -Recurse -Force -ErrorAction Stop
                } catch {
                    throw "Failed to remove excluded driver package '$excludedFolder' before injection: $_"
                }
            }

            & $Logger "Exported $($stagedDriverFolders.Count) of $($driverFolders.Count) driver packages ($($excludedDriverFolderGroups.Count) excluded)."

            # Storage for Setup comes from the same surviving set as install.wim, so stale
            # duplicates never reach boot.wim.
            $storageFolders = @(
                $driverFolders |
                    Where-Object { $_.Name -in $stagedDriverFolders } |
                    Where-Object { @($_.Group | Where-Object { Test-WinUtilISOStorageDriver -InfFile $_ }).Count -gt 0 } |
                    ForEach-Object { [string]$_.Name }
            )
            $storageRootFolders = @(Get-WinUtilISORootDriverFolders -DriverFolders $storageFolders)
            $rootPackageFolders = @(Get-WinUtilISORootDriverFolders -DriverFolders $stagedDriverFolders)
            $imageMountedRef = [ref]$imageMounted

            $bootWim = Join-Path $ContentRoot 'sources\boot.wim'
            if ($storageRootFolders.Count -gt 0) {
                if (Test-Path -LiteralPath $bootWim) {
                    & $Logger "Adding $($storageRootFolders.Count) root storage driver packages to boot.wim."
                    $null = Add-WinUtilISODriversToImage -ImagePath $bootWim -ImageIndex 2 -MountDir $mountDir -DriverFolders $storageRootFolders -ImageLabel 'boot.wim' -ImageMounted $imageMountedRef
                } else {
                    & $Logger 'Warning: boot.wim was not found; Windows Setup will not have injected storage drivers.'
                }
            }

            & $Logger "Adding $($rootPackageFolders.Count) root driver packages to install.wim."
            $addedCount = Add-WinUtilISODriversToImage -ImagePath $InstallImagePath -ImageIndex $InstallImageIndex -MountDir $mountDir -DriverFolders $rootPackageFolders -ImageLabel 'install.wim' -ImageMounted $imageMountedRef
            if ($addedCount -gt 0) {
                $metadataAfter = Get-WinUtilISOWimMetadata -ImagePath $InstallImagePath -Index $InstallImageIndex
                Assert-WinUtilISOWimMetadata -Before $metadataBefore -After $metadataAfter
                & $Logger 'Driver injection complete; install.wim metadata validation passed.'
                $DriversInjected.Value = $true
            }
        } finally {
            if ($imageMounted -or (Test-WinUtilISOMountedImage -Path $mountDir)) {
                try {
                    Invoke-WinUtilISODism -Arguments @('/English', '/Unmount-Image', "/MountDir:$mountDir", '/Discard') -Operation 'discard' | Out-Null
                } catch {
                    & $Logger "Warning: could not discard the failed WIM mount: $_"
                }
            }
            Remove-Item -LiteralPath $mountDir -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath $driverExportRoot -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    function Write-WinUtilISOEditionConfig {
        param (
            [Parameter(Mandatory)][string]$ContentRoot,
            [string]$EditionId,
            [scriptblock]$Logger
        )

        $sourcesDir = Join-Path $ContentRoot "sources"
        New-Item -Path $sourcesDir -ItemType Directory -Force | Out-Null

        $pidPath = Join-Path $sourcesDir "PID.txt"
        if (Test-Path $pidPath) {
            Remove-Item -Path $pidPath -Force
            & $Logger "Removed sources\PID.txt so setup will not force a stale or mismatched product key."
        }

        if ([string]::IsNullOrWhiteSpace($EditionId)) {
            & $Logger "Warning: selected edition ID is unknown - skipping sources\ei.cfg fallback."
            return
        }

        $eiCfgPath = Join-Path $sourcesDir "ei.cfg"
        $eiCfg = @"
[EditionID]
$EditionId
[Channel]
Retail
[VL]
0
"@.Trim()

        Set-Content -Path $eiCfgPath -Value $eiCfg -Encoding ASCII -Force
        & $Logger "Written sources\ei.cfg for EditionID '$EditionId'."
    }

    function Add-WinUtilISOSetupCustomizations {
        param (
            [Parameter(Mandatory)][string]$XmlContent,
            [Parameter(Mandatory)][int]$InstallImageIndex,
            [scriptblock]$Logger
        )

        $appxPackages = @(
            'Clipchamp.Clipchamp', 'Microsoft.BingNews', 'Microsoft.BingSearch',
            'Microsoft.BingWeather', 'Microsoft.GetHelp', 'Microsoft.MicrosoftOfficeHub',
            'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.MicrosoftStickyNotes',
            'Microsoft.OutlookForWindows', 'Microsoft.Paint', 'Microsoft.PowerAutomateDesktop',
            'Microsoft.StartExperiencesApp', 'Microsoft.Todos', 'Microsoft.Windows.DevHome',
            'Microsoft.WindowsFeedbackHub', 'Microsoft.WindowsSoundRecorder',
            'Microsoft.ZuneMusic', 'MicrosoftCorporationII.QuickAssist', 'MSTeams'
        )

        $appxList = ($appxPackages | ForEach-Object { "    '$_'" }) -join "`r`n"
        $postInstallScript = @"
`$ErrorActionPreference = 'Continue'
`$logPath = 'C:\Windows\Setup\Scripts\WinUtil-PostInstall.log'
Start-Transcript -Path `$logPath -Append -ErrorAction SilentlyContinue

try {
    Write-Host 'WinUtil: Removing provisioned AppX packages...'
    `$packages = @(
$appxList
    )
    foreach (`$package in `$packages) {
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue |
            Where-Object { `$_.DisplayName -like "*`$package*" } |
            ForEach-Object { Remove-AppxProvisionedPackage -Online -PackageName `$_.PackageName -ErrorAction SilentlyContinue | Out-Null }
        Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue |
            Where-Object { `$_.Name -like "*`$package*" } |
            ForEach-Object { Remove-AppxPackage -AllUsers -Package `$_.PackageFullName -ErrorAction SilentlyContinue | Out-Null }
    }

    function Set-WinUtilRegistryValue([string]`$Path, [string]`$Name, [string]`$Type, [string]`$Value) {
        reg.exe add `$Path /v `$Name /t `$Type /d `$Value /f 2>&1 | Out-Null
    }

    function Set-WinUtilContentDeliveryManagerValues([string]`$HiveRoot) {
        `$contentDeliveryManager = "`$HiveRoot\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
        Set-WinUtilRegistryValue `$contentDeliveryManager 'OemPreInstalledAppsEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'PreInstalledAppsEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SilentInstalledAppsEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'ContentDeliveryAllowed' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'FeatureManagementEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'PreInstalledAppsEverEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SoftLandingEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContentEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-310093Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-338388Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-338389Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-338393Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-353694Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SubscribedContent-353696Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue `$contentDeliveryManager 'SystemPaneSuggestionsEnabled' 'REG_DWORD' '0'
        reg.exe delete "`$contentDeliveryManager\Subscriptions" /f 2>&1 | Out-Null
        reg.exe delete "`$contentDeliveryManager\SuggestedApps" /f 2>&1 | Out-Null
    }

    Write-Host 'WinUtil: Applying registry tweaks...'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager' 'ShippedWithReserves' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Control\BitLocker' 'PreventDeviceEncryption' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 'REG_DWORD' '3'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\dmwappushservice' 'Start' 'REG_DWORD' '4'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot' 'TurnOffWindowsCopilot' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Edge' 'HubsSidebarEnabled' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer' 'DisableSearchBoxSuggestions' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Teams' 'DisableInstallation' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Mail' 'PreventRun' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableWindowsConsumerFeatures' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableConsumerAccountStateContent' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent' 'DisableCloudOptimizedContent' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\PolicyManager\current\device\Start' 'ConfigureStartPins' 'REG_SZ' '{"pinnedList": [{}]}'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE' 'BypassNRO' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassCPUCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassRAMCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassSecureBootCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassStorageCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\LabConfig' 'BypassTPMCheck' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\Setup\MoSetup' 'AllowUpgradesWithUnsupportedTPMOrCPU' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\PushToInstall' 'DisablePushToInstall' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\MRT' 'DontOfferThroughWUAU' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate' 'workCompleted' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate' 'workCompleted' 'REG_DWORD' '1'
    reg.exe delete 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate' /f 2>&1 | Out-Null
    reg.exe delete 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate' /f 2>&1 | Out-Null
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'UseWUServer' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'DisableWindowsUpdateAccess' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'WUServer' 'REG_SZ' 'http://localhost:8080'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate' 'WUStatusServer' 'REG_SZ' 'http://localhost:8080'
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler_Oobe\WindowsUpdate' 'workCompleted' 'REG_DWORD' '1'
    reg.exe delete 'HKLM\SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\WindowsUpdate' /f 2>&1 | Out-Null
    Set-WinUtilRegistryValue 'HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' 'DODownloadMode' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\BITS' 'Start' 'REG_DWORD' '4'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\wuauserv' 'Start' 'REG_DWORD' '4'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\UsoSvc' 'Start' 'REG_DWORD' '4'
    Set-WinUtilRegistryValue 'HKLM\SYSTEM\CurrentControlSet\Services\WaaSMedicSvc' 'Start' 'REG_DWORD' '4'

    `$defaultHive = 'HKU\WinUtilDefault'
    reg.exe load `$defaultHive 'C:\Users\Default\NTUSER.DAT' 2>&1 | Out-Null
    if (`$LASTEXITCODE -eq 0) {
        Set-WinUtilRegistryValue "`$defaultHive\Control Panel\UnsupportedHardwareNotificationCache" 'SV1' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Control Panel\UnsupportedHardwareNotificationCache" 'SV2' 'REG_DWORD' '0'
        Set-WinUtilContentDeliveryManagerValues `$defaultHive
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" 'Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Windows\CurrentVersion\Privacy" 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" 'HasAccepted' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Input\TIPC" 'Enabled' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\InputPersonalization" 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\InputPersonalization" 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\InputPersonalization\TrainedDataStore" 'HarvestContacts' 'REG_DWORD' '0'
        Set-WinUtilRegistryValue "`$defaultHive\Software\Microsoft\Personalization\Settings" 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'
        reg.exe unload `$defaultHive 2>&1 | Out-Null
    }

    Set-WinUtilContentDeliveryManagerValues 'HKCU'
    Set-WinUtilRegistryValue 'HKCU\Control Panel\UnsupportedHardwareNotificationCache' 'SV1' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Control Panel\UnsupportedHardwareNotificationCache' 'SV2' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarMn' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy' 'HasAccepted' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Input\TIPC' 'Enabled' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\InputPersonalization' 'RestrictImplicitInkCollection' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\InputPersonalization' 'RestrictImplicitTextCollection' 'REG_DWORD' '1'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore' 'HarvestContacts' 'REG_DWORD' '0'
    Set-WinUtilRegistryValue 'HKCU\Software\Microsoft\Personalization\Settings' 'AcceptedPrivacyPolicy' 'REG_DWORD' '0'

    Write-Host 'WinUtil: Removing scheduled task definitions...'
    `$taskPaths = @(
        'C:\Windows\System32\Tasks\Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser',
        'C:\Windows\System32\Tasks\Microsoft\Windows\Customer Experience Improvement Program',
        'C:\Windows\System32\Tasks\Microsoft\Windows\Application Experience\ProgramDataUpdater',
        'C:\Windows\System32\Tasks\Microsoft\Windows\Chkdsk\Proxy',
        'C:\Windows\System32\Tasks\Microsoft\Windows\Windows Error Reporting\QueueReporting',
        'C:\Windows\System32\Tasks\Microsoft\Windows\InstallService',
        'C:\Windows\System32\Tasks\Microsoft\Windows\UpdateOrchestrator',
        'C:\Windows\System32\Tasks\Microsoft\Windows\UpdateAssistant',
        'C:\Windows\System32\Tasks\Microsoft\Windows\WaaSMedic',
        'C:\Windows\System32\Tasks\Microsoft\Windows\WindowsUpdate',
        'C:\Windows\System32\Tasks\Microsoft\WindowsUpdate'
    )
    foreach (`$taskPath in `$taskPaths) { Remove-Item -LiteralPath `$taskPath -Recurse -Force -ErrorAction SilentlyContinue }

    Start-Process -FilePath 'C:\Windows\System32\OneDriveSetup.exe' -ArgumentList '/uninstall' -Wait -ErrorAction SilentlyContinue

    # WinUtil-MAX: Create 1-click desktop shortcut on installed OS
    try {
        Write-Host 'WinUtil-MAX: Creating desktop shortcut...'
        `$iconDir = 'C:\ProgramData\winutil-max'
        if (-not (Test-Path -LiteralPath `$iconDir)) {
            New-Item -Path `$iconDir -ItemType Directory -Force | Out-Null
        }
        `$iconFile = Join-Path `$iconDir 'MAX.ico'
        `$iconBase64 = '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'
        if (-not (Test-Path -LiteralPath `$iconFile)) {
            [System.IO.File]::WriteAllBytes(`$iconFile, [Convert]::FromBase64String(`$iconBase64))
        }

        `$publicDesktop = [Environment]::GetFolderPath('CommonDesktopDirectory')
        if (-not `$publicDesktop) { `$publicDesktop = 'C:\Users\Public\Desktop' }
        `$shortcutPath = Join-Path `$publicDesktop 'WinUtil-MAX.lnk'

        `$wshShell = New-Object -ComObject WScript.Shell
        `$shortcut = `$wshShell.CreateShortcut(`$shortcutPath)
        `$shortcut.TargetPath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
        `$shortcut.Arguments = '-NoProfile -ExecutionPolicy Bypass -Command "& ([ScriptBlock]::Create((irm https://raw.githubusercontent.com/R-Rinku/winutil-max/main/winutil.ps1)))"'
        `$shortcut.Description = '⚡ WinUtil-MAX - The Ultimate Windows Optimization, Automation & Tweaking Suite'
        `$shortcut.WorkingDirectory = 'C:\Users\Public'
        if (Test-Path -LiteralPath `$iconFile) {
            `$shortcut.IconLocation = "`$iconFile,0"
        }
        `$shortcut.Save()
        Write-Host "WinUtil-MAX: Desktop shortcut created at '`$shortcutPath'."
    } catch {
        Write-Host "WinUtil-MAX: Desktop shortcut creation skipped: `$_"
    }

    Write-Host 'WinUtil: Post-install customization complete.'
} finally {
    Stop-Transcript -ErrorAction SilentlyContinue
}
"@

        $xmlDoc = [xml]::new()
        $xmlDoc.PreserveWhitespace = $true
        $xmlDoc.LoadXml($XmlContent)
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
        $nsMgr.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
        $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')

        $setupComponent = $xmlDoc.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]', $nsMgr)
        $extensions = $xmlDoc.SelectSingleNode('//sg:Extensions', $nsMgr)
        $firstLogonFile = $xmlDoc.SelectSingleNode('//sg:File[@path="C:\Windows\Setup\Scripts\FirstLogon.ps1"]', $nsMgr)
        if (-not $setupComponent -or -not $extensions -or -not $firstLogonFile) {
            throw 'autounattend.xml is missing a required Windows Setup, Extensions, or FirstLogon.ps1 node.'
        }

        $imageInstall = $setupComponent.SelectSingleNode('u:ImageInstall', $nsMgr)
        if (-not $imageInstall) {
            $imageInstall = $xmlDoc.CreateElement('ImageInstall', $setupComponent.NamespaceURI)
            [void]$setupComponent.AppendChild($imageInstall)
        }
        $osImage = $imageInstall.SelectSingleNode('u:OSImage', $nsMgr)
        if (-not $osImage) {
            $osImage = $xmlDoc.CreateElement('OSImage', $setupComponent.NamespaceURI)
            [void]$imageInstall.AppendChild($osImage)
        }
        $installFrom = $osImage.SelectSingleNode('u:InstallFrom', $nsMgr)
        if (-not $installFrom) {
            $installFrom = $xmlDoc.CreateElement('InstallFrom', $setupComponent.NamespaceURI)
            [void]$osImage.AppendChild($installFrom)
        }
        foreach ($existingMetadata in @($installFrom.SelectNodes('u:MetaData', $nsMgr))) {
            [void]$installFrom.RemoveChild($existingMetadata)
        }
        $metadata = $xmlDoc.CreateElement('MetaData', $setupComponent.NamespaceURI)
        $action = $xmlDoc.CreateAttribute('wcm', 'action', 'http://schemas.microsoft.com/WMIConfig/2002/State')
        $action.Value = 'add'
        [void]$metadata.Attributes.Append($action)
        $key = $xmlDoc.CreateElement('Key', $setupComponent.NamespaceURI)
        $key.InnerText = '/IMAGE/INDEX'
        [void]$metadata.AppendChild($key)
        $value = $xmlDoc.CreateElement('Value', $setupComponent.NamespaceURI)
        $value.InnerText = [string]$InstallImageIndex
        [void]$metadata.AppendChild($value)
        [void]$installFrom.AppendChild($metadata)

        $postInstallFile = $xmlDoc.CreateElement('File', $extensions.NamespaceURI)
        $postInstallFile.SetAttribute('path', 'C:\Windows\Setup\Scripts\WinUtil-PostInstall.ps1')
        $postInstallFile.InnerText = $postInstallScript
        [void]$extensions.AppendChild($postInstallFile)

        $firstLogonFile.InnerText = "& 'C:\Windows\Setup\Scripts\WinUtil-PostInstall.ps1';`r`n`r`n$($firstLogonFile.InnerText.Trim())"

        $null = & $Logger 'Added WinUtil post-install AppX, registry, and scheduled-task customizations to autounattend.xml.'
        return $xmlDoc.OuterXml
    }

    function Add-WinUtilISOSetupScriptFallback {
        param (
            [Parameter(Mandatory)][string]$ContentRoot,
            [Parameter(Mandatory)][string]$XmlContent,
            [scriptblock]$Logger
        )

        $xmlDoc = [xml]::new()
        $xmlDoc.PreserveWhitespace = $true
        $xmlDoc.LoadXml($XmlContent)
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xmlDoc.NameTable)
        $nsMgr.AddNamespace('u', 'urn:schemas-microsoft-com:unattend')
        $nsMgr.AddNamespace('sg', 'https://schneegans.de/windows/unattend-generator/')

        $setupScriptsRoot = Join-Path $ContentRoot 'sources\$OEM$\$$\Setup\Scripts'
        $stagedCount = 0
        foreach ($file in $xmlDoc.SelectNodes('//sg:File', $nsMgr)) {
            $path = $file.GetAttribute('path')
            if (-not $path.StartsWith('C:\Windows\Setup\Scripts\', [System.StringComparison]::OrdinalIgnoreCase)) {
                continue
            }

            $relativePath = $path.Substring('C:\Windows\Setup\Scripts\'.Length)
            $targetPath = Join-Path $setupScriptsRoot $relativePath
            New-Item -Path (Split-Path $targetPath -Parent) -ItemType Directory -Force | Out-Null

            $encoding = switch ([System.IO.Path]::GetExtension($targetPath)) {
                { $_ -in '.ps1', '.xml' } { [System.Text.Encoding]::UTF8; break }
                { $_ -in '.reg', '.vbs', '.js' } { [System.Text.UnicodeEncoding]::new($false, $true); break }
                default { [System.Text.Encoding]::Default }
            }
            $bytes = $encoding.GetPreamble() + $encoding.GetBytes($file.InnerText.Trim())
            [System.IO.File]::WriteAllBytes($targetPath, $bytes)
            $stagedCount++
        }

        $useConfigurationSet = $xmlDoc.SelectSingleNode('/u:unattend/u:settings[@pass="windowsPE"]/u:component[@name="Microsoft-Windows-Setup"]/u:UseConfigurationSet', $nsMgr)
        if ($useConfigurationSet) {
            $useConfigurationSet.InnerText = 'true'
            [System.IO.File]::WriteAllText((Join-Path $ContentRoot 'autounattend.xml'), $xmlDoc.OuterXml, [System.Text.UTF8Encoding]::new($false))
        }
        & $Logger "Staged $stagedCount WinUtil setup script fallback files at '$setupScriptsRoot'."
    }

    if (-not (Test-Path $ISOContentsDir)) {
        throw "ISO contents directory does not exist: $ISOContentsDir"
    }

    if ([string]::IsNullOrWhiteSpace($AutoUnattendXml)) {
        throw "autounattend.xml content is required to prepare setup media."
    }

    $preparedAutoUnattendXml = Add-WinUtilISOSetupCustomizations -XmlContent $AutoUnattendXml -InstallImageIndex $InstallImageIndex -Logger $Log
    $unattendPath = Join-Path $ISOContentsDir "autounattend.xml"
    [System.IO.File]::WriteAllText($unattendPath, $preparedAutoUnattendXml, [System.Text.UTF8Encoding]::new($false))
    & $Log "Written autounattend.xml with WinUtil setup customizations to ISO root ($unattendPath)."
    Add-WinUtilISOSetupScriptFallback -ContentRoot $ISOContentsDir -XmlContent $preparedAutoUnattendXml -Logger $Log

    Write-WinUtilISOEditionConfig -ContentRoot $ISOContentsDir -EditionId $InstallEditionId -Logger $Log

    if ($InjectCurrentSystemDrivers) {
        Add-WinUtilISOStagedDrivers -ContentRoot $ISOContentsDir -Logger $Log -InstallImagePath $InstallImagePath -InstallImageIndex $InstallImageIndex -DriversInjected $DriversInjected
    }
}
