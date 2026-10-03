# =============================================================================
# ScriptName : toggle-vtx-GUI-v1.2.ps1
# Version    : v1.2
# Author     : Evgeny Ageev (Fixed)
# Description: GUI script to switch Hyper-V / VBS (Memory Integrity / HVCI) on and off so you 
#              can use Intel VT-x/AMD-V with either Windows-integrated virtualization (Docker/WSL2) 
#              or third-party hypervisors (VMware/VirtualBox).
#
# Notes:       - Must be run as Administrator.
#              - Enabling/disabling VBS (Memory Integrity) requires registry changes and reboot.
#              - The script toggles Windows optional features, registry keys for VBS, and 
#                bcdedit hypervisorlaunchtype.
# =============================================================================

# Ensure running as admin
Add-Type -AssemblyName System.Windows.Forms
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show("Please run this script elevated (as Administrator).","Elevation required")
    exit 1
}

function Get-FeatureState($name) {
    try {
        $f = Get-WindowsOptionalFeature -Online -FeatureName $name -ErrorAction Stop
        return $f.State
    } catch {
        return $null
    }
}

function Get-HypervisorLaunchType {
    $bcd = bcdedit 2>$null
    if ($bcd -match "hypervisorlaunchtype\s+([a-zA-Z]+)") {
        return $matches[1]
    } else {
        return $null
    }
}

function Get-VBSState {
    # Read DeviceGuard keys to determine whether VBS/HVCI is enabled
    try {
        $dgPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
        $hvciPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
        
        $vbs = $false
        $hvciEnabled = $false

        if (Test-Path $dgPath) {
            $dgd = Get-ItemProperty -Path $dgPath -ErrorAction SilentlyContinue
            if ($dgd -and $dgd.PSObject.Properties.Name -contains 'EnableVirtualizationBasedSecurity') {
                $vbs = [bool]$dgd.EnableVirtualizationBasedSecurity
            }
        }
        
        if (Test-Path $hvciPath) {
            $hvcikey = Get-ItemProperty -Path $hvciPath -ErrorAction SilentlyContinue
            if ($hvcikey -and $hvcikey.PSObject.Properties.Name -contains 'Enabled') {
                $hvciEnabled = [bool]$hvcikey.Enabled
            }
        }
        
        return @{ VBS = $vbs; HVCI = $hvciEnabled }
    } catch {
        return @{ VBS = $false; HVCI = $false }
    }
}

function Set-VBS($enable) {
    # Enable/disable VBS and HVCI via registry keys
    $dgPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
    $hvciPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity'
    
    if (-not (Test-Path $dgPath)) { New-Item -Path $dgPath -Force | Out-Null }
    if (-not (Test-Path $hvciPath)) { New-Item -Path $hvciPath -Force | Out-Null }
    
    if ($enable) {
        Set-ItemProperty -Path $dgPath -Name 'EnableVirtualizationBasedSecurity' -Value 1 -Force | Out-Null
        Set-ItemProperty -Path $hvciPath -Name 'Enabled' -Value 1 -Force | Out-Null
    } else {
        Set-ItemProperty -Path $dgPath -Name 'EnableVirtualizationBasedSecurity' -Value 0 -Force | Out-Null
        Set-ItemProperty -Path $hvciPath -Name 'Enabled' -Value 0 -Force | Out-Null
    }
}

