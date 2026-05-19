$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')

dub build --config=application --build=release --force | Out-Null
$exe = Join-Path $PWD 'bluetooth-scanner.exe'
if (-not (Test-Path $exe)) { throw "missing $exe after build" }

$fail = 0
$pass = 0
$skip = 0
$LiveBluetooth = $false

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

function Assert-JsonScan($name, $path, $exitCode) {
    Assert-File "$name file" $path
    $j = Get-Content -Raw $path | ConvertFrom-Json
    if ($script:LiveBluetooth) {
        if ($exitCode -in 0, 1 -and $j.ok -eq $true -and $null -ne $j.devices) {
            Write-Host "[PASS] $name (live radio, count=$($j.count))"
            $script:pass++
        } else {
            Write-Host "[FAIL] $name (expected ok=true with devices on live radio)"
            $script:fail++
        }
    } else {
        if ($exitCode -eq 2 -and $j.ok -eq $false -and $j.error) {
            Write-Host "[PASS] $name (no radio, error json: $($j.error))"
            $script:pass++
        } else {
            Write-Host "[FAIL] $name (expected exit 2 and ok=false without radio)"
            $script:fail++
        }
    }
}

function Assert-ScanExit($name, $code) {
    if ($script:LiveBluetooth) {
        if ($code -eq 0 -or $code -eq 1) {
            Write-Host "[PASS] $name (exit $code)"
            $script:pass++
        } else {
            Write-Host "[FAIL] $name (expected 0 or 1, got $code)"
            $script:fail++
        }
    } else {
        if ($code -eq 2) {
            Write-Host "[PASS] $name (no radio, exit 2 as expected)"
            $script:pass++
        } else {
            Write-Host "[FAIL] $name (expected 2 without radio, got $code)"
            $script:fail++
        }
    }
}

function Test-BluetoothRadioAvailable {
    $probePath = Join-Path $env:TEMP 'bt-scanner-probe.json'
    if (Test-Path $probePath) { Remove-Item $probePath -Force }
    $code = Invoke-Scanner @('--once', '--no-inquiry', '--json', $probePath)
    if (-not (Test-Path $probePath)) {
        Write-Host '[probe] no json written'
        return $false
    }
    $j = Get-Content -Raw $probePath | ConvertFrom-Json
    if ($j.ok -eq $true) {
        Write-Host "[probe] live Bluetooth radio detected (exit $code, count=$($j.count))"
        return $true
    }
    Write-Host "[probe] no usable radio (exit $code, error=$($j.error))"
    return $false
}

Write-Host '=== struct layout ==='
dub run --config=struct-test --build=release --quiet
if ($LASTEXITCODE -ne 0) { throw 'struct-test failed' }

Write-Host '=== Bluetooth probe ==='
$LiveBluetooth = Test-BluetoothRadioAvailable
if (-not $LiveBluetooth -and $env:GITHUB_ACTIONS -eq 'true') {
    Write-Host '[info] GitHub Actions runners have no Bluetooth radio; live scan tests use error-path expectations.'
}

Write-Host '=== CLI help ==='
Assert-Exit 'help exits 0' 0 (Invoke-Scanner @('--help'))

Write-Host '=== invalid args ==='
Assert-Exit 'bad flag exits 1' 1 (Invoke-Scanner @('--not-a-flag'))

Write-Host '=== scan modes ==='
Assert-ScanExit '--once --fast' (Invoke-Scanner @('--once', '--fast'))
Assert-ScanExit '--once --timeout 2' (Invoke-Scanner @('--once', '--timeout', '2'))
Assert-ScanExit '--once --no-inquiry' (Invoke-Scanner @('--once', '--no-inquiry'))
Assert-ScanExit '--once --paired-only' (Invoke-Scanner @('--once', '--paired-only'))

Write-Host '=== JSON output ==='
$jsonOut = Join-Path $PWD 'test-out.json'
if (Test-Path $jsonOut) { Remove-Item $jsonOut }
$jsonCode = Invoke-Scanner @('--once', '--fast', '--json', $jsonOut)
Assert-JsonScan 'json file' $jsonOut $jsonCode

Write-Host '=== JSON stdout ==='
$prevEa = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$stdoutJson = (& $exe --once --fast --json 2>&1 | Out-String).Trim()
$ErrorActionPreference = $prevEa
try {
    $j = $stdoutJson | ConvertFrom-Json
    if ($LiveBluetooth -and $j.ok -eq $true) {
        Write-Host "[PASS] json stdout (count=$($j.count))"
        $pass++
    } elseif (-not $LiveBluetooth -and $j.ok -eq $false -and $j.error) {
        Write-Host "[PASS] json stdout error payload (no radio)"
        $pass++
    } else {
        Write-Host '[FAIL] json stdout unexpected shape'
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
if ($LiveBluetooth) {
    if ($codeSvc -eq 0 -or $codeSvc -eq 1) {
        Assert-File 'services json' $svcJson
        $sj = Get-Content -Raw $svcJson | ConvertFrom-Json
        if ($sj.ok -and $sj.devices.Count -gt 0) {
            Write-Host '[PASS] services scan returned devices'
            $pass++
        } else {
            Write-Host '[FAIL] services json missing devices'
            $fail++
        }
    } else {
        Write-Host "[FAIL] --services scan (exit $codeSvc)"
        $fail++
    }
} else {
    Assert-JsonScan 'services json' $svcJson $codeSvc
}

Write-Host ''
Write-Host "=== summary: $pass passed, $fail failed, $skip skipped ==="
if ($fail -gt 0) { exit 1 }
exit 0
