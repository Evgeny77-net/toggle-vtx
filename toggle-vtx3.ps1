# ===================================================================================
# ScriptName : toggle-vtx.ps1
# Version    : v1.0
# Author     : Evgeny Ageev
# Created On : 2025-05-05
# Last Modified: 2025-06-05
#
# Description:
#   A simple script that switching Hyper-V services on and off to use Intel VT-x by MS Windows applications or third party ones.
#
# Copyright © 2025 Evgeny Ageev.
# All rights reserved.
# Unauthorized copying or redistribution strictly prohibited.
# ===================================================================================

param (
    [Parameter(Mandatory = $true)]
    [ValidateSet("docker", "vm")]
    [string]$mode
)

function Set-HyperVMode {
    param (
        [string]$desiredMode
    )

    if ($desiredMode -eq "docker") {
        Write-Host "Switching to Docker + WSL2 mode (enabling Hyper-V)..."

        # Enable necessary features
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
            Write-Host "Features updated. Rebooting is required..."
            Restart-Computer
        } else {
            Write-Host "All required features are already enabled."
            Write-Host "If Docker Desktop still fails, manually reboot to finalize feature registration."
        }

    } elseif ($desiredMode -eq "vm") {
        Write-Host "Switching to VirtualBox/VMWare mode (disabling Hyper-V)..."

        # Disable features
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
            Write-Host "Features updated. Rebooting is required..."
            Restart-Computer
        } else {
            Write-Host "All unnecessary features already disabled."
            Write-Host "If VirtualBox/VMWare still show VT-x unavailable, manually reboot."
        }
    }
}

Set-HyperVMode -desiredMode $mode
