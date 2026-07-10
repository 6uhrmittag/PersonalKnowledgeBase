<#
.SYNOPSIS
    Post-session batch step (CLAUDE.md §8.3): remux MKV->MP4, verify integrity,
    optional proxies, session manifest.

.DESCRIPTION
    Windows PowerShell 5.1 compatible. Requires ffmpeg + ffprobe on PATH.
    Non-destructive: originals are never deleted, existing up-to-date targets are skipped.

.PARAMETER SessionDir
    Session folder to process. Default: the newest folder under -SessionsRoot.

.PARAMETER SessionsRoot
    Where sessions/{date} folders live. Default: %USERPROFILE%\Videos\FragPunk\sessions

.PARAMETER Proxies
    Also generate 1080p H.264 NVENC proxies into <session>\proxies\.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\postprocess.ps1
    powershell -ExecutionPolicy Bypass -File .\postprocess.ps1 -SessionDir "$env:USERPROFILE\Videos\FragPunk\sessions\2026-07-12" -Proxies
#>
[CmdletBinding()]
param(
    [string]$SessionDir,
    [string]$SessionsRoot = (Join-Path $env:USERPROFILE 'Videos\FragPunk\sessions'),
    [switch]$Proxies
)

$ErrorActionPreference = 'Stop'

foreach ($tool in 'ffmpeg', 'ffprobe') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Error "$tool not on PATH. Install: winget install Gyan.FFmpeg (then reopen the shell)."
    }
}

if (-not $SessionDir) {
    $latest = Get-ChildItem $SessionsRoot -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending | Select-Object -First 1
    if (-not $latest) { Write-Error "No session folders under $SessionsRoot. Pass -SessionDir explicitly." }
    $SessionDir = $latest.FullName
}
if (-not (Test-Path $SessionDir)) { Write-Error "Session folder not found: $SessionDir" }

Write-Host "Processing session: $SessionDir`n"
$mkvFiles = @(Get-ChildItem $SessionDir -Filter '*.mkv' -File)
if ($mkvFiles.Count -eq 0) { Write-Warning 'No .mkv files in this session folder.' }

# --- 1. Remux MKV -> MP4 (stream copy, all tracks) -----------------------------
$remuxed = @()
foreach ($mkv in $mkvFiles) {
    $mp4 = [System.IO.Path]::ChangeExtension($mkv.FullName, '.mp4')
    if ((Test-Path $mp4) -and ((Get-Item $mp4).LastWriteTime -ge $mkv.LastWriteTime)) {
        Write-Host "remux  SKIP  $($mkv.Name) (mp4 up to date)"
        $remuxed += $mp4
        continue
    }
    & ffmpeg -hide_banner -loglevel error -y -i $mkv.FullName -map 0 -c copy $mp4
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "remux FAILED for $($mkv.Name)"
        if (Test-Path $mp4) { Remove-Item $mp4 -Force }  # don't leave a broken half-file
        continue
    }
    Write-Host "remux  OK    $($mkv.Name) -> $([System.IO.Path]::GetFileName($mp4))"
    $remuxed += $mp4
}

# --- 2. Integrity check ---------------------------------------------------------
$broken = @()
foreach ($file in $remuxed) {
    $errors = & ffmpeg -hide_banner -v error -i $file -f null NUL 2>&1
    if ($LASTEXITCODE -ne 0 -or $errors) {
        $broken += $file
        $snippet = (@($errors) | Select-Object -First 3) -join ' | '
        Write-Warning ("verify FAIL  {0}: {1}" -f [System.IO.Path]::GetFileName($file), $snippet)
    } else {
        Write-Host "verify OK    $([System.IO.Path]::GetFileName($file))"
    }
}

# --- 3. Optional proxies ---------------------------------------------------------
if ($Proxies) {
    $proxyDir = Join-Path $SessionDir 'proxies'
    if (-not (Test-Path $proxyDir)) { New-Item -ItemType Directory -Path $proxyDir | Out-Null }
    foreach ($file in $remuxed) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($file)
        $proxy = Join-Path $proxyDir "$name`_proxy.mp4"
        if (Test-Path $proxy) { Write-Host "proxy  SKIP  $name"; continue }
        & ffmpeg -hide_banner -loglevel error -i $file -vf 'scale=-2:1080' -c:v h264_nvenc -preset p4 -cq 28 -c:a copy $proxy
        if ($LASTEXITCODE -eq 0) { Write-Host "proxy  OK    $name" } else { Write-Warning "proxy FAILED $name" }
    }
}

# --- 4. Manifest ------------------------------------------------------------------
$manifest = @()
foreach ($file in $remuxed) {
    $probeJson = & ffprobe -v error -print_format json -show_format -show_streams $file | ConvertFrom-Json
    $video = $probeJson.streams | Where-Object { $_.codec_type -eq 'video' } | Select-Object -First 1
    $fps = 0
    if ($video.avg_frame_rate -match '^(\d+)/(\d+)$') { $fps = [math]::Round([int]$Matches[1] / [int]$Matches[2], 0) }
    $manifest += [pscustomobject]@{
        File       = [System.IO.Path]::GetFileName($file)
        DurationS  = [math]::Round([double]$probeJson.format.duration, 1)
        Resolution = "$($video.width)x$($video.height)"
        Fps        = $fps
        Codec      = $video.codec_name
        AudioTracks = @($probeJson.streams | Where-Object { $_.codec_type -eq 'audio' }).Count
        SizeMB     = [math]::Round((Get-Item $file).Length / 1MB, 0)
        Verified   = -not ($broken -contains $file)
    }
}

Write-Host "`nSession manifest:"
$manifest | Format-Table -AutoSize
$manifest | ConvertTo-Json | Set-Content (Join-Path $SessionDir 'manifest.json') -Encoding UTF8

Write-Host ("Done: {0} remuxed, {1} broken, manifest.json written." -f $remuxed.Count, $broken.Count)
Write-Host 'MKV originals kept — delete manually once the MP4s are verified in Resolve.'
if ($broken.Count -gt 0) { exit 1 }
