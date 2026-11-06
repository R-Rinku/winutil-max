function Invoke-WPFOneDriveExclusion {
    <#
    .SYNOPSIS
        Launches the simplified OneDrive Sync Exclusion Manager for WinUtil-MAX.
    .DESCRIPTION
        Provides a simple, 1-click interface to stop OneDrive from uploading selected
        folders (such as WindowsPowerShell, node_modules) or files to cloud storage.
        Safely clears cloud tracking for items already synced, keeping them 100% local.
    #>
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="OneDrive Sync Excluder - WinUtil-MAX"
        Width="700" Height="560" MinWidth="620" MinHeight="480"
        WindowStartupLocation="CenterScreen"
        Background="#18181B" Foreground="#F4F4F5"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#27272A"/>
            <Setter Property="Foreground" Value="#F4F4F5"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,5"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2563EB"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E4E4E7"/>
            <Setter Property="FontSize" Value="11"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#E4E4E7"/>
        </Style>
        <Style TargetType="GridViewColumnHeader">
            <Setter Property="Background" Value="#27272A"/>
            <Setter Property="Foreground" Value="#93C5FD"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="BorderThickness" Value="0,0,1,1"/>
        </Style>
        <Style TargetType="ListViewItem">
            <Setter Property="Foreground" Value="#F4F4F5"/>
            <Setter Property="Padding" Value="4,4"/>
            <Style.Triggers>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#1E3A8A"/>
                    <Setter Property="Foreground" Value="#FFFFFF"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>

    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Title Header -->
            <RowDefinition Height="Auto"/> <!-- Card 1: Exclude Input -->
            <RowDefinition Height="*"/>    <!-- Card 2: Current Exclusions -->
            <RowDefinition Height="Auto"/> <!-- Footer Actions -->
        </Grid.RowDefinitions>

        <!-- Title Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,14">
            <TextBlock Text="OneDrive Sync Excluder" FontSize="18" FontWeight="Bold" Foreground="#60A5FA"/>
            <TextBlock Text="Stop OneDrive from uploading folders or files to cloud storage. Files remain safe and functional on this PC." FontSize="11" Foreground="#A1A1AA" Margin="0,3,0,0"/>
        </StackPanel>

        <!-- Card 1: Exclude Input -->
        <Border Grid.Row="1" Background="#202024" BorderBrush="#2E2E33" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,0,0,14">
            <StackPanel>
                <!-- Quick Picks -->
                <WrapPanel Margin="0,0,0,10">
                    <TextBlock Text="Quick Picks:" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,8,4" Foreground="#93C5FD" FontSize="11"/>
                    <Button Name="ChipWinPS" Content="+ WindowsPowerShell" Margin="0,0,6,4" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1" Padding="7,3" FontSize="11"/>
                    <Button Name="ChipPS7" Content="+ PowerShell 7" Margin="0,0,6,4" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1" Padding="7,3" FontSize="11"/>
                    <Button Name="ChipNode" Content="+ node_modules" Margin="0,0,6,4" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1" Padding="7,3" FontSize="11"/>
                    <Button Name="ChipGit" Content="+ .git" Margin="0,0,6,4" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1" Padding="7,3" FontSize="11"/>
                    <Button Name="ChipVenv" Content="+ .venv" Margin="0,0,6,4" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1" Padding="7,3" FontSize="11"/>
                </WrapPanel>

                <!-- Input Box & Browse -->
                <Grid Margin="0,0,0,10">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Grid.Column="0" Name="TxtTarget" Height="32" VerticalAlignment="Center" ToolTip="Folder name (e.g. WindowsPowerShell) or file pattern (e.g. *.iso)"/>
                    <Button Grid.Column="1" Name="BtnBrowseFolder" Content="Browse Folder..." Margin="8,0,0,0" Height="32" Padding="10,0" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1"/>
                    <Button Grid.Column="2" Name="BtnBrowseFile" Content="Browse File..." Margin="8,0,0,0" Height="32" Padding="10,0" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1"/>
                </Grid>

                <!-- Option & Main Action -->
                <Grid>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <CheckBox Grid.Column="0" Name="ChkCleanCloud" Content="If already in OneDrive, unlink from cloud (keep files safe on this PC)" IsChecked="True"/>
                    <Button Grid.Column="1" Name="BtnExclude" Content="Exclude from OneDrive" Height="34" Width="180" Background="#2563EB" FontWeight="Bold" FontSize="12"/>
                </Grid>
            </StackPanel>
        </Border>

        <!-- Card 2: Currently Excluded Items -->
        <Border Grid.Row="2" Background="#202024" BorderBrush="#2E2E33" BorderThickness="1" CornerRadius="8" Padding="14" Margin="0,0,0,14">
            <Grid>
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                    <RowDefinition Height="Auto"/>
                </Grid.RowDefinitions>

                <TextBlock Grid.Row="0" Text="Currently Excluded Items" FontWeight="Bold" FontSize="12" Foreground="#93C5FD" Margin="0,0,0,8"/>

                <ListView Grid.Row="1" Name="LvExclusions" Background="#18181B" Foreground="#F4F4F5" BorderBrush="#2E2E33" BorderThickness="1" SelectionMode="Single">
                    <ListView.View>
                        <GridView>
                            <GridViewColumn Header="Name / Pattern" DisplayMemberBinding="{Binding DisplayName}" Width="250"/>
                            <GridViewColumn Header="Type" DisplayMemberBinding="{Binding Type}" Width="90"/>
                            <GridViewColumn Header="Status" DisplayMemberBinding="{Binding Status}" Width="150"/>
                        </GridView>
                    </ListView.View>
                </ListView>

                <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,8,0,0">
                    <Button Name="BtnRefresh" Content="Refresh" Margin="0,0,8,0" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1" Height="28" Width="85"/>
                    <Button Name="BtnRemove" Content="Remove Exclusion" Background="#DC2626" Height="28" Width="140"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Footer Actions -->
        <Grid Grid.Row="3">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Name="LblStatus" Text="Ready." VerticalAlignment="Center" Foreground="#A1A1AA" FontSize="11" TextTrimming="CharacterEllipsis"/>
            <Button Grid.Column="1" Name="BtnExportReg" Content="Save for Reinstall (.reg)" Margin="0,0,8,0" Background="#3F3F46" Height="32" Padding="12,0" ToolTip="Export a .reg file you can double-click anytime after reinstalling Windows"/>
            <Button Grid.Column="2" Name="BtnClose" Content="Close" Background="#27272A" BorderBrush="#3F3F46" BorderThickness="1" Height="32" Width="75"/>
        </Grid>
    </Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader($xaml)
    $form = [Windows.Markup.XamlReader]::Load($reader)

    # Cache Controls
    $ChipWinPS       = $form.FindName("ChipWinPS")
    $ChipPS7         = $form.FindName("ChipPS7")
    $ChipNode        = $form.FindName("ChipNode")
    $ChipGit         = $form.FindName("ChipGit")
    $ChipVenv        = $form.FindName("ChipVenv")
    $TxtTarget       = $form.FindName("TxtTarget")
    $BtnBrowseFolder = $form.FindName("BtnBrowseFolder")
    $BtnBrowseFile   = $form.FindName("BtnBrowseFile")
    $ChkCleanCloud   = $form.FindName("ChkCleanCloud")
    $BtnExclude      = $form.FindName("BtnExclude")
    $LvExclusions    = $form.FindName("LvExclusions")
    $BtnRefresh      = $form.FindName("BtnRefresh")
    $BtnRemove       = $form.FindName("BtnRemove")
    $LblStatus       = $form.FindName("LblStatus")
    $BtnExportReg    = $form.FindName("BtnExportReg")
    $BtnClose        = $form.FindName("BtnClose")

    # Set Window Icon if available
    try {
        $appIcon = Get-WinUtilAppIcon
        if ($null -ne $appIcon) { $form.Icon = $appIcon }
    } catch {}

    # State
    $script:browsedFullPath = ""
    $script:RegFolderUser   = "HKCU:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreFolderListFromGPO"
    $script:RegFolderMachine= "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreFolderListFromGPO"
    $script:RegFileUser     = "HKCU:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO"
    $script:RegFileMachine  = "HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO"

    # Helper: Check Admin
    function Test-IsAdmin {
        try {
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            return ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        } catch { return $false }
    }

    # Helper: Restart OneDrive without Administrator elevation
    # Running OneDrive elevated triggers: "OneDrive can't be run using full administrator rights"
    function Restart-OneDriveApp {
        try {
            Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force
            Start-Sleep -Seconds 1
            $odExe = "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe"
            if (Test-Path $odExe) {
                # explorer.exe launches child processes with standard user tokens (unelevated)
                explorer.exe "$odExe"
            }
        } catch {}
    }

    # Load Active Exclusions into ListView
    $loadRules = {
        $items = [System.Collections.Generic.List[PSCustomObject]]::new()

        $sources = @(
            @{ Path = $script:RegFolderUser;    Type = "Folder"; Prefix = "[Folder] " },
            @{ Path = $script:RegFolderMachine; Type = "Folder"; Prefix = "[Folder] " },
            @{ Path = $script:RegFileUser;      Type = "File";   Prefix = "[File] " },
            @{ Path = $script:RegFileMachine;   Type = "File";   Prefix = "[File] " }
        )

        $seen = @{}
        foreach ($src in $sources) {
            if (Test-Path $src.Path) {
                try {
                    $regItem = Get-Item -Path $src.Path -ErrorAction SilentlyContinue
                    if ($regItem) {
                        foreach ($prop in $regItem.Property) {
                            if ($prop -notin @("PSPath","PSParentPath","PSChildName","PSDrive","PSProvider")) {
                                $val = $regItem.GetValue($prop)
                                $targetName = if ([string]::IsNullOrWhiteSpace($val)) { $prop } else { $val }
                                $key = "$($src.Type):$targetName"
                                if (-not $seen.ContainsKey($key)) {
                                    $seen[$key] = $true
                                    $items.Add([PSCustomObject]@{
                                        DisplayName  = "$($src.Prefix)$targetName"
                                        RawTarget    = $targetName
                                        Type         = $src.Type
                                        Status       = "Excluded from Sync"
                                        RegistryPath = $src.Path
                                        PropName     = $prop
                                    })
                                }
                            }
                        }
                    }
                } catch {}
            }
        }

        $LvExclusions.ItemsSource = $items
        $LblStatus.Text = "$($items.Count) item(s) currently excluded from OneDrive sync."
    }

    # Helper: Add Rule to Registry
    function Add-OneDriveRule {
        param([string]$Target, [string]$Type)
        $clean = $Target.Trim()
        if ([string]::IsNullOrWhiteSpace($clean)) { return $false }

        $targets = @()
        if ($Type -eq "Folder") {
            $targets += $script:RegFolderUser
            if (Test-IsAdmin) { $targets += $script:RegFolderMachine }
        } else {
            $targets += $script:RegFileUser
            if (Test-IsAdmin) { $targets += $script:RegFileMachine }
        }

        $saved = $false
        foreach ($p in $targets) {
            try {
                if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
                Set-ItemProperty -Path $p -Name $clean -Value $clean -Force
                $saved = $true
            } catch {}
        }
        return $saved
    }

    # Quick Picks
    $ChipWinPS.Add_Click({ $TxtTarget.Text = "WindowsPowerShell"; $script:browsedFullPath = "" })
    $ChipPS7.Add_Click({   $TxtTarget.Text = "PowerShell";        $script:browsedFullPath = "" })
    $ChipNode.Add_Click({  $TxtTarget.Text = "node_modules";     $script:browsedFullPath = "" })
    $ChipGit.Add_Click({   $TxtTarget.Text = ".git";             $script:browsedFullPath = "" })
    $ChipVenv.Add_Click({  $TxtTarget.Text = ".venv";            $script:browsedFullPath = "" })

    # Browse Folder
    $BtnBrowseFolder.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select a folder to exclude from OneDrive"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $script:browsedFullPath = $dialog.SelectedPath
            $TxtTarget.Text = Split-Path $dialog.SelectedPath -Leaf
        }
    })

    # Browse File
    $BtnBrowseFile.Add_Click({
        $dialog = New-Object System.Windows.Forms.OpenFileDialog
        $dialog.Title = "Select a file to exclude"
        $dialog.Filter = "All Files (*.*)|*.*"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $ext = [System.IO.Path]::GetExtension($dialog.FileName)
            if (-not [string]::IsNullOrWhiteSpace($ext)) {
                $TxtTarget.Text = "*$ext"
            } else {
                $TxtTarget.Text = [System.IO.Path]::GetFileName($dialog.FileName)
            }
            $script:browsedFullPath = $dialog.FileName
        }
    })

    # Apply Exclusion Action
    $BtnExclude.Add_Click({
        $target = $TxtTarget.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($target)) {
            [System.Windows.MessageBox]::Show("Please choose a Quick Pick or enter a folder/file name to exclude.", "Input Required", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }

        # Determine type
        $isFolder = -not ($target.Contains(".") -and ($target.StartsWith("*") -or [System.IO.Path]::HasExtension($target)))
        $ruleType = if ($isFolder) { "Folder" } else { "File" }

        # Check if the folder exists inside OneDrive locally
        $localOdFolder = ""
        if ($isFolder) {
            if (-not [string]::IsNullOrWhiteSpace($script:browsedFullPath) -and (Test-Path $script:browsedFullPath)) {
                $localOdFolder = $script:browsedFullPath
            } else {
                # Look in common OneDrive locations
                $myDocs = [System.Environment]::GetFolderPath('MyDocuments')
                $candidates = @(
                    (Join-Path $myDocs $target),
                    (Join-Path $env:OneDrive "Documents\$target"),
                    (Join-Path $env:OneDrive $target)
                )
                $localOdFolder = $candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path $_) } | Select-Object -First 1
            }
        }

        # Add rule to registry
        $LblStatus.Text = "Registering exclusion rule for '$target'..."
        Add-OneDriveRule -Target $target -Type $ruleType | Out-Null

        # If it is an existing folder inside OneDrive and Clean Cloud is checked
        $cleanedSync = $false
        if ($localOdFolder -and [bool]$ChkCleanCloud.IsChecked) {
            $folderLeaf = Split-Path $localOdFolder -Leaf
            # Friendly prompt without exposing personal user paths
            $confirm = [System.Windows.MessageBox]::Show(
                "'$folderLeaf' was detected in your OneDrive folder.`n`nWould you like to unlink its existing cloud sync now?`n`n- Files stay 100% safe on your PC`n- OneDrive will briefly restart to apply the exclusion",
                "Unlink from Cloud Sync",
                [System.Windows.MessageBoxButton]::YesNo,
                [System.Windows.MessageBoxImage]::Question
            )

            if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
                $stagingDir = Join-Path ([System.IO.Path]::GetTempPath()) "WinUtil_OD_Staging_$([System.IO.Path]::GetRandomFileName())"
                try {
                    $LblStatus.Text = "Temporarily staging '$folderLeaf'..."
                    New-Item -ItemType Directory -Path $stagingDir -Force | Out-Null
                    Get-Process OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force
                    Start-Sleep -Seconds 1

                    Move-Item -LiteralPath $localOdFolder -Destination $stagingDir -Force

                    # Restart OneDrive without admin elevation to clear cloud tracking
                    $LblStatus.Text = "Starting OneDrive to clear cloud tracking..."
                    Restart-OneDriveApp
                    Start-Sleep -Seconds 4

                    # Restore folder back
                    $stagedItem = Join-Path $stagingDir $folderLeaf
                    if (Test-Path $stagedItem) {
                        $LblStatus.Text = "Restoring '$folderLeaf' with exclusion active..."
                        Move-Item -LiteralPath $stagedItem -Destination $localOdFolder -Force
                    }

                    Remove-Item -LiteralPath $stagingDir -Recurse -Force -ErrorAction SilentlyContinue
                    $cleanedSync = $true
                } catch {
                    # Safety rollback
                    $stagedItem = Join-Path $stagingDir $folderLeaf
                    if ((Test-Path $stagedItem) -and (-not (Test-Path $localOdFolder))) {
                        Move-Item -LiteralPath $stagedItem -Destination $localOdFolder -Force
                    }
                }
            }
        } else {
            # Restart OneDrive without admin elevation to apply registry policies
            Restart-OneDriveApp
        }

        & $loadRules

        $TxtTarget.Text = ""
        $script:browsedFullPath = ""

        $msg = if ($cleanedSync) {
            "'$target' is now excluded and unlinked from the cloud!`n`nYour files remain safe on this PC and will not sync to OneDrive."
        } else {
            "'$target' has been added to OneDrive exclusions!`n`nOneDrive was restarted to activate the new rule."
        }

        $LblStatus.Text = "'$target' excluded successfully."
        [System.Windows.MessageBox]::Show($msg, "Exclusion Active", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    })

    # Remove Selected
    $BtnRemove.Add_Click({
        $selected = $LvExclusions.SelectedItem
        if ($null -eq $selected) {
            [System.Windows.MessageBox]::Show("Please select an item from the list to remove.", "Selection Required", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }

        $confirm = [System.Windows.MessageBox]::Show("Remove exclusion for '$($selected.RawTarget)'?`nOneDrive may resume syncing this item.", "Confirm Removal", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($confirm -eq [System.Windows.MessageBoxResult]::Yes) {
            try {
                # Remove from User and Machine paths
                Remove-ItemProperty -Path $script:RegFolderUser -Name $selected.RawTarget -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $script:RegFolderMachine -Name $selected.RawTarget -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $script:RegFileUser -Name $selected.RawTarget -Force -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $script:RegFileMachine -Name $selected.RawTarget -Force -ErrorAction SilentlyContinue

                Restart-OneDriveApp
                & $loadRules
                $LblStatus.Text = "Removed exclusion for '$($selected.RawTarget)'."
            } catch {
                [System.Windows.MessageBox]::Show("Error removing rule: $($_.Exception.Message)", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            }
        }
    })

    $BtnRefresh.Add_Click($loadRules)

    # Save .reg File (For Windows Reinstall)
    $BtnExportReg.Add_Click({
        $dialog = New-Object System.Windows.Forms.SaveFileDialog
        $dialog.Title = "Save Exclusions for Windows Reinstall"
        $dialog.Filter = "Registry Files (*.reg)|*.reg"
        $dialog.FileName = "OneDrive_Exclusions_Setup.reg"

        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            try {
                $sb = [System.Text.StringBuilder]::new()
                $sb.AppendLine("Windows Registry Editor Version 5.00") | Out-Null
                $sb.AppendLine("") | Out-Null

                $items = @($LvExclusions.ItemsSource)
                $folders = @($items | Where-Object { $_.Type -eq "Folder" } | Select-Object -ExpandProperty RawTarget -Unique)
                $files   = @($items | Where-Object { $_.Type -eq "File" } | Select-Object -ExpandProperty RawTarget -Unique)

                if ($folders.Count -eq 0 -and $files.Count -eq 0) {
                    $folders = @("WindowsPowerShell", "PowerShell")
                }

                # User Folder Policy
                $sb.AppendLine("[HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreFolderListFromGPO]") | Out-Null
                foreach ($f in $folders) { $sb.AppendLine("`"$f`"=`"$f`"") | Out-Null }
                $sb.AppendLine("") | Out-Null

                # Machine Folder Policy
                $sb.AppendLine("[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreFolderListFromGPO]") | Out-Null
                foreach ($f in $folders) { $sb.AppendLine("`"$f`"=`"$f`"") | Out-Null }
                $sb.AppendLine("") | Out-Null

                # Files Policy
                if ($files.Count -gt 0) {
                    $sb.AppendLine("[HKEY_CURRENT_USER\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO]") | Out-Null
                    foreach ($fl in $files) { $sb.AppendLine("`"$fl`"=`"$fl`"") | Out-Null }
                    $sb.AppendLine("") | Out-Null

                    $sb.AppendLine("[HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\EnableODIgnoreListFromGPO]") | Out-Null
                    foreach ($fl in $files) { $sb.AppendLine("`"$fl`"=`"$fl`"") | Out-Null }
                    $sb.AppendLine("") | Out-Null
                }

                [System.IO.File]::WriteAllText($dialog.FileName, $sb.ToString(), [System.Text.Encoding]::Unicode)
                $LblStatus.Text = "Exported setup file to $($dialog.FileName)."
                [System.Windows.MessageBox]::Show("Setup file saved successfully!`n`nWhenever you reinstall Windows, double-click this .reg file to instantly restore your OneDrive exclusions.", "Export Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            } catch {
                [System.Windows.MessageBox]::Show("Failed saving file: $($_.Exception.Message)", "Export Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            }
        }
    })

    $BtnClose.Add_Click({ $form.Close() })

    # Initial Load
    & $loadRules

    # Show Modal
    $form.ShowDialog() | Out-Null
}
