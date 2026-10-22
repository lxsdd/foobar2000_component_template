[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$verifier = Join-Path $root 'ci/verify-fb2k-component.ps1'
$work = Join-Path ([IO.Path]::GetTempPath()) ('fb2k-verifier-contract-' + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $work | Out-Null

function New-SyntheticPe([string]$Target, [int]$Machine) {
    # Synthetic PE signature sufficient for structural verifier, not executable.
    $bytes = New-Object byte[] 128
    $bytes[0] = 0x4D
    $bytes[1] = 0x5A
    [BitConverter]::GetBytes([int]0x40).CopyTo($bytes, 0x3C)
    $bytes[0x40] = 0x50
    $bytes[0x41] = 0x45
    [BitConverter]::GetBytes([uint16]$Machine).CopyTo($bytes, 0x44)
    [IO.File]::WriteAllBytes($Target, $bytes)
}

function New-Case([string]$Name, [int]$RootMachine = 0x014c,
                   [int]$X64Machine = 0x8664, [switch]$NoX64,
                   [switch]$X86Folder, [switch]$ExtraDll, [switch]$BrokenZip) {
    $stage = Join-Path $work ('stage-' + $Name)
    New-Item -ItemType Directory -Path $stage | Out-Null
    New-SyntheticPe (Join-Path $stage 'foo_contract_probe.dll') $RootMachine
    if (-not $NoX64) {
        $x64 = New-Item -ItemType Directory -Path (Join-Path $stage 'x64')
        New-SyntheticPe (Join-Path $x64.FullName 'foo_contract_probe.dll') $X64Machine
    }
    if ($X86Folder) {
        New-Item -ItemType Directory -Path (Join-Path $stage 'x86') | Out-Null
    }
    if ($ExtraDll) {
        New-SyntheticPe (Join-Path $stage 'foo_unexpected.dll') $RootMachine
    }
    $output = Join-Path $work ($Name + '.fb2k-component')
    if ($BrokenZip) {
        [IO.File]::WriteAllBytes($output, [byte[]]@(0x00, 0x01, 0x02))
    } else {
        [IO.Compression.ZipFile]::CreateFromDirectory($stage, $output)
    }
    return $output
}

function Assert-Reject([string]$Case, [string]$Path, [string]$DllName = '') {
    try {
        if ($DllName) {
            $proof = & $verifier -ComponentPath $Path -DllName $DllName
        } else {
            $proof = & $verifier -ComponentPath $Path
        }
    } catch {
        Write-Host ("PASS rejected " + $Case + ": " + $_.Exception.Message)
        return
    }
    throw ("Safety FAIL: verifier accepted " + $Case + " with status " + $proof.Status)
}

try {
    $good = New-Case 'valid'
    $valid = & $verifier -ComponentPath $good -DllName 'foo_contract_probe.dll'
    if ($null -eq $valid -or $valid.Status -ne 'PASS' -or
        $valid.RootMachine -ne '0x014C' -or $valid.X64Machine -ne '0x8664' -or
        $valid.Sha256 -notmatch '^[a-f0-9]{64}$') {
        throw 'Valid structural foobar component was not qualified.'
    }
    $autodetect = & $verifier -ComponentPath $good
    if ($autodetect.DllName -ne 'foo_contract_probe.dll') {
        throw 'Root component DLL autodetection failed.'
    }
    Assert-Reject 'root x64 mislabeled as x86' (New-Case 'swapped-root' -RootMachine 0x8664)
    Assert-Reject 'x64 wrong PE machine' (New-Case 'bad-x64' -X64Machine 0x014c)
    Assert-Reject 'missing x64 payload' (New-Case 'missing-x64' -NoX64)
    Assert-Reject 'forbidden x86 folder' (New-Case 'x86-layout' -X86Folder)
    Assert-Reject 'ambiguous root DLL autodetect' (New-Case 'extra-dll' -ExtraDll)
    Assert-Reject 'corrupt ZIP input' (New-Case 'corrupt-zip' -BrokenZip)
    Assert-Reject 'wrong exact DLL name' $good 'foo_incorrect.dll'
    Write-Host 'COMPONENT_VERIFIER_NEGATIVE_FIXTURES=PASS cases=9'
} finally {
    if (Test-Path -LiteralPath $work) {
        Remove-Item -LiteralPath $work -Recurse -Force
    }
}
