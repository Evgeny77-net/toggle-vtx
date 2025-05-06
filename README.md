# Quick switching Hyper-V and tied services on and off

When you use VirtualBox or VMware software on Windows PC you can meet problem with access to hardware acceleration technology Intel VT-x because it under control of Hyper-V by default. Also if you install Docker Desktop on Windows 10/11 today it required WSL2 that depends on Hyper-V. It's not very easy task to stop everything in Hyper-V services and allow VirtualBox for example to get all hardware advantages. The same about way to return back everything so you can normally start your containers early working in Docker Desktop. This PowerShell script solve this problem and make some automation when switching there and back. The toggle-vtx.ps1 script work in command line and you should use it like this:

`toggle-vtx.ps1 -mode docker`

if you want to setup using Intel VT-x by Hyper-V and other depending applications like Docker Desktop

`toggel-vtx.ps1 -mode vm`

if you want to switch Hyper-V off and allow VT-x for third party software.
To start script you should before allow excercurtion of PowerShell scripts with command

`Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

in PowerShell command line or create bat file where this option included as part of script launching command.
The toggle-vtx-GUI.ps1 is a variation of script that add simple GUI for selection mode.
File docker-vtx.bat is prepared bat file for launching toggle-vtx-GUI.ps1 script, you should only correct path to script there if bat file and script not in the same folder.

Happy using Intel VT-x in a convinient way!
