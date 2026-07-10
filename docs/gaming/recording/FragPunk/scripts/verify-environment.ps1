<#
.SYNOPSIS
    Automates the environment checks from CLAUDE.md §7 for the FragPunk clip pipeline.

.DESCRIPTION
    Read-only except for the optional -DiskTest (writes and deletes one temp file).
    Touches OBS/Resolve/ffmpeg installs and the filesystem only — never the game client.

    Run in Windows PowerShell on the gaming PC:
        powershell -ExecutionPolicy Bypass -File .\verify-environment.ps1
        powershell -ExecutionPolicy Bypass -File .\verify-environment.ps1 -DiskTest

.PARAMETER DiskTest
    Write a 2 GB temp file to -TargetDir and report sequential throughput.

.PARAMETER TargetDir
    Recording target for the disk test. Default: %USERPROFILE%\Videos\FragPunk\masters
#>
[CmdletBinding()]
param(
    [switch]$DiskTest,
    [string]$TargetDir = (Join-Path $env:USERPROFILE 'Videos\FragPunk\masters')
)

$ErrorActionPreference = 'Continue'
$results = New-Object System.Collections.ArrayList

function Add-Result {
    param([string]$Check, [string]$Status, [string]$Detail, [string]$Action = '')
    [void]$results.Add([pscustomobject]@{ Check = $Check; Status = $Status; Detail = $Detail; Action = $Action })
}

function Get-UninstallEntry {
    param([string]$DisplayNamePattern)
    $roots = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty $roots -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like $DisplayNamePattern }
}

# --- 1. OBS Studio ------------------------------------------------------------
$obsExe = @(
    (Join-Path ${env:ProgramFiles} 'obs-studio\bin\64bit\obs64.exe'),
    'C:\Program Files\obs-studio\bin\64bit\obs64.exe'
) | Where-Object { Test-Path $_ } | Select-Object -First 1

if ($obsExe) {
    $obsVer = (Get-Item $obsExe).VersionInfo.ProductVersion
    if (-not $obsVer) { $obsVer = (Get-Item $obsExe).VersionInfo.FileVersion }
    Add-Result 'OBS Studio' 'PASS' "found $obsVer at $obsExe"
    # obs-websocket v5 is built into OBS >= 28, but must be *enabled*.
    $wsConfig = Join-Path $env:APPDATA 'obs-studio\plugin_config\obs-websocket\config.json'
    if (Test-Path $wsConfig) {
        try {
            $ws = Get-Content $wsConfig -Raw | ConvertFrom-Json
            if ($ws.server_enabled) {
                Add-Result 'obs-websocket' 'PASS' "enabled, port $($ws.server_port)"
            } else {
                Add-Result 'obs-websocket' 'FAIL' 'present but disabled' 'OBS: Tools -> WebSocket Server Settings -> Enable'
            }
        } catch {
            Add-Result 'obs-websocket' 'WARN' "config unreadable: $($_.Exception.Message)" 'check Tools -> WebSocket Server Settings in OBS'
        }
    } else {
        Add-Result 'obs-websocket' 'WARN' 'no config yet (OBS never opened WebSocket settings?)' 'OBS: Tools -> WebSocket Server Settings -> Enable, then re-run'
    }
    # Live reachability (only meaningful while OBS is running)
    $tcp = New-Object System.Net.Sockets.TcpClient
    try {
        $port = 4455
        if ($ws -and $ws.server_port) { $port = $ws.server_port }
        $async = $tcp.BeginConnect('127.0.0.1', $port, $null, $null)
        if ($async.AsyncWaitHandle.WaitOne(1500) -and $tcp.Connected) {
            Add-Result 'obs-websocket reachable' 'PASS' "127.0.0.1:$port accepts connections"
        } else {
            Add-Result 'obs-websocket reachable' 'WARN' "nothing listening on 127.0.0.1:$port" 'fine if OBS is not running right now'
        }
    } catch {
        Add-Result 'obs-websocket reachable' 'WARN' $_.Exception.Message 'fine if OBS is not running right now'
    } finally { $tcp.Close() }
} else {
    Add-Result 'OBS Studio' 'FAIL' 'obs64.exe not found in Program Files' 'install OBS: winget install OBSProject.OBSStudio'
}

# --- 2. ffmpeg / ffprobe ------------------------------------------------------
foreach ($tool in 'ffmpeg', 'ffprobe') {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        $verLine = (& $tool -version 2>$null | Select-Object -First 1)
        Add-Result $tool 'PASS' "$verLine"
    } else {
        Add-Result $tool 'FAIL' 'not on PATH' 'winget install Gyan.FFmpeg (then reopen the shell)'
    }
}

