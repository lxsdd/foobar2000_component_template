[CmdletBinding()]
param(
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$testRoot = Join-Path $root ".template-test\$PID"
$first = Join-Path $testRoot 'first'
$second = Join-Path $testRoot 'second'

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    & (Join-Path $root 'create_component.ps1') `
        -ComponentId foo_template_probe `
        -DisplayName 'Template Probe' `
        -Description 'Validates the reusable foobar2000 component baseline.' `
        -Destination $first `
        -Version 0.1.0 `
        -SkipGitInit

    & (Join-Path $root 'create_component.ps1') `
        -ComponentId foo_template_probe_two `
        -DisplayName 'Template Probe Two' `
        -Description 'Validates unique project and persistence identifiers.' `
        -Destination $second `
        -Version 0.2.0 `
        -SkipGitInit

    $firstGuidText = Get-Content -LiteralPath (Join-Path $first 'src\foo_template_probe\guid.h') -Raw
    $secondGuidText = Get-Content -LiteralPath (Join-Path $second 'src\foo_template_probe_two\guid.h') -Raw
    if ($firstGuidText -eq $secondGuidText) {
        throw 'Generated projects reused persistent GUIDs.'
    }

    $firstProject = Get-Content -LiteralPath (Join-Path $first 'src\foo_template_probe\foo_template_probe.vcxproj') -Raw
    $secondProject = Get-Content -LiteralPath (Join-Path $second 'src\foo_template_probe_two\foo_template_probe_two.vcxproj') -Raw
    $projectGuidPattern = '<ProjectGuid>([^<]+)</ProjectGuid>'
    $firstProjectGuid = [regex]::Match($firstProject, $projectGuidPattern).Groups[1].Value
    $secondProjectGuid = [regex]::Match($secondProject, $projectGuidPattern).Groups[1].Value
    if (-not $firstProjectGuid -or $firstProjectGuid -eq $secondProjectGuid) {
        throw 'Generated projects reused their Visual Studio project GUID.'
    }

    if ($Build) {
        & git -C $first init --initial-branch=main
        if ($LASTEXITCODE -ne 0) { throw 'Probe git init failed.' }
        & git -C $first add .
        if ($LASTEXITCODE -ne 0) { throw 'Probe git add failed.' }
        $statusBeforeBuild = @(& git -C $first status --porcelain=v1)

        Push-Location $first
        try {
            & .\build.bat
            if ($LASTEXITCODE -ne 0) { throw 'Probe build failed.' }
            & .\pack_component.bat
            if ($LASTEXITCODE -ne 0) { throw 'Probe packaging failed.' }
            $package = Join-Path $first 'build\foo_template_probe_0.1.0.fb2k-component'
            if (-not (Test-Path -LiteralPath $package)) { throw 'Probe package is missing.' }
            $packageEntries = @(& tar -tf $package)
            if ($LASTEXITCODE -ne 0) { throw 'Probe package could not be inspected.' }
            $normalizedEntries = @($packageEntries | ForEach-Object { $_.Replace('\', '/').TrimStart('./') })
            foreach ($requiredEntry in @('foo_template_probe.dll', 'x64/foo_template_probe.dll')) {
                if ($requiredEntry -notin $normalizedEntries) {
                    throw "Probe package is missing entry: $requiredEntry"
                }
            }
            $unexpectedDll = @($normalizedEntries | Where-Object { $_ -like '*.dll' -and $_ -notin @('foo_template_probe.dll', 'x64/foo_template_probe.dll') })
            if ($unexpectedDll.Count -gt 0) {
                throw "Probe package contains unexpected DLLs: $($unexpectedDll -join ', ')"
            }

            $statusAfterBuild = @(& git -C $first status --porcelain=v1)
            if (($statusAfterBuild -join "`n") -ne ($statusBeforeBuild -join "`n")) {
                $newStatus = @($statusAfterBuild | Where-Object { $_ -notin $statusBeforeBuild })
                throw "Build or packaging dirtied the generated worktree: $($newStatus -join ', ')"
            }
        } finally {
            Pop-Location
        }
    }

    Write-Host 'Template tests passed.'
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}
