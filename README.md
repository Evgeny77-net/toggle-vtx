# Quick switching Hyper-V and tied services on and off

When you use VirtualBox or VMware software on Windows PC you can meet problem with access to hardware acceleration technology Intel VT-x because it under control of Hyper-V by default. Also if you install Docker Desktop on Windows 10/11 today it required WSL2 that depends on Hyper-V. It's not very easy task to stop everything in Hyper-V services and allow VirtualBox for example to get all hardware advantages. The same about way to return back everything so you can normally start your containers early working in Docker Desktop. This PowerShell script solve this problem and make some automation when toggling. The **toggle-vtx.ps1** script work in PowerShell command line and you should use it like this:

`toggle-vtx.ps1 -mode docker`

Mode docker mean you want to enable Hyper-V and other depending services so Docker Desktop will works well too. In opposite case use:

`toggel-vtx.ps1 -mode vm`

This mean you want to switch Hyper-V off and allow VT-x for third party software like VMware or VirtualBox.
To start script you should before allow excercurtion of PowerShell scripts with command

`Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process`

or create bat file where this option included as part of script launching command.
The **toggle-vtx-GUI.ps1** is a variation of script that add simple GUI for selection mode and file **docker-vtx.bat** is prepared bat file for launching **toggle-vtx-GUI.ps1** script. 

You should only correct path to script there if bat file and script not in the same folder.

Happy using Virtualization and Docker Containers on Windows PC!