function Show-Status {
    $hvFeature = Get-FeatureState -name 'Microsoft-Hyper-V-All'
    $vmpFeature = Get-FeatureState -name 'VirtualMachinePlatform'
    $wslFeature = Get-FeatureState -name 'Microsoft-Windows-Subsystem-Linux'
    $bcdType = Get-HypervisorLaunchType
    $vbs = Get-VBSState
    $statusText = "Feature Hyper-V: $hvFeature`r`nVirtualMachinePlatform: $vmpFeature`r`nWSL: $wslFeature`r`nBCDEdit: $bcdType`r`nVBS: $($vbs.VBS) | HVCI: $($vbs.HVCI)"
    return $statusText
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Switch Hyper-V / VBS Mode"
$form.Size = New-Object System.Drawing.Size(520,340)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

# Label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Choose the mode you want to enable. Note: changes require reboot."
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(12,10)
$form.Controls.Add($label)

# Status box
$txtStatus = New-Object System.Windows.Forms.TextBox
$txtStatus.Multiline = $true
$txtStatus.ReadOnly = $true
$txtStatus.ScrollBars = 'Vertical'
$txtStatus.Size = New-Object System.Drawing.Size(480,120)
$txtStatus.Location = New-Object System.Drawing.Point(12,40)
$txtStatus.Text = Show-Status
$form.Controls.Add($txtStatus)

# Buttons
$btnDocker = New-Object System.Windows.Forms.Button
$btnDocker.Text = "Docker + WSL2 (Enable Hyper-V + VBS)"
$btnDocker.Size = New-Object System.Drawing.Size(480,30)
$btnDocker.Location = New-Object System.Drawing.Point(12,170)
$form.Controls.Add($btnDocker)

$btnVM = New-Object System.Windows.Forms.Button
$btnVM.Text = "VirtualBox / VMware (Disable Hyper-V + VBS)"
$btnVM.Size = New-Object System.Drawing.Size(480,30)
$btnVM.Location = New-Object System.Drawing.Point(12,210)
$form.Controls.Add($btnVM)

$btnRefresh = New-Object System.Windows.Forms.Button
$btnRefresh.Text = "Refresh Status"
$btnRefresh.Size = New-Object System.Drawing.Size(120,30)
$btnRefresh.Location = New-Object System.Drawing.Point(12,250)
$form.Controls.Add($btnRefresh)

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Size = New-Object System.Drawing.Size(120,30)
$btnCancel.Location = New-Object System.Drawing.Point(372,250)
$form.Controls.Add($btnCancel)

function Enable-DockerMode {
    [System.Windows.Forms.MessageBox]::Show("Enabling Docker/WSL2 mode. The system will reboot if changes are applied.", "Info")
    $featuresChanged = $false
    $vbsChanged = $false
    $bcdChanged = $false

    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart -ErrorAction SilentlyContinue | Out-Null
        $featuresChanged = $true
    }
    if ((Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart -ErrorAction SilentlyContinue | Out-Null
        $featuresChanged = $true
    }
    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne "Enabled") {
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart -ErrorAction SilentlyContinue | Out-Null
        $featuresChanged = $true
    }

    # Enable VBS / HVCI
    $vbs = Get-VBSState
    if (-not $vbs.VBS -or -not $vbs.HVCI) {
        Set-VBS -enable $true
        $vbsChanged = $true
    }

    # Turn on Hyper-V loader
    if ((Get-HypervisorLaunchType) -ne "Auto") {
        bcdedit /set hypervisorlaunchtype auto | Out-Null
        $bcdChanged = $true
    }

    if ($featuresChanged -or $vbsChanged -or $bcdChanged) {
        $res = [System.Windows.Forms.MessageBox]::Show("Changes applied successfully. Rebooting now is highly recommended. Reboot now?", "Reboot Required", [System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
            Restart-Computer -Force
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("Docker mode already fully enabled. No changes needed.", "No Changes")
    }
}

function Enable-VMMode {
    [System.Windows.Forms.MessageBox]::Show("Enabling VM mode (Hyper-V and VBS disabled). The system will reboot if changes are applied.", "Info")
    $featuresChanged = $false
    $vbsChanged = $false
    $bcdChanged = $false

    if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State -eq "Enabled") {
        Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart -ErrorAction SilentlyContinue | Out-Null
        $featuresChanged = $true
    }
    if ((Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -eq "Enabled") {
        Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -ErrorAction SilentlyContinue | Out-Null
        $featuresChanged = $true
    }

    # Disable VBS / HVCI
    $vbs = Get-VBSState
    if ($vbs.VBS -or $vbs.HVCI) {
        Set-VBS -enable $false
        $vbsChanged = $true
    }

    # Turn off Hyper-V loader to unlock raw VT-x/AMD-V
    if ((Get-HypervisorLaunchType) -ne "Off") {
        bcdedit /set hypervisorlaunchtype off | Out-Null
        $bcdChanged = $true
    }

    if ($featuresChanged -or $vbsChanged -or $bcdChanged) {
        $res = [System.Windows.Forms.MessageBox]::Show("Changes applied successfully. You MUST reboot to release raw hardware virtualization. Reboot now?", "Reboot Required", [System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($res -eq [System.Windows.Forms.DialogResult]::Yes) {
            Restart-Computer -Force
        }
    } else {
        [System.Windows.Forms.MessageBox]::Show("VM mode already fully enabled (Hyper-V is off). No changes needed.", "No Changes")
    }
}

# Bind events to buttons
$btnDocker.Add_Click({ Enable-DockerMode; $txtStatus.Text = Show-Status })
$btnVM.Add_Click({ Enable-VMMode; $txtStatus.Text = Show-Status })
$btnRefresh.Add_Click({ $txtStatus.Text = Show-Status })
$btnCancel.Add_Click({ $form.Close() })

# Display Form
$form.ShowDialog() | Out-Null