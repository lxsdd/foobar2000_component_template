[CmdletBinding()]
param(
    [ValidatePattern('^\d{4}-\d{2}-\d{2}$')]
    [string]$Version = '2026-10-01',
    [switch]$NoCommit
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = Split-Path -Parent $PSScriptRoot
$uri = "https://www.foobar2000.org/downloads/SDK-$Version.7z"
$temp = Join-Path ([IO.Path]::GetTempPath()) ("foobar-sdk-stage-" + [guid]::NewGuid().ToString('N'))
$archive = Join-Path $temp 'sdk.7z'
$expanded = Join-Path $temp 'expanded'
$vendor = Join-Path $root 'vendor/sdk'
try {
    New-Item -ItemType Directory -Path $expanded -Force | Out-Null
    Write-Host "Downloading official foobar2000 SDK $Version"
    Invoke-WebRequest -Uri $uri -OutFile $archive -MaximumRetryCount 3 -RetryIntervalSec 2
    if ((Get-Item $archive).Length -lt 100000) {
        throw "Downloaded SDK archive is implausibly small."
    }
    $archiveSha256 = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    # Frozen from the successful official-archive provenance run (2026-10-08).
    $expectedSha256 = 'd4c55077336fae81bf8df0259b5b2748fa45ea84132c656ead93eb123cbcdc26'
    if ($archiveSha256 -ne $expectedSha256) {
        throw "Official SDK archive SHA-256 mismatch: $archiveSha256 (expected $expectedSha256)"
    }
    $sevenZipCommand = Get-Command 7z.exe -ErrorAction SilentlyContinue
    $sevenZip = if ($sevenZipCommand) { $sevenZipCommand.Source } else { 'C:\Program Files\7-Zip\7z.exe' }
    if (-not (Test-Path -LiteralPath $sevenZip)) { throw "7-Zip not installed: $sevenZip" }
    & $sevenZip x "-o$expanded" -y $archive | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'SDK extraction failed.' }

    $candidates = @(Get-ChildItem -LiteralPath $expanded -Filter sdk-readme.html -Recurse -File |
        Where-Object {
            $parent = $_.Directory.FullName
            (Test-Path (Join-Path $parent 'sdk-license.txt')) -and
            (Test-Path (Join-Path $parent 'foobar2000')) -and
            (Test-Path (Join-Path $parent 'pfc')) -and
            (Test-Path (Join-Path $parent 'libPPUI'))
        })
    if ($candidates.Count -ne 1) { throw "Expected one official SDK root, found $($candidates.Count)." }
    $sdkRoot = $candidates[0].Directory.FullName
    $readme = Get-Content -LiteralPath $candidates[0].FullName -Raw
    if ($readme -notmatch [regex]::Escape($Version)) {
        throw "SDK readme does not identify requested release $Version."
    }
    $license = Get-Content -LiteralPath (Join-Path $sdkRoot 'sdk-license.txt') -Raw
    if ($license -notmatch 'Redistribution and use') { throw 'SDK license validation failed.' }
    if (-not (Test-Path (Join-Path $sdkRoot 'foobar2000/SDK'))) { throw 'Missing SDK project tree.' }

    # Only after source validation may we replace the checked-in historical snapshot.
    & git -C $root rm -r --quiet --ignore-unmatch -- vendor/sdk
    if ($LASTEXITCODE -ne 0) { throw 'Removing the old SDK snapshot failed.' }
    New-Item -ItemType Directory -Path $vendor -Force | Out-Null
    Get-ChildItem -LiteralPath $sdkRoot -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $vendor -Recurse -Force
    }
    $pin = [ordered]@{
        sdk_version = $Version
        upstream_url = $uri
        upstream_archive_sha256 = $archiveSha256
        archive_size_bytes = (Get-Item $archive).Length
        captured_utc = [DateTime]::UtcNow.ToString('o')
    }
    $pin | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $root 'SDK-PIN.json') -Encoding utf8NoBOM
    & git -C $root add -A -- vendor/sdk SDK-PIN.json
    if ($LASTEXITCODE -ne 0) { throw 'Staging SDK snapshot failed.' }
    $staged = @(& git -C $root diff --cached --name-only)
    if ($staged.Count -lt 3) { throw 'SDK refresh unexpectedly staged too few paths.' }

    Write-Host "SDK=$Version; upstream SHA256=$archiveSha256; staged paths=$($staged.Count)"
    if (-not $NoCommit) {
        if ($env:GITHUB_REF_NAME -ne 'sdk/2026-10-01') {
            throw 'Automatic SDK snapshot push is restricted to sdk/2026-10-01.'
        }
        & git -C $root config user.name 'github-actions[bot]'
        & git -C $root config user.email '41898282+github-actions[bot]@users.noreply.github.com'
        & git -C $root commit -m "vendor: stage official foobar2000 SDK $Version (unqualified)"
        if ($LASTEXITCODE -ne 0) { throw 'SDK staging commit failed.' }
        & git -C $root push origin 'HEAD:refs/heads/sdk/2026-10-01'
        if ($LASTEXITCODE -ne 0) { throw 'SDK staging push failed.' }
    }
} finally {
    if (Test-Path -LiteralPath $temp) { Remove-Item -LiteralPath $temp -Recurse -Force }
}
