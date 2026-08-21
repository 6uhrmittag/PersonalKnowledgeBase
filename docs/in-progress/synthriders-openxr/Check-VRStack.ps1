<#
.SYNOPSIS
    Doctor script for the "VR game starts but never renders into the headset" class of problem.

.DESCRIPTION
    Prints the things that actually decide whether an OpenXR title can reach the headset:
      1. which OpenXR runtime is active (registry + XR_RUNTIME_JSON override)
      2. which implicit API layers get injected into every OpenXR app
      3. what VDXR logged the last time an app asked it for an instance
      4. a verdict from the game's own Unity log: layers seen, session state reached
      5. whether the app reached SteamVR's OpenXR runtime, and any launch timeouts

    Read-only. Safe to run at any time, elevated or not.

.EXAMPLE
    .\Check-VRStack.ps1
#>

[CmdletBinding()]
param(
    [string]$SteamRoot = 'C:\Program Files (x86)\Steam',
    [string]$GameLog   = "$env:USERPROFILE\AppData\LocalLow\Kluge Interactive\SynthRiders\Player.log",
    [string]$XrClient  = 'xrclient_SynthRiders.txt'
)

function Write-Section($Title) {
    Write-Host ''
    Write-Host "=== $Title " -ForegroundColor Cyan -NoNewline
    Write-Host ('=' * [Math]::Max(0, 58 - $Title.Length)) -ForegroundColor Cyan
}

Write-Section 'Active OpenXR runtime'
foreach ($k in @(
    @{ Name = 'HKLM (64-bit)'; Path = 'HKLM:\SOFTWARE\Khronos\OpenXR\1' },
    @{ Name = 'HKLM (32-bit)'; Path = 'HKLM:\SOFTWARE\WOW6432Node\Khronos\OpenXR\1' },
    @{ Name = 'HKCU override'; Path = 'HKCU:\SOFTWARE\Khronos\OpenXR\1' }
)) {
    $v = (Get-ItemProperty $k.Path -Name ActiveRuntime -ErrorAction SilentlyContinue).ActiveRuntime
    '{0,-15} {1}' -f $k.Name, $(if ($v) { $v } else { '(not set)' })
}
$override = $null
foreach ($scope in 'Machine', 'User', 'Process') {
    $v = [Environment]::GetEnvironmentVariable('XR_RUNTIME_JSON', $scope)
    if ($v) {
        $override = $v
        Write-Host ("XR_RUNTIME_JSON ($scope) WINS over the registry: $v") -ForegroundColor Green
    }
}
if (-not $override) { 'XR_RUNTIME_JSON  (not set - the registry value above decides)' }

Write-Section 'Implicit API layers (injected into every OpenXR app)'
foreach ($root in 'HKLM:\SOFTWARE\Khronos\OpenXR\1',
                  'HKLM:\SOFTWARE\WOW6432Node\Khronos\OpenXR\1',
                  'HKCU:\SOFTWARE\Khronos\OpenXR\1') {
    $p = "$root\ApiLayers\Implicit"
    if (-not (Test-Path $p)) { continue }
    $item = Get-Item $p
    foreach ($n in $item.Property) {
        if ($item.GetValue($n) -eq 0) {
            Write-Host ('ENABLED   ' + $n) -ForegroundColor Yellow
        } else {
            'disabled  ' + $n
        }
    }
}
Write-Host '  (a broken ENABLED layer makes xrCreateInstance fail for every OpenXR app)' -ForegroundColor DarkGray

Write-Section 'VDXR log (last OpenXR instance request it saw)'
$vd = 'C:\ProgramData\Virtual Desktop\OpenXR.log'
if (Test-Path $vd) {
    "(last written: $((Get-Item $vd).LastWriteTime))"
    Get-Content $vd -Tail 8
} else {
    'no VDXR log - VDXR has never been loaded by an app'
}

