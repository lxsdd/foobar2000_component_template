[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^foo_[a-z0-9_]+$')]
    [string]$ComponentId,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$DisplayName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Description,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$Destination,

    [ValidatePattern('^[a-z][a-z0-9_]*$')]
    [string]$Namespace,

    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version = '0.1.0',

    [switch]$SkipGitInit
)

$ErrorActionPreference = 'Stop'
$templateRoot = Join-Path $PSScriptRoot 'template'
$vendorRoot = Join-Path $PSScriptRoot 'vendor'

if (-not $Namespace) {
    $Namespace = $ComponentId.Substring(4)
}
if ($Namespace -notmatch '^[a-z][a-z0-9_]*$') {
    throw "Namespace must be a valid lowercase C++ identifier: $Namespace"
}
if ($DisplayName -match '["\r\n]' -or $Description -match '["\r\n]') {
    throw 'DisplayName and Description must be single-line strings without double quotes.'
}

$versionParts = @($Version.Split('.') | ForEach-Object { [int]$_ })
if ($versionParts.Count -ne 3 -or ($versionParts | Where-Object { $_ -gt 65535 }).Count -gt 0) {
    throw 'Version components must be between 0 and 65535.'
}
$versionCommas = "$($versionParts[0]),$($versionParts[1]),$($versionParts[2]),0"

$destinationPath = [System.IO.Path]::GetFullPath($Destination)
if (Test-Path -LiteralPath $destinationPath) {
    if (@(Get-ChildItem -LiteralPath $destinationPath -Force).Count -gt 0) {
        throw "Destination is not empty: $destinationPath"
    }
} else {
    New-Item -ItemType Directory -Path $destinationPath | Out-Null
}

foreach ($required in @(
    $templateRoot,
    (Join-Path $vendorRoot 'sdk\sdk-license.txt'),
    (Join-Path $vendorRoot 'wtl\Include\atlapp.h')
)) {
    if (-not (Test-Path -LiteralPath $required)) {
        throw "Template dependency is missing: $required"
    }
}

function ConvertTo-CppGuidInitializer([Guid]$Guid) {
    $parts = $Guid.ToString('D').Split('-')
    $tail = $parts[3] + $parts[4]
    $bytes = for ($i = 0; $i -lt 16; $i += 2) { "0x$($tail.Substring($i, 2))" }
    return "{ 0x$($parts[0]), 0x$($parts[1]), 0x$($parts[2]), { $($bytes -join ', ') } }"
}

function New-ProjectMappings([string]$ComponentProjectGuid) {
    $projects = @(
        @{ Guid = $ComponentProjectGuid; Debug32 = 'Debug|Win32'; Debug64 = 'Debug|x64'; Release32 = 'Release|Win32'; Release64 = 'Release|x64' },
        @{ Guid = '{EBFFFB4E-261D-44D3-B89C-957B31A0BF9C}'; Debug32 = 'Debug FB2K|Win32'; Debug64 = 'Debug FB2K|x64'; Release32 = 'Release FB2K|Win32'; Release64 = 'Release FB2K|x64' },
        @{ Guid = '{E8091321-D79D-4575-86EF-064EA1A4A20D}'; Debug32 = 'Debug|Win32'; Debug64 = 'Debug|x64'; Release32 = 'Release|Win32'; Release64 = 'Release|x64' },
        @{ Guid = '{EE47764E-A202-4F85-A767-ABDAB4AFF35F}'; Debug32 = 'Debug|Win32'; Debug64 = 'Debug|x64'; Release32 = 'Release|Win32'; Release64 = 'Release|x64' },
        @{ Guid = '{71AD2674-065B-48F5-B8B0-E1F9D3892081}'; Debug32 = 'Debug|Win32'; Debug64 = 'Debug|x64'; Release32 = 'Release|Win32'; Release64 = 'Release|x64' }
    )
    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($project in $projects) {
        foreach ($entry in @(
            @{ Solution = 'Debug|Win32'; Project = $project.Debug32 },
            @{ Solution = 'Debug|x64'; Project = $project.Debug64 },
            @{ Solution = 'Release|Win32'; Project = $project.Release32 },
            @{ Solution = 'Release|x64'; Project = $project.Release64 }
        )) {
            $lines.Add("        $($project.Guid).$($entry.Solution).ActiveCfg = $($entry.Project)")
            $lines.Add("        $($project.Guid).$($entry.Solution).Build.0 = $($entry.Project)")
        }
        $lines.Add('')
    }
    return ($lines -join "`r`n").TrimEnd()
}

