[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$errors = [System.Collections.Generic.List[string]]::new()

$required = @(
    'component.sln',
    'component.props',
    'build.bat',
    'pack_component.bat',
    'sdk\sdk-license.txt',
    'wtl\Include\atlapp.h'
)
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
        $errors.Add("Missing required path: $relative")
    }
}

$componentDirs = @(Get-ChildItem -LiteralPath (Join-Path $root 'src') -Directory -ErrorAction SilentlyContinue)
if ($componentDirs.Count -ne 1) {
    $errors.Add("Expected exactly one component source directory, found $($componentDirs.Count).")
} else {
    $componentId = $componentDirs[0].Name
    if ($componentId -notmatch '^foo_[a-z0-9_]+$') {
        $errors.Add("Invalid component ID: $componentId")
    }
    foreach ($relative in @(
        "src\$componentId\$componentId.vcxproj",
        "src\$componentId\component.cpp",
        "src\$componentId\preferences.cpp",
        "src\$componentId\component.rc"
    )) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) {
            $errors.Add("Missing component file: $relative")
        }
    }
}

$textExtensions = @('.bat', '.cpp', '.h', '.md', '.props', '.ps1', '.rc', '.sln', '.txt', '.vcxproj')
$projectTextFiles = Get-ChildItem -LiteralPath $root -Recurse -File |
    Where-Object {
        $_.FullName -notlike "$(Join-Path $root 'sdk')*" -and
        $_.FullName -notlike "$(Join-Path $root 'wtl')*" -and
        ($textExtensions -contains $_.Extension -or $_.Name -eq '.gitignore')
    }
$forbiddenCoupling = 'foo_' + 'smart' + '_tempo|smart' + '_tempo'
foreach ($file in $projectTextFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw
    if ($content -match '__[A-Z0-9_]+__') {
        $errors.Add("Unresolved template token: $($file.FullName)")
    }
    if ($content -match $forbiddenCoupling) {
        $errors.Add("Smart Tempo coupling found: $($file.FullName)")
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { Write-Error $_ -ErrorAction Continue }
    exit 1
}

Write-Host "Project validation passed: $componentId"
