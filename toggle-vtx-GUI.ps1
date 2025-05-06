Add-Type -AssemblyName System.Windows.Forms

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Switch Hyper-V Mode"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"

# Add a label
$label = New-Object System.Windows.Forms.Label
$label.Text = "Choose the mode:"
$label.AutoSize = $true
$label.Location = New-Object System.Drawing.Point(30,20)
$form.Controls.Add($label)

# Add buttons
$btnDocker = New-Object System.Windows.Forms.Button
$btnDocker.Text = "Docker + WSL2 (Enable Hyper-V)"
$btnDocker.Size = New-Object System.Drawing.Size(300,30)
$btnDocker.Location = New-Object System.Drawing.Point(30,50)
$form.Controls.Add($btnDocker)

$btnVM = New-Object System.Windows.Forms.Button
$btnVM.Text = "VirtualBox / VMware (Disable Hyper-V)"
$btnVM.Size = New-Object System.Drawing.Size(300,30)
$btnVM.Location = New-Object System.Drawing.Point(30,90)
$form.Controls.Add($btnVM)

# Add cancel/close button
$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Cancel"
$btnCancel.Size = New-Object System.Drawing.Size(80,30)
$btnCancel.Location = New-Object System.Drawing.Point(150,130)
$form.Controls.Add($btnCancel)

function Set-HyperVMode {
    param (
        [string]$mode
    )

    if ($mode -eq "docker") {
        [System.Windows.Forms.MessageBox]::Show("Enabling Docker mode. Your PC will reboot.","Info")

        $featuresChanged = $false

        if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State -ne "Enabled") {
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -All -NoRestart
            $featuresChanged = $true
        }
        if ((Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -ne "Enabled") {
            Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart
            $featuresChanged = $true
        }
        if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne "Enabled") {
            Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart
            $featuresChanged = $true
        }

        bcdedit /set hypervisorlaunchtype auto

        if ($featuresChanged) {
            Restart-Computer
        } else {
            [System.Windows.Forms.MessageBox]::Show("Docker mode already enabled. Please reboot manually if needed.","No Changes")
        }
    }

    elseif ($mode -eq "vm") {
        [System.Windows.Forms.MessageBox]::Show("Enabling VM mode. Your PC will reboot.","Info")

        $featuresChanged = $false

        if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All).State -ne "Disabled") {
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
            $featuresChanged = $true
        }
        if ((Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -ne "Disabled") {
            Disable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
            $featuresChanged = $true
        }
        if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne "Disabled") {
            Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
            $featuresChanged = $true
        }

        bcdedit /set hypervisorlaunchtype off

        if ($featuresChanged) {
            Restart-Computer
        } else {
            [System.Windows.Forms.MessageBox]::Show("VM mode already enabled. Please reboot manually if needed.","No Changes")
        }
    }
}

# Button click events
$btnDocker.Add_Click({ $form.Close(); Set-HyperVMode -mode "docker" })
$btnVM.Add_Click({ $form.Close(); Set-HyperVMode -mode "vm" })
$btnCancel.Add_Click({ $form.Close() })

# Run the form
[void]$form.ShowDialog()