$projectGuid = [Guid]::NewGuid()
$solutionGuid = [Guid]::NewGuid()
$preferencesGuid = [Guid]::NewGuid()
$cfgEnabledGuid = [Guid]::NewGuid()

Write-Host "Creating $DisplayName in $destinationPath"
Copy-Item -Path (Join-Path $templateRoot '*') -Destination $destinationPath -Recurse -Force

$placeholderSourceDir = Join-Path $destinationPath 'src\__COMPONENT_ID__'
$componentSourceDir = Join-Path $destinationPath "src\$ComponentId"
Move-Item -LiteralPath $placeholderSourceDir -Destination $componentSourceDir
Move-Item -LiteralPath (Join-Path $componentSourceDir '__COMPONENT_ID__.vcxproj') -Destination (Join-Path $componentSourceDir "$ComponentId.vcxproj")

$replacements = [ordered]@{
    '__COMPONENT_ID__' = $ComponentId
    '__DISPLAY_NAME__' = $DisplayName
    '__DESCRIPTION__' = $Description
    '__NAMESPACE__' = $Namespace
    '__VERSION__' = $Version
    '__VERSION_COMMAS__' = $versionCommas
    '__PROJECT_GUID__' = '{' + $projectGuid.ToString('D').ToUpperInvariant() + '}'
    '__SOLUTION_GUID__' = '{' + $solutionGuid.ToString('D').ToUpperInvariant() + '}'
    '__PREFERENCES_GUID_CPP__' = ConvertTo-CppGuidInitializer $preferencesGuid
    '__CFG_ENABLED_GUID_CPP__' = ConvertTo-CppGuidInitializer $cfgEnabledGuid
    '__PROJECT_CONFIG_MAPPINGS__' = New-ProjectMappings ('{' + $projectGuid.ToString('D').ToUpperInvariant() + '}')
}

$textExtensions = @('.bat', '.cpp', '.h', '.md', '.props', '.ps1', '.rc', '.sln', '.txt', '.vcxproj')
$textFiles = Get-ChildItem -LiteralPath $destinationPath -Recurse -File |
    Where-Object { $textExtensions -contains $_.Extension -or $_.Name -eq '.gitignore' }
foreach ($file in $textFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    foreach ($entry in $replacements.GetEnumerator()) {
        $content = $content.Replace($entry.Key, $entry.Value)
    }
    Set-Content -LiteralPath $file.FullName -Value $content -Encoding utf8NoBOM
}

Copy-Item -LiteralPath (Join-Path $vendorRoot 'sdk') -Destination (Join-Path $destinationPath 'sdk') -Recurse
Copy-Item -LiteralPath (Join-Path $vendorRoot 'wtl') -Destination (Join-Path $destinationPath 'wtl') -Recurse

& (Join-Path $destinationPath 'validate_project.ps1')
if (-not $?) { throw 'Generated project validation failed.' }

if (-not $SkipGitInit) {
    & git -C $destinationPath init --initial-branch=main
    if ($LASTEXITCODE -ne 0) { throw 'git init failed.' }
}

Write-Host ''
Write-Host 'Project created successfully.'
Write-Host "Next: Set-Location '$destinationPath'"
Write-Host '      .\build.bat'
Write-Host '      .\pack_component.bat'