Write-Section 'Game log verdict'
if (Test-Path $GameLog) {
    "(last written: $((Get-Item $GameLog).LastWriteTime))"
    $t = Get-Content $GameLog

    $layerLine = $t | Select-String -Pattern 'Available Layers: \((\d+)\)' | Select-Object -First 1
    $layerCount = if ($layerLine) { $layerLine.Matches[0].Groups[1].Value } else { '?' }
    "  API layers loaded : $layerCount"
    $t | Select-String -Pattern '^\s*\[XR\].*(SpecVersion=)' |
        ForEach-Object { '                      ' + ($_.ToString().Trim() -replace '^.*Info\s*\]\s*', '') } |
        Select-Object -Unique

    $rt  = $t | Select-String -Pattern 'Runtime Name: '  | Select-Object -First 1
    $api = $t | Select-String -Pattern 'API Version: '   | Select-Object -First 1
    "  Runtime           : $(if ($rt)  { ($rt  -split 'Runtime Name: ')[1] } else { '(not reached)' })"
    "  OpenXR API version: $(if ($api) { ($api -split 'API Version: ')[1] } else { '(none)' })"

    $createErr = $t | Select-String -Pattern 'xrCreateInstance: XR_ERROR' | Select-Object -First 1
    $focused   = ($t | Select-String -Pattern 'XR_SESSION_STATE_VISIBLE->XR_SESSION_STATE_FOCUSED' | Measure-Object).Count
    $ready     = ($t | Select-String -Pattern 'XR_SESSION_STATE_IDLE->XR_SESSION_STATE_READY'      | Measure-Object).Count

    if ($createErr) {
        Write-Host ('  xrCreateInstance  : FAILED - ' + (($createErr -split '\]\s*')[-1])) -ForegroundColor Red
    } else {
        Write-Host '  xrCreateInstance  : ok' -ForegroundColor Green
    }
    if ($focused -gt 0) {
        Write-Host "  Session           : reached FOCUSED - running in the headset" -ForegroundColor Green
    } elseif ($ready -gt 0) {
        Write-Host '  Session           : reached READY but never FOCUSED' -ForegroundColor Yellow
    } else {
        Write-Host '  Session           : never created - game is stuck on the flat screen' -ForegroundColor Red
    }
} else {
    "game log not found: $GameLog"
}

Write-Section 'SteamVR OpenXR handshake'
$xr = Join-Path $SteamRoot "logs\$XrClient"
if (Test-Path $xr) {
    '{0} last written: {1}' -f $XrClient, (Get-Item $xr).LastWriteTime

    # A fresh timestamp proves NOTHING - this file is written as soon as the game loads
    # SteamVR's OpenXR client library, including on launches that die immediately.
    # Only a real vrserver/compositor connection means the game actually rendered.
    $xt       = Get-Content $xr
    $connects = ($xt | Select-String -Pattern 'success response from vr(server|compositor) connect' | Measure-Object).Count
    $states   = ($xt | Select-String -Pattern 'Transitioning XrSession'                             | Measure-Object).Count
    $drivers  = ($xt | Select-String -Pattern 'Load Default Json Settings from .*\\drivers\\'        | Measure-Object).Count

    "  vrserver/compositor connects : $connects"
    "  XrSession transitions        : $states"
    "  driver enumerations (old SteamVR builds): $drivers"
    if (($connects + $states + $drivers) -gt 0) {
        Write-Host '  -> this app HAS had a real SteamVR OpenXR session at some point.' -ForegroundColor Green
    } else {
        Write-Host '  -> startup banners only: the game loaded the client but NEVER rendered.' -ForegroundColor Red
    }
} else {
    "$XrClient does not exist - this app has never used SteamVR's OpenXR runtime"
}

$vrserver = Join-Path $SteamRoot 'logs\vrserver.txt'
if (Test-Path $vrserver) {
    $last = Get-Content $vrserver |
        Select-String -Pattern 'Aborting external launch because of timeout' |
        Select-Object -Last 1
    if ($last) {
        '  most recent launch timeout: ' + $last.ToString().Trim()
        '  (compare the timestamp with your last launch - an old one is harmless)'
    } else {
        Write-Host '  no launch timeouts recorded.' -ForegroundColor Green
    }
}

Write-Host ''
