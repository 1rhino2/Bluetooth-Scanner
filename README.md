<!-- bluetooth-scanner -->
<div align="center">

  <img src="https://img.shields.io/badge/Platform-Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white" alt="Windows" />
  <img src="https://img.shields.io/badge/Language-D-BC231E?style=for-the-badge" alt="D" />
  <img src="https://img.shields.io/badge/License-MIT-22C55E?style=for-the-badge" alt="MIT" />

  <br /><br />

  <h1><b>bluetooth-scanner</b></h1>

  <a href="https://git.io/typing-svg">
    <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=22&pause=1200&color=A259FF&center=true&vCenter=true&width=520&lines=Windows+Bluetooth+enumerator;Single+static+binary;Text+%2B+JSON+snapshots;Built+for+recon+%26+CI" alt="Typing animation" />
  </a>

  <br /><br />

  <a href="https://github.com/1rhino2/Bluetooth-Scanner/actions/workflows/ci.yml">
    <img src="https://github.com/1rhino2/Bluetooth-Scanner/actions/workflows/ci.yml/badge.svg" alt="CI" />
  </a>
  <a href="LICENSE">
    <img src="https://img.shields.io/badge/docs-README-24292F?style=flat-square&logo=github" alt="Docs" />
  </a>
  <a href="scripts/test-all.ps1">
    <img src="https://img.shields.io/badge/tests-test--all.ps1-0EA5E9?style=flat-square&logo=powershell" alt="Tests" />
  </a>

</div>

<p align="center">
  Windows Bluetooth device enumerator written in <b>D</b>. Single static binary, no runtime deps beyond the OS Bluetooth stack.<br />
  Lists nearby and cached devices with address, name, class-of-device, pairing state, and optional installed service GUIDs.
</p>

---

## Why this exists

`go tool pprof` has a base profile mode; Windows Settings shows paired gear but not a scriptable report. This tool prints a **fixed text or JSON snapshot** for recon notes, CI logs, or quick lab checks.

---

## Requirements

| | |
|---|---|
| OS | Windows 10/11 |
| Hardware | Bluetooth adapter enabled |
| Toolchain | [DMD](https://dlang.org/download.html) 2.100+ and [DUB](https://dub.pm/) |

---

## Build

```powershell
dub build --build=release
# or
.\build.ps1
```

Binary: `bluetooth-scanner.exe` in the project root (or `dub run --`).

---

## Usage

```text
bluetooth-scanner [options]
```

| Option | Description |
|--------|-------------|
| `--once` | One scan, then exit |
| `--timeout N` | Inquiry multiplier 1..48 (~1.28s per step) |
| `--fast` | `--timeout 1` |
| `--no-inquiry` | Cached/paired devices only (no active inquiry) |
| `--paired-only` | Hide unknown unpaired devices |
| `--services` | Query installed SDP service GUIDs (slower) |
| `--json [path]` | JSON to stdout or file |
| `-h`, `--help` | Help |

### Examples

```powershell
dub run -- --once --fast
dub run -- --once --services --json scan.json
.\bluetooth-scanner.exe --once --timeout 8
```

Interactive mode (no flags): run `dub run`, press Enter to scan, `q` to quit.

---

<details>
<summary><b>Project layout</b></summary>

```text
source/
  app.d                 CLI entry
  win32/
    bluetooth.d         API structs + static size checks
    errors.d            GetLastError helper
  scanner/
    device.d            DeviceRecord / ScanResult
    options.d           ScanOptions
    scan.d              BluetoothFindFirstDevice loop
  output/
    device_class.d      CoD major/minor label
    report.d            Text output
    json_out.d          JSON export
test/
  struct_test.d         Prints/asserts struct sizes (CI)
```

`BLUETOOTH_DEVICE_INFO` must match `bluetoothapis.h` exactly (`dwSize` is validated by the API). Wrong layouts silently failed before v2; we `static assert` sizes at compile time.

</details>

<details open>
<summary><b>Sample output</b></summary>

```text
[+] Device #1
    Address      : EF:B6:1C:EE:B1:AC
    Name         : Example Headphones
    Class        : 0x00240404
    Kind         : Audio/Video (major=0x04 minor=0x01)
    Connected    : no
    Remembered   : yes
    Authenticated: yes
```

</details>

---

## CI / testing

```powershell
.\scripts\test-all.ps1
```

On machines **with** a Bluetooth radio, live scans must succeed. On **GitHub Actions** (and other VMs without a radio), the same script still passes by checking struct layout, CLI parsing, and JSON error output (`ok: false`) when the stack returns no handle.

---

## Limits

- Windows only (uses `Bthprops.lib`).
- Best for enumeration, not pairing, spoofing, or exploitation.
- Service list is raw GUIDs unless you map them yourself.
- Unknown devices need discoverable mode and enough `--timeout`.

---

<div align="center">

  <b>License</b><br />
  MIT. See <a href="LICENSE">LICENSE</a>.

  <br /><br />

  <a href="https://github.com/1rhino2">
    <img src="https://img.shields.io/badge/@1rhino2-181717?style=for-the-badge&logo=github&logoColor=white" alt="1rhino2" />
  </a>
  <a href="https://1rhino2.github.io/">
    <img src="https://img.shields.io/badge/website-1rhino2.github.io-4CAF50?style=for-the-badge&logo=google-chrome&logoColor=white" alt="Website" />
  </a>

</div>
