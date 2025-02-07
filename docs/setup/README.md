# Tools to install

!> Will be refactored into https://github.com/6uhrmittag/setup-workstation within 2025

# via patchmypc

see https://patchmypc.com/home-updater-download

- Foxit Reader
- ImageGlass
- Notepad++
- Dropbox
- Git version
- GitHub Desktop
- Google Chrome
- Microsoft Visual C++ 2010 x64 Redistributable
- Microsoft Visual C++ 2010 x86 Redistributable
- Microsoft Visual C++ 2012 Redistributable (x64)
- Microsoft Visual C++ 2012 Redistributable (x86)
- Mozilla Firefox
- TeraCopy version
- VLC media player
- WinRAR
- Wireshark

# manual setup

- Vagrant
- Virtualbox (Check Version - must work with Vagrant)
- [KiTTY](http://kitty.9bis.net/)
- Pycharms via jetbrains-toolbox
- https://www.binisoft.org/wfc
- https://github.com/jimradford/superputty
- https://portal.office.com/account
- https://sourceforge.net/projects/vcxsrv/
- https://www.samsung.com/semiconductor/minisite/ssd/product/consumer/magician/
- https://mpv.io/installation/

## via scoop (optional)

- https://github.com/lukesampson/scoop
- https://rasa.github.io/scoop-directory/by-stars

### install & setup scoop
````powershell
iwr -useb get.scoop.sh | iex
scoop install sudo # to use --global
scoop install aria2 # better download performance
sudo Add-MpPreference -ExclusionPath 'C:\Users\marvin\scoop'
sudo Add-MpPreference -ExclusionPath 'C:\ProgramData\scoop'
scoop install 7zip
scoop install innounp 
scoop install dark
scoop checkup

scoop bucket add scoop-completion https://github.com/Moeologist/scoop-completion
````

````powershell
scoop bucket add extras # add more Tools
scoop bucket add nirsoft # add nirsoft systemtools
scoop bucket add Sysinternals 'https://github.com/Ash258/Scoop-Sysinternals.git' # add sysinternal tools
scoop bucket add Ash258 'https://github.com/Ash258/Scoop-Ash258.git' # add more 3rd party tools
scoop install ProcessExplorer  
scoop install ProcessMonitor
scoop install screentogif
scoop install less
````

#### optional

````powershell
scoop install typora
scoop install JetBrains-Toolbox
scoop install mysql-workbench
scoop install heidisql
scoop install hosts-file-editor
scoop install screentogif
scoop install FullEventLogView
scoop install treesize-free
scoop install TeraCopy
````

#### Usage

````powershell
scoop list
scoop install <app>
sudo scoop install --global <app>
scoop update
scoop update <app>
scoop uninstall <app>
````

## manual config
### Putty

- https://github.com/jacktrocinski/pretty-putty
    - **Note:** Will change mouse-shortcut `right-click to paste/insert` to wheel-click! change after import back to right-click(Win default)

### Jetbrains IDE
- https://developpaper.com/using-typora-to-edit-markdown-file-in-pycharm/

### Logitech Capture

- https://www.logitech.com/de-de/software/capture.html

## Powershell

Moved to https://github.com/6uhrmittag/setup-workstation

## Windows Terminal

Moved to https://github.com/6uhrmittag/setup-workstation

## Experimental

### XServer Alternative

- install `GWSL` from MS Store

# Optional/Not 100% reviewed yet

- https://www.microsoft.com/en-us/p/openinwsl/9ngmqpwcg7sf?cid=msft_web_chart&activetab=pivot:overviewtab
- https://www.microsoft.com/en-us/p/windows-performance-analyzer/9n0w1b2bxgnz?cid=msft_web_chart&activetab=pivot:overviewtab
- https://www.microsoft.com/en-us/p/gwsl/9nl6kd1h33v3?activetab=pivot:overviewtab
  - https://opticos.github.io/gwsl/
- https://www.jetbrains.com/lp/mono/#how-to-install


## winget (experimental)

Search: https://winget.run/

### Notes aboute UAC
UAC interrupts installs. Use gsudo or disable/re-enable UAC manually before/after usage

https://github.com/gerardog/gsudo:
````powershell
winget install gerardog.gsudo
````

usage:

````text
# start new Shell with admin
gsudo -n
# make current session admin with cached creds
gsudo cache on
# disable cache
gsudo cache off
gsudo -k
````


#### Disable UAC via Powershell

Disable:

````powershell
Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 0
````

Re-enable UAC:

````powershell
Set-ItemProperty -Path REGISTRY::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System -Name ConsentPromptBehaviorAdmin -Value 2
````

### Basic Tools

````powershell
winget install -e --id Microsoft.WindowsTerminal
winget install -e --id Flow-Launcher.Flow-Launcher
winget install -e --id voidtools.Everything
winget install -e --id TorProject.TorBrowser
winget install -e --id CodeSector.TeraCopy
winget install -e --id DuongDieuPhap.ImageGlass
winget install -e --id QL-Win.QuickLook
winget install -e --id Google.Drive
winget install -e --id Google.Chrome
winget install -e --id Microsoft.MouseandKeyboardCenter
winget install -e --id JetBrains.Toolbox
winget install -e --id Microsoft.PowerShell
winget install -e --id mcmilk.7zip-zstd
winget install -e --id Logitech.LogiTune
winget install -e --id ogdesign.Eagle
winget install -e --id VideoLAN.VLC
winget install -e --id Notepad++.Notepad++
winget install -e --id Greenshot.Greenshot
winget install -e --id eMClient.eMClient
winget install -e --id HulubuluSoftware.AdvancedRenamer
winget install -e --id JAMSoftware.TreeSize.Free
````

### DevTools

````powershell
winget install -e --id=Python.Python.3
winget install -e --id JohnMacFarlane.Pandoc
winget install -e --id Mirantis.Lens
winget install -e --id scottlerch.hosts-file-editor
winget install -e --id HeidiSQL.HeidiSQL
winget install -e --id NickeManarin.ScreenToGif
````

### Update all

````powershell
winget upgrade --all
````

## putty/kitty

import/export Settings: https://www.9bis.net/kitty/#!pages/Portability.md

## superputty

copy dir: `~\Documents\SuperPuTTY`

## Windows 11 Tweaks

- TODO -

### Ressources:

- https://github.com/valinet/ExplorerPatcher
- https://github.com/99natmar99/Windows-11-Fixer
- https://github.com/bbmaster123/10SM
- https://github.com/awesome-windows11/windows11
- https://github.com/PeterStrick/ViVeTool-GUI
- https://github.com/ikas-mc/ContextMenuForWindows11
- https://github.com/farag2/Sophia-Script-for-Windows
- https://github.com/M2Team/NanaZip