# --- 3. DaVinci Resolve: edition + scripting API ------------------------------
$resolveEntry = Get-UninstallEntry 'DaVinci Resolve*' | Select-Object -First 1
if ($resolveEntry) {
    $edition = 'Free'
    if ($resolveEntry.DisplayName -match 'Studio') { $edition = 'Studio' }
    Add-Result 'DaVinci Resolve' 'PASS' "$($resolveEntry.DisplayName) $($resolveEntry.DisplayVersion) -> edition: $edition"
    if ($edition -eq 'Studio') {
        Add-Result 'Resolve external scripting' 'PASS' 'Studio: external scripts allowed (enable in Preferences -> System -> General -> External scripting using local)'
    } else {
        Add-Result 'Resolve external scripting' 'WARN' 'Free edition: scripting is console-only' 'run resolve-setup.py from Resolve''s internal console (Workspace -> Console -> Py3), or upgrade to Studio'
    }
} else {
    Add-Result 'DaVinci Resolve' 'FAIL' 'not found in installed programs' 'install from blackmagicdesign.com'
}
$scriptingModules = 'C:\ProgramData\Blackmagic Design\DaVinci Resolve\Support\Developer\Scripting\Modules'
if (Test-Path (Join-Path $scriptingModules 'DaVinciResolveScript.py')) {
    Add-Result 'Resolve scripting module' 'PASS' $scriptingModules
} else {
    Add-Result 'Resolve scripting module' 'WARN' 'DaVinciResolveScript.py not at default path' 'verify Resolve install; resolve-setup.py also honors RESOLVE_SCRIPT_API'
}

# --- 4. Python / uv (for record-helper & resolve-setup) -----------------------
$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { $py = Get-Command py -ErrorAction SilentlyContinue }
if ($py) {
    Add-Result 'Python' 'PASS' ((& $py.Source --version 2>&1) -join ' ')
} else {
    Add-Result 'Python' 'WARN' 'no python/py on PATH' 'winget install Python.Python.3.12 (or rely on uv alone)'
}
$uv = Get-Command uv -ErrorAction SilentlyContinue
if ($uv) {
    Add-Result 'uv' 'PASS' ((& uv --version 2>&1) -join ' ')
} else {
    Add-Result 'uv' 'WARN' 'uv not on PATH (record_helper.py runs via "uv run")' 'winget install astral-sh.uv'
}

# --- 5. GPU / NVENC sanity -----------------------------------------------------
$smi = Get-Command nvidia-smi -ErrorAction SilentlyContinue
if ($smi) {
    $gpu = (& nvidia-smi --query-gpu=name,driver_version --format=csv,noheader 2>$null) -join '; '
    Add-Result 'NVIDIA GPU' 'PASS' $gpu
} else {
    Add-Result 'NVIDIA GPU' 'WARN' 'nvidia-smi not on PATH' 'expected on a 4090 box - check driver install'
}

# --- 6. Recording target dir + free space --------------------------------------
if (Test-Path $TargetDir) {
    $drive = (Get-Item $TargetDir).PSDrive
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    $status = 'PASS'; if ($freeGB -lt 100) { $status = 'WARN' }
    Add-Result 'Recording target' $status "$TargetDir ($freeGB GB free)" '4K120 CQP16 can exceed 1 GB/min - keep >100 GB free'
} else {
    Add-Result 'Recording target' 'WARN' "$TargetDir does not exist" "create it and set it as OBS Recording Path (see obs/README.md)"
}

if ($DiskTest) {
    if (-not (Test-Path $TargetDir)) { New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null }
    $testFile = Join-Path $TargetDir '__disktest.tmp'
    try {
        $sizeMB = 2048
        $buffer = New-Object byte[] (16MB)
        (New-Object Random).NextBytes($buffer)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $fs = [System.IO.File]::Create($testFile)
        for ($i = 0; $i -lt ($sizeMB / 16); $i++) { $fs.Write($buffer, 0, $buffer.Length) }
        $fs.Flush($true); $fs.Close()
        $sw.Stop()
        $mbps = [math]::Round($sizeMB / $sw.Elapsed.TotalSeconds, 0)
        # 4K120 CQP16 HEVC peaks are roughly 150-300 Mbit/s = 20-40 MB/s; anything >200 MB/s is comfortable.
        $status = 'PASS'; if ($mbps -lt 200) { $status = 'WARN' }
        Add-Result 'Disk write throughput' $status "$mbps MB/s sequential ($sizeMB MB test)"
    } catch {
        Add-Result 'Disk write throughput' 'WARN' $_.Exception.Message
    } finally {
        if (Test-Path $testFile) { Remove-Item $testFile -Force }
    }
}

# --- Manual items the script cannot check --------------------------------------
Add-Result 'AV1 decode in Resolve' 'MANUAL' 'import an AV1 file into Resolve and scrub it' 'until confirmed, stay on HEVC (current profile default)'
Add-Result 'FragPunk replay UI' 'MANUAL' 'camera modes / free-cam / HUD toggle / speed / retention' 'record findings in CLAUDE.md par. 7.3'
Add-Result 'Windows HDR off' 'MANUAL' 'Win+P -> Display settings: HDR & Auto HDR OFF before recording' 'see WORKFLOW.md prep checklist'

# --- Report ---------------------------------------------------------------------
$results | Format-Table -AutoSize -Wrap

$fails = @($results | Where-Object Status -eq 'FAIL')
$warns = @($results | Where-Object Status -eq 'WARN')
Write-Host ''
Write-Host ("Summary: {0} FAIL, {1} WARN, {2} manual item(s)." -f $fails.Count, $warns.Count, @($results | Where-Object Status -eq 'MANUAL').Count)
if ($fails.Count -gt 0) {
    Write-Host 'Fix the FAILs before the first recording session (actions listed above).'
    exit 1
}
exit 0
