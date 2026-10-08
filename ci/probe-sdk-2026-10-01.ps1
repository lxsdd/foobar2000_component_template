[CmdletBinding()]
param(
    [ValidatePattern('^[0-9a-fA-F]{64}$')]
    [string]$ExpectedSHA256 = '',
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = Split-Path -Parent $PSScriptRoot
$evidenceRoot = Join-Path $repositoryRoot 'sdk-probe-evidence'
New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
$reportPath = Join-Path $evidenceRoot 'report.txt'
$archiveUrl = 'https://www.foobar2000.org/downloads/SDK-2026-10-01.7z'
$archive = Join-Path $env:RUNNER_TEMP 'foobar2000-SDK-2026-10-01.7z'
$extractRoot = Join-Path $env:RUNNER_TEMP 'foobar2000-SDK-2026-10-01-extract'

if ([string]::IsNullOrWhiteSpace($env:RUNNER_TEMP)) {
    throw 'RUNNER_TEMP is required: run only in an ephemeral GitHub Windows runner.'
}
if ($Build -and -not $ExpectedSHA256) {
    throw 'Build blocked: official archive SHA-256 must be reviewed and pinned first.'
}

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('SDK_PROBE_VERSION=2026-10-01')
$lines.Add("SDK_SOURCE=$archiveUrl")
$lines.Add("EXPECTED_SHA256=$ExpectedSHA256")
$lines.Add('SDK_PROBE_STATUS=NOT_QUALIFIED')
try {
    Invoke-WebRequest -Uri $archiveUrl -OutFile $archive -MaximumRedirection 5
    $archiveSize = (Get-Item -LiteralPath $archive).Length
    if ($archiveSize -lt 65536) { throw "Unexpectedly small SDK archive ($archiveSize bytes)." }
    $hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
    $lines.Add("SOURCE_ARCHIVE_SIZE=$archiveSize")
    $lines.Add("SOURCE_ARCHIVE_SHA256=$hash")

    $zipCommand = Get-Command 7z.exe -ErrorAction SilentlyContinue
    $sevenZip = if ($zipCommand) { $zipCommand.Source } else { 'C:\Program Files\7-Zip\7z.exe' }
    if (-not (Test-Path -LiteralPath $sevenZip)) { throw "7-Zip not found: $sevenZip" }
    & $sevenZip t $archive | Out-Null
    if ($LASTEXITCODE -ne 0) { throw '7z archive integrity test failed.' }
    if (Test-Path -LiteralPath $extractRoot) { Remove-Item -LiteralPath $extractRoot -Recurse -Force }
    New-Item -ItemType Directory -Path $extractRoot -Force | Out-Null
    & $sevenZip x -y "-o$extractRoot" $archive | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Official SDK extraction failed.' }

    $readmes = @(Get-ChildItem -LiteralPath $extractRoot -File -Recurse -Filter 'sdk-readme.html' |
        Where-Object { (Get-Content -LiteralPath $_.FullName -Raw) -match 'foobar2000 SDK, version 2026-10-01' })
    if ($readmes.Count -ne 1) { throw "Expected exactly one SDK 2026-10-01 root; found $($readmes.Count)." }
    $sdkRoot = $readmes[0].Directory.FullName
    foreach ($relative in @('sdk-license.txt','foobar2000','pfc','libPPUI')) {
        if (-not (Test-Path -LiteralPath (Join-Path $sdkRoot $relative))) {
            throw "Upstream SDK is missing expected content: $relative"
        }
    }
    $lines.Add('SDK_README_VERSION=2026-10-01')
    $lines.Add('SOURCE_INTEGRITY=PASS')
    $lines.Add('SOURCE_LAYOUT=PASS')

    if (-not $ExpectedSHA256) {
        $lines.Add('SDK_PROBE_STATUS=SOURCE_DISCOVERY_ONLY')
        $lines.Add('BUILD_STATUS=NOT_RUN_UNPINNED_ARCHIVE')
        Write-Host "Discovered upstream SDK 2026-10-01; SHA256=$hash"
        Write-Host 'Review this SHA-256 against the independently obtained official archive before enabling -Build.'
    } else {
        if ($hash -ne $ExpectedSHA256.ToLowerInvariant()) {
            throw "Archive SHA-256 mismatch: expected $ExpectedSHA256, received $hash."
        }
        $lines.Add('SOURCE_SHA256_PIN=PASS')
        if ($Build) {
            $workspace = Join-Path $env:RUNNER_TEMP 'foobar2000-sdk-upgrade-probe'
            if (Test-Path -LiteralPath $workspace) { Remove-Item -LiteralPath $workspace -Recurse -Force }
            New-Item -ItemType Directory -Path $workspace -Force | Out-Null
            Copy-Item -Path (Join-Path $repositoryRoot '*') -Destination $workspace -Recurse -Force

            $vendoredSdk = Join-Path $workspace 'vendor\sdk'
            Remove-Item -LiteralPath $vendoredSdk -Force -Recurse
            Copy-Item -LiteralPath $sdkRoot -Destination $vendoredSdk -Recurse -Force

            $docs = @('README.md','template\README.md')
            foreach ($relative in $docs) {
                $path = Join-Path $workspace $relative
                $original = Get-Content -LiteralPath $path -Raw
                if (-not $original.Contains('SDK 2025-03-07')) {
                    throw "Baseline SDK reference missing in $relative; inspect the migration."
                }
                Set-Content -LiteralPath $path -Value $original.Replace('SDK 2025-03-07','SDK 2026-10-01') -NoNewline -Encoding utf8
            }
            $validator = Join-Path $workspace 'validate_template.ps1'
            $originalValidator = Get-Content -LiteralPath $validator -Raw
            $oldPin = "$" + "expectedSdkVersion = '2025-03-07'"
            $newPin = "$" + "expectedSdkVersion = '2026-10-01'"
            if (-not $originalValidator.Contains($oldPin)) { throw 'Baseline validator pin not found.' }
            Set-Content -LiteralPath $validator -Value $originalValidator.Replace($oldPin,$newPin) -NoNewline -Encoding utf8

            Push-Location $workspace
            try {
                & .\validate_template.ps1 -Build
                if (-not $?) { throw 'SDK 2026-10-01 template build smoke test failed.' }
            } finally {
                Pop-Location
            }
            $lines.Add('SDK_PROBE_STATUS=DUAL_ARCH_BUILD_PASS')
            $lines.Add('BUILD_STATUS=PASS')
        } else {
            $lines.Add('SDK_PROBE_STATUS=SOURCE_PIN_VERIFIED')
            $lines.Add('BUILD_STATUS=NOT_REQUESTED')
        }
    }
} catch {
    $lines.Add('SDK_PROBE_STATUS=FAIL')
    $lines.Add("ERROR=$($_.Exception.Message.Replace([Environment]::NewLine,' '))")
    throw
} finally {
    $lines | Set-Content -LiteralPath $reportPath -Encoding utf8
}
