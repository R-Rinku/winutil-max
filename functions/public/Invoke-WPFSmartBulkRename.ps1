function Invoke-WPFSmartBulkRename {
    <#
    .SYNOPSIS
        Launches the Smart Bulk Name Modifier / Renamer GUI.
    .DESCRIPTION
        An advanced bulk file and folder renamer with live preview, text replace, remove,
        prefix/suffix, numbering, case transformation, regex support, and automated permission resolution.
    #>
    [CmdletBinding()]
    param()

    Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms, System.Drawing

    # Build the WPF XAML
    [xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Smart Bulk Name Modifier - Windows Tweaks Hub"
        Width="920" Height="680" MinWidth="800" MinHeight="550"
        WindowStartupLocation="CenterScreen"
        Background="#18181B" Foreground="#F4F4F5"
        FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#27272A"/>
            <Setter Property="Foreground" Value="#F4F4F5"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="6,4"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#2563EB"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
        <Style TargetType="RadioButton">
            <Setter Property="Foreground" Value="#E4E4E7"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Margin" Value="0,0,14,0"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#E4E4E7"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="TextBlock">
            <Setter Property="Foreground" Value="#E4E4E7"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Foreground" Value="#60A5FA"/>
            <Setter Property="BorderBrush" Value="#3F3F46"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="10"/>
            <Setter Property="Margin" Value="0,0,0,10"/>
        </Style>
    </Window.Resources>

    <Grid Margin="16">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/> <!-- Folder Picker -->
            <RowDefinition Height="Auto"/> <!-- Operation Controls -->
            <RowDefinition Height="Auto"/> <!-- Scope & Filters -->
            <RowDefinition Height="*"/>    <!-- Preview Grid -->
            <RowDefinition Height="Auto"/> <!-- Status & Actions -->
        </Grid.RowDefinitions>

        <!-- Folder Selection -->
        <Border Grid.Row="0" Background="#202024" BorderBrush="#27272A" BorderThickness="1" CornerRadius="6" Padding="12" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="Target Folder:" FontWeight="Bold" FontSize="13" VerticalAlignment="Center" Margin="0,0,12,0"/>
                <TextBox Grid.Column="1" Name="TxtFolder" VerticalAlignment="Center" Height="28"/>
                <Button Grid.Column="2" Name="BtnBrowse" Content="Browse..." Margin="8,0,0,0" Height="28" Width="90"/>
                <Button Grid.Column="3" Name="BtnRefresh" Content="Scan" Margin="8,0,0,0" Height="28" Width="70" Background="#3F3F46"/>
            </Grid>
        </Border>

        <!-- Operation Tabs / Modes -->
        <GroupBox Grid.Row="1" Header="Renaming Rule">
            <StackPanel>
                <WrapPanel Margin="0,0,0,10">
                    <RadioButton Name="RbModeReplace" Content="Replace / Remove" IsChecked="True"/>
                    <RadioButton Name="RbModeAdd" Content="Add Prefix / Suffix"/>
                    <RadioButton Name="RbModeCase" Content="Change Case"/>
                    <RadioButton Name="RbModeNumber" Content="Numbering / Sequence"/>
                </WrapPanel>

                <!-- Panel 1: Replace / Remove -->
                <Grid Name="PanelReplace" Margin="0,4,0,0">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <TextBlock Grid.Row="0" Grid.Column="0" Text="Find Text:" VerticalAlignment="Center" Margin="0,0,8,6"/>
                    <TextBox Grid.Row="0" Grid.Column="1" Name="TxtFind" Margin="0,0,16,6" Height="26"/>
                    <TextBlock Grid.Row="0" Grid.Column="2" Text="Replace With:" VerticalAlignment="Center" Margin="0,0,8,6"/>
                    <TextBox Grid.Row="0" Grid.Column="3" Name="TxtReplace" Margin="0,0,0,6" Height="26" ToolTip="Leave blank to remove find text"/>

                    <StackPanel Grid.Row="1" Grid.Column="1" Grid.ColumnSpan="3" Orientation="Horizontal" Margin="0,2,0,0">
                        <CheckBox Name="ChkMatchCase" Content="Match Case" Margin="0,0,20,0"/>
                        <CheckBox Name="ChkUseRegex" Content="Regular Expressions (Regex)"/>
                    </StackPanel>
                </Grid>

                <!-- Panel 2: Add Prefix / Suffix -->
                <Grid Name="PanelAdd" Margin="0,4,0,0" Visibility="Collapsed">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="Add Prefix:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox Grid.Column="1" Name="TxtPrefix" Margin="0,0,16,0" Height="26"/>
                    <TextBlock Grid.Column="2" Text="Add Suffix:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox Grid.Column="3" Name="TxtSuffix" Margin="0,0,0,0" Height="26"/>
                </Grid>

                <!-- Panel 3: Change Case -->
                <StackPanel Name="PanelCase" Orientation="Horizontal" Margin="0,4,0,0" Visibility="Collapsed">
                    <RadioButton Name="RbCaseLower" Content="lowercase" IsChecked="True"/>
                    <RadioButton Name="RbCaseUpper" Content="UPPERCASE"/>
                    <RadioButton Name="RbCaseTitle" Content="Title Case"/>
                    <RadioButton Name="RbCaseSentence" Content="Sentence case"/>
                </StackPanel>

                <!-- Panel 4: Numbering -->
                <Grid Name="PanelNumber" Margin="0,4,0,0" Visibility="Collapsed">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="80"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="80"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="*"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Grid.Column="0" Text="Start At:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox Grid.Column="1" Name="TxtStartNum" Text="1" Height="26" Margin="0,0,16,0"/>
                    <TextBlock Grid.Column="2" Text="Digits (01):" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox Grid.Column="3" Name="TxtPadding" Text="2" Height="26" Margin="0,0,16,0"/>
                    <TextBlock Grid.Column="4" Text="Separator:" VerticalAlignment="Center" Margin="0,0,8,0"/>
                    <TextBox Grid.Column="5" Name="TxtSeparator" Text="_" Height="26" Width="60" HorizontalAlignment="Left"/>
                </Grid>
            </StackPanel>
        </GroupBox>

        <!-- Scope & Filters -->
        <Border Grid.Row="2" Background="#202024" BorderBrush="#27272A" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,0,0,10">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="Auto"/>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <TextBlock Grid.Column="0" Text="Apply To:" FontWeight="SemiBold" VerticalAlignment="Center" Margin="0,0,14,0"/>
                <StackPanel Grid.Column="1" Orientation="Horizontal">
                    <RadioButton Name="RbScopeName" Content="File Name" IsChecked="True"/>
                    <RadioButton Name="RbScopeExt" Content="Extension"/>
                    <RadioButton Name="RbScopeBoth" Content="Both"/>
                </StackPanel>
                <StackPanel Grid.Column="3" Orientation="Horizontal">
                    <CheckBox Name="ChkSubfolders" Content="Include Subfolders" Margin="0,0,16,0"/>
                    <TextBlock Text="Filter:" VerticalAlignment="Center" Margin="0,0,6,0"/>
                    <TextBox Name="TxtFilter" Text="*.*" Width="70" Height="24"/>
                </StackPanel>
            </Grid>
        </Border>

        <!-- Preview Grid -->
        <GroupBox Grid.Row="3" Header="Live Preview">
            <DataGrid Name="DgPreview" AutoGenerateColumns="False" IsReadOnly="True"
                      Background="#18181B" Foreground="#F4F4F5" RowBackground="#202024"
                      AlternatingRowBackground="#27272A" BorderThickness="0"
                      GridLinesVisibility="Horizontal" HorizontalGridLinesBrush="#3F3F46"
                      HeadersVisibility="Column" SelectionMode="Single">
                <DataGrid.ColumnHeaderStyle>
                    <Style TargetType="DataGridColumnHeader">
                        <Setter Property="Background" Value="#27272A"/>
                        <Setter Property="Foreground" Value="#93C5FD"/>
                        <Setter Property="FontWeight" Value="SemiBold"/>
                        <Setter Property="Padding" Value="8,5"/>
                        <Setter Property="BorderThickness" Value="0,0,1,1"/>
                        <Setter Property="BorderBrush" Value="#3F3F46"/>
                    </Style>
                </DataGrid.ColumnHeaderStyle>
                <DataGrid.Columns>
                    <DataGridTextColumn Header="Status" Binding="{Binding Status}" Width="110"/>
                    <DataGridTextColumn Header="Original Name" Binding="{Binding OriginalName}" Width="2*"/>
                    <DataGridTextColumn Header="New Name" Binding="{Binding NewName}" Width="2*"/>
                    <DataGridTextColumn Header="Relative Path" Binding="{Binding RelativeFolder}" Width="*"/>
                </DataGrid.Columns>
            </DataGrid>
        </GroupBox>

        <!-- Status & Actions -->
        <Grid Grid.Row="4" Margin="0,8,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Grid.Column="0" Name="LblStatus" Text="Ready. Select a folder to begin." VerticalAlignment="Center" Foreground="#A1A1AA" FontSize="12"/>
            <Button Grid.Column="1" Name="BtnPreview" Content="Update Preview" Margin="0,0,10,0" Background="#3F3F46" Height="34" Width="130"/>
            <Button Grid.Column="2" Name="BtnExecute" Content="Apply Renaming" Background="#059669" Height="34" Width="140"/>
        </Grid>
    </Grid>
</Window>
"@

    $reader = New-Object System.Xml.XmlNodeReader($xaml)
    $form = [Windows.Markup.XamlReader]::Load($reader)

    # Cache Controls
    $TxtFolder     = $form.FindName("TxtFolder")
    $BtnBrowse     = $form.FindName("BtnBrowse")
    $BtnRefresh    = $form.FindName("BtnRefresh")
    $RbModeReplace = $form.FindName("RbModeReplace")
    $RbModeAdd     = $form.FindName("RbModeAdd")
    $RbModeCase    = $form.FindName("RbModeCase")
    $RbModeNumber  = $form.FindName("RbModeNumber")
    $PanelReplace  = $form.FindName("PanelReplace")
    $PanelAdd      = $form.FindName("PanelAdd")
    $PanelCase     = $form.FindName("PanelCase")
    $PanelNumber   = $form.FindName("PanelNumber")
    $TxtFind       = $form.FindName("TxtFind")
    $TxtReplace    = $form.FindName("TxtReplace")
    $ChkMatchCase  = $form.FindName("ChkMatchCase")
    $ChkUseRegex   = $form.FindName("ChkUseRegex")
    $TxtPrefix     = $form.FindName("TxtPrefix")
    $TxtSuffix     = $form.FindName("TxtSuffix")
    $RbCaseLower   = $form.FindName("RbCaseLower")
    $RbCaseUpper   = $form.FindName("RbCaseUpper")
    $RbCaseTitle   = $form.FindName("RbCaseTitle")
    $RbCaseSentence= $form.FindName("RbCaseSentence")
    $TxtStartNum   = $form.FindName("TxtStartNum")
    $TxtPadding    = $form.FindName("TxtPadding")
    $TxtSeparator  = $form.FindName("TxtSeparator")
    $RbScopeName   = $form.FindName("RbScopeName")
    $RbScopeExt    = $form.FindName("RbScopeExt")
    $RbScopeBoth   = $form.FindName("RbScopeBoth")
    $ChkSubfolders = $form.FindName("ChkSubfolders")
    $TxtFilter     = $form.FindName("TxtFilter")
    $DgPreview     = $form.FindName("DgPreview")
    $LblStatus     = $form.FindName("LblStatus")
    $BtnPreview    = $form.FindName("BtnPreview")
    $BtnExecute    = $form.FindName("BtnExecute")

    # Set Window Icon if available
    try {
        $appIcon = Get-WinUtilAppIcon
        if ($null -ne $appIcon) { $form.Icon = $appIcon }
    } catch {}

    # State
    $script:cachedFiles = @()

    # Permission Fix Helper
    function Grant-FileAccess {
        param($Path)
        try {
            takeown /f "$Path" /a /d y | Out-Null
            icacls "$Path" /grant Administrators:F /c | Out-Null
        } catch {}
    }

    # Switch Mode Panels
    $updatePanels = {
        $PanelReplace.Visibility = if ($RbModeReplace.IsChecked) { "Visible" } else { "Collapsed" }
        $PanelAdd.Visibility     = if ($RbModeAdd.IsChecked) { "Visible" } else { "Collapsed" }
        $PanelCase.Visibility    = if ($RbModeCase.IsChecked) { "Visible" } else { "Collapsed" }
        $PanelNumber.Visibility  = if ($RbModeNumber.IsChecked) { "Visible" } else { "Collapsed" }
        & $updatePreview
    }

    $RbModeReplace.Add_Checked($updatePanels)
    $RbModeAdd.Add_Checked($updatePanels)
    $RbModeCase.Add_Checked($updatePanels)
    $RbModeNumber.Add_Checked($updatePanels)

    # Scan Files
    $scanFiles = {
        $folder = $TxtFolder.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($folder) -or -not (Test-Path $folder)) {
            $LblStatus.Text = "Please select a valid folder."
            $script:cachedFiles = @()
            $DgPreview.ItemsSource = $null
            return
        }

        $filter = if ([string]::IsNullOrWhiteSpace($TxtFilter.Text)) { "*.*" } else { $TxtFilter.Text.Trim() }
        $recurse = [bool]$ChkSubfolders.IsChecked

        try {
            $gciParams = @{
                Path = $folder
                Filter = $filter
                File = $true
                ErrorAction = "SilentlyContinue"
            }
            if ($recurse) { $gciParams["Recurse"] = $true }

            $script:cachedFiles = @(Get-ChildItem @gciParams)
            $LblStatus.Text = "Scanned $($script:cachedFiles.Count) files."
            & $updatePreview
        } catch {
            $LblStatus.Text = "Error scanning folder: $($_.Exception.Message)"
        }
    }

    # Compute Preview
    $updatePreview = {
        if ($script:cachedFiles.Count -eq 0) {
            $DgPreview.ItemsSource = $null
            return
        }

        $folder = $TxtFolder.Text.Trim()
        $previewItems = [System.Collections.Generic.List[PSCustomObject]]::new()
        $willChangeCount = 0

        $startNum = 1
        [int]::TryParse($TxtStartNum.Text, [ref]$startNum) | Out-Null
        $padding = 2
        [int]::TryParse($TxtPadding.Text, [ref]$padding) | Out-Null
        $padFormat = "D$padding"
        $currentNum = $startNum
        $separator = $TxtSeparator.Text

        $findText = $TxtFind.Text
        $replaceText = $TxtReplace.Text
        $isRegex = [bool]$ChkUseRegex.IsChecked
        $matchCase = [bool]$ChkMatchCase.IsChecked

        $prefix = $TxtPrefix.Text
        $suffix = $TxtSuffix.Text

        foreach ($file in $script:cachedFiles) {
            $base = $file.BaseName
            $ext  = $file.Extension

            # Apply Rule
            if ($RbModeReplace.IsChecked -and -not [string]::IsNullOrEmpty($findText)) {
                try {
                    $pattern = if ($isRegex) { $findText } else { [regex]::Escape($findText) }
                    $regexOptions = if ($matchCase) { [System.Text.RegularExpressions.RegexOptions]::None } else { [System.Text.RegularExpressions.RegexOptions]::IgnoreCase }
                    
                    if ($RbScopeName.IsChecked -or $RbScopeBoth.IsChecked) {
                        $base = [regex]::Replace($base, $pattern, $replaceText, $regexOptions)
                    }
                    if ($RbScopeExt.IsChecked -or $RbScopeBoth.IsChecked) {
                        $ext = [regex]::Replace($ext, $pattern, $replaceText, $regexOptions)
                    }
                } catch {}
            }
            elseif ($RbModeAdd.IsChecked) {
                if ($RbScopeName.IsChecked -or $RbScopeBoth.IsChecked) {
                    $base = "$prefix$base$suffix"
                }
            }
            elseif ($RbModeCase.IsChecked) {
                $textInfo = (Get-Culture).TextInfo
                if ($RbCaseLower.IsChecked) {
                    if ($RbScopeName.IsChecked -or $RbScopeBoth.IsChecked) { $base = $base.ToLower() }
                    if ($RbScopeExt.IsChecked -or $RbScopeBoth.IsChecked) { $ext = $ext.ToLower() }
                }
                elseif ($RbCaseUpper.IsChecked) {
                    if ($RbScopeName.IsChecked -or $RbScopeBoth.IsChecked) { $base = $base.ToUpper() }
                    if ($RbScopeExt.IsChecked -or $RbScopeBoth.IsChecked) { $ext = $ext.ToUpper() }
                }
                elseif ($RbCaseTitle.IsChecked) {
                    if ($RbScopeName.IsChecked -or $RbScopeBoth.IsChecked) { $base = $textInfo.ToTitleCase($base.ToLower()) }
                }
                elseif ($RbCaseSentence.IsChecked) {
                    if ($base.Length -gt 0) {
                        $base = $base.Substring(0,1).ToUpper() + $base.Substring(1).ToLower()
                    }
                }
            }
            elseif ($RbModeNumber.IsChecked) {
                $numStr = $currentNum.ToString($padFormat)
                $base = "$base$separator$numStr"
                $currentNum++
            }

            $newName = "$base$ext"
            $relative = if ($file.DirectoryName.Length -ge $folder.Length) {
                $file.DirectoryName.Substring($folder.Length).TrimStart('\')
            } else { "" }
            if ([string]::IsNullOrEmpty($relative)) { $relative = "." }

            $hasChanged = ($newName -ne $file.Name)
            if ($hasChanged) { $willChangeCount++ }

            $previewItems.Add([PSCustomObject]@{
                Status         = if ($hasChanged) { "Will Rename" } else { "Unchanged" }
                OriginalName   = $file.Name
                NewName        = $newName
                RelativeFolder = $relative
                FullPath       = $file.FullName
                NewFullPath    = (Join-Path $file.DirectoryName $newName)
                HasChanged     = $hasChanged
            })
        }

        $DgPreview.ItemsSource = $previewItems
        $LblStatus.Text = "Files: $($script:cachedFiles.Count) | Will Rename: $willChangeCount | Unchanged: $($script:cachedFiles.Count - $willChangeCount)"
    }

    # Browse Button
    $BtnBrowse.Add_Click({
        $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $dialog.Description = "Select Folder for Bulk Renaming"
        if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
            $TxtFolder.Text = $dialog.SelectedPath
            & $scanFiles
        }
    })

    $BtnRefresh.Add_Click($scanFiles)
    $BtnPreview.Add_Click($updatePreview)

    # Realtime triggers on input change
    $TxtFind.Add_TextChanged($updatePreview)
    $TxtReplace.Add_TextChanged($updatePreview)
    $TxtPrefix.Add_TextChanged($updatePreview)
    $TxtSuffix.Add_TextChanged($updatePreview)
    $TxtStartNum.Add_TextChanged($updatePreview)
    $TxtPadding.Add_TextChanged($updatePreview)
    $TxtSeparator.Add_TextChanged($updatePreview)
    $ChkMatchCase.Add_Click($updatePreview)
    $ChkUseRegex.Add_Click($updatePreview)
    $RbScopeName.Add_Click($updatePreview)
    $RbScopeExt.Add_Click($updatePreview)
    $RbScopeBoth.Add_Click($updatePreview)
    $RbCaseLower.Add_Click($updatePreview)
    $RbCaseUpper.Add_Click($updatePreview)
    $RbCaseTitle.Add_Click($updatePreview)
    $RbCaseSentence.Add_Click($updatePreview)

    # Execute Rename
    $BtnExecute.Add_Click({
        $items = @($DgPreview.ItemsSource | Where-Object { $_.HasChanged })
        if ($items.Count -eq 0) {
            [System.Windows.MessageBox]::Show("No file names will be changed under the current rules.", "Smart Renamer", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }

        $confirm = [System.Windows.MessageBox]::Show("Are you sure you want to rename $($items.Count) file(s)?", "Confirm Bulk Rename", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
        if ($confirm -ne [System.Windows.MessageBoxResult]::Yes) { return }

        $successCount = 0
        $failCount = 0

        foreach ($item in $items) {
            try {
                if (Test-Path $item.NewFullPath) {
                    # Skip if collision
                    $failCount++
                    continue
                }
                Rename-Item -LiteralPath $item.FullPath -NewName (Split-Path $item.NewFullPath -Leaf) -ErrorAction Stop
                $successCount++
            } catch {
                # Attempt permission elevation/grant access then retry
                try {
                    Grant-FileAccess $item.FullPath
                    Rename-Item -LiteralPath $item.FullPath -NewName (Split-Path $item.NewFullPath -Leaf) -ErrorAction Stop
                    $successCount++
                } catch {
                    $failCount++
                }
            }
        }

        [System.Windows.MessageBox]::Show("Rename complete!`n`nSuccessfully renamed: $successCount file(s)`nFailed / skipped: $failCount file(s)", "Renaming Complete", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null

        & $scanFiles
    })

    $form.ShowDialog() | Out-Null
}
