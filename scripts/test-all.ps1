$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

dub build --config=application --build=release --force | Out-Null
$exe = Join-Path $PWD 'bluetooth-scanner.exe'
if (-not (Test-Path $exe)) { throw "missing $exe after build" }

$fail = 0
$pass = 0

function Invoke-Scanner {
    param([string[]]$ScannerArgs)
    $p = Start-Process -FilePath $exe -ArgumentList $ScannerArgs -WorkingDirectory $PWD -Wait -PassThru -NoNewWindow
    return $p.ExitCode
}

function Assert-Exit($name, $expected, $actual) {
    if ($actual -eq $expected) {
        Write-Host "[PASS] $name (exit $actual)"
        $script:pass++
    } else {
        Write-Host "[FAIL] $name (expected exit $expected, got $actual)"
        $script:fail++
    }
}

function Assert-File($name, $path) {
    if (Test-Path $path) {
        $n = (Get-Item $path).Length
        if ($n -gt 10) {
            Write-Host "[PASS] $name ($n bytes)"
            $script:pass++
        } else {
            Write-Host "[FAIL] $name (file too small)"
            $script:fail++
        }
    } else {
        Write-Host "[FAIL] $name (missing $path)"
        $script:fail++
    }
}

function Assert-JsonOk($name, $path) {
    $raw = Get-Content -Raw $path
    $j = $raw | ConvertFrom-Json
    if ($j.ok -eq $true -and $null -ne $j.devices) {
        Write-Host "[PASS] $name (count=$($j.count))"
        $script:pass++
    } else {
        Write-Host "[FAIL] $name (bad json shape or ok=false)"
        $script:fail++
    }
}

Write-Host '=== struct layout ==='
dub run --config=struct-test --build=release --quiet
if ($LASTEXITCODE -ne 0) { throw 'struct-test failed' }

Write-Host '=== CLI help ==='
Assert-Exit 'help exits 0' 0 (Invoke-Scanner @('--help'))

Write-Host '=== invalid args ==='
Assert-Exit 'bad flag exits 1' 1 (Invoke-Scanner @('--not-a-flag'))

Write-Host '=== scan modes ==='
Assert-Exit '--once --fast' 0 (Invoke-Scanner @('--once', '--fast'))
Assert-Exit '--once --timeout 2' 0 (Invoke-Scanner @('--once', '--timeout', '2'))

$codeNoInq = Invoke-Scanner @('--once', '--no-inquiry')
if ($codeNoInq -eq 0 -or $codeNoInq -eq 1) {
    Write-Host "[PASS] --once --no-inquiry (exit $codeNoInq)"
    $pass++
} else {
    Write-Host "[FAIL] --once --no-inquiry (exit $codeNoInq)"
    $fail++
}

$codePaired = Invoke-Scanner @('--once', '--paired-only')
if ($codePaired -eq 0 -or $codePaired -eq 1) {
    Write-Host "[PASS] --once --paired-only (exit $codePaired)"
    $pass++
} else {
    Write-Host "[FAIL] --once --paired-only (exit $codePaired)"
    $fail++
}

Write-Host '=== JSON output ==='
$jsonOut = Join-Path $PWD 'test-out.json'
if (Test-Path $jsonOut) { Remove-Item $jsonOut }
Assert-Exit '--json file' 0 (Invoke-Scanner @('--once', '--fast', '--json', $jsonOut))
Assert-File 'json file created' $jsonOut
Assert-JsonOk 'json content' $jsonOut

Write-Host '=== JSON stdout ==='
$prevEa = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$stdoutJson = (& $exe --once --fast --json 2>&1 | Out-String).Trim()
$ErrorActionPreference = $prevEa
try {
    $j = $stdoutJson | ConvertFrom-Json
    if ($j.ok) {
        Write-Host "[PASS] json stdout (count=$($j.count))"
        $pass++
    } else {
        Write-Host "[FAIL] json stdout ok=false"
        $fail++
    }
} catch {
    Write-Host "[FAIL] json stdout parse: $_"
    $fail++
}

Write-Host '=== services (slow) ==='
$svcJson = Join-Path $PWD 'test-services.json'
if (Test-Path $svcJson) { Remove-Item $svcJson }
$codeSvc = Invoke-Scanner @('--once', '--fast', '--services', '--json', $svcJson)
if ($codeSvc -eq 0 -or $codeSvc -eq 1) {
    Assert-File 'services json' $svcJson
    $sj = Get-Content -Raw $svcJson | ConvertFrom-Json
    if ($sj.devices.Count -gt 0) {
        Write-Host '[PASS] services scan returned devices'
        $pass++
    }
} else {
    Write-Host "[FAIL] --services scan (exit $codeSvc)"
    $fail++
}

Write-Host ''
Write-Host "=== summary: $pass passed, $fail failed ==="
if ($fail -gt 0) { exit 1 }
exit 0
