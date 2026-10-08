[CmdletBinding()]
param(
    [switch]$Build
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path

$required = @(
    'create_component.ps1',
    'TEMPLATE_CONTRACT.md',
    'template\component.sln',
    'template\component.props',
    'template\validate_project.ps1',
    'tests\test_template.ps1',
    'vendor\sdk\sdk-license.txt',
    'vendor\wtl\Include\atlapp.h',
    'vendor\wtl\MS-PL.txt'
)
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
        throw "Template path is missing: $relative"
    }
}

$generatedGitignore = @(Get-Content -LiteralPath (Join-Path $root 'template\.gitignore'))
foreach ($requiredIgnore in @('Debug FB2K/', 'Release FB2K/')) {
    if ($requiredIgnore -notin $generatedGitignore) {
        throw "Generated .gitignore is missing SDK output rule: $requiredIgnore"
    }
}

$sdkReadme = Get-Content -LiteralPath (Join-Path $root 'vendor\sdk\sdk-readme.html') -Raw
$sdkVersionMatch = [regex]::Match($sdkReadme, 'foobar2000 SDK, version (\d{4}-\d{2}-\d{2})')
if (-not $sdkVersionMatch.Success) {
    throw 'SDK readme has no recognizable version.'
}
$sdkVersion = $sdkVersionMatch.Groups[1].Value
# Pin the actual vendored snapshot, not a claimed version in documentation.
$expectedSdkVersion = '2026-10-01'
if ($sdkVersion -ne $expectedSdkVersion) {
    throw "Unexpected foobar2000 SDK snapshot: $sdkVersion (expected $expectedSdkVersion)."
}
foreach ($relative in @('README.md', 'template\README.md')) {
    $readme = Get-Content -LiteralPath (Join-Path $root $relative) -Raw
    if (-not $readme.Contains("SDK $sdkVersion")) {
        throw "SDK version mismatch: $relative does not describe the actual vendored SDK $sdkVersion."
    }
}

$forbiddenArtifactExtensions = @('.aps', '.dll', '.exp', '.iobj', '.ipdb', '.lib', '.obj', '.pch', '.pdb', '.tlog')
$allowedUpstreamBinaries = @(
    'vendor\sdk\foobar2000\foo_input_validator\foo_input_validator.dll',
    'vendor\sdk\foobar2000\shared\shared-ARM64EC.lib',
    'vendor\sdk\foobar2000\shared\shared-Win32.lib',
    'vendor\sdk\foobar2000\shared\shared-x64.lib'
)
$vendorArtifacts = @(Get-ChildItem -LiteralPath (Join-Path $root 'vendor') -Recurse -File |
    Where-Object {
        $relative = [IO.Path]::GetRelativePath($root, $_.FullName)
        $forbiddenArtifactExtensions -contains $_.Extension.ToLowerInvariant() -and
        $relative -notin $allowedUpstreamBinaries
    })
if ($vendorArtifacts.Count -gt 0) {
    throw "Vendor tree contains build artifacts: $($vendorArtifacts[0].FullName)"
}

$knownTokens = @(
    '__CFG_ENABLED_GUID_CPP__',
    '__COMPONENT_ID__',
    '__DESCRIPTION__',
    '__DISPLAY_NAME__',
    '__NAMESPACE__',
    '__PREFERENCES_GUID_CPP__',
    '__PROJECT_CONFIG_MAPPINGS__',
    '__PROJECT_GUID__',
    '__SOLUTION_GUID__',
    '__VERSION_COMMAS__',
    '__VERSION__'
)
$unknownTokens = [System.Collections.Generic.HashSet[string]]::new()
Get-ChildItem -LiteralPath (Join-Path $root 'template') -Recurse -File | ForEach-Object {
    if ($_.FullName -like "$(Join-Path $root 'template\sdk')*" -or $_.FullName -like "$(Join-Path $root 'template\wtl')*") { return }
    $content = Get-Content -LiteralPath $_.FullName -Raw
    foreach ($match in [regex]::Matches($content, '__[A-Z0-9_]+__')) {
        if ($match.Value -notin $knownTokens) { [void]$unknownTokens.Add($match.Value) }
    }
}
if ($unknownTokens.Count -gt 0) {
    throw "Unknown template tokens: $($unknownTokens -join ', ')"
}

& (Join-Path $root 'tests\test_template.ps1') -Build:$Build
if (-not $?) { throw 'Template tests failed.' }

Write-Host 'Template validation passed.'
