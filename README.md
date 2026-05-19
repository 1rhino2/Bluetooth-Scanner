# bluetooth-scanner

Windows Bluetooth device enumerator written in **D**. Single static binary, no runtime deps beyond the OS Bluetooth stack.

Lists nearby and cached devices with address, name, class-of-device, pairing state, and optional installed service GUIDs.

## Why this exists

`go tool pprof` has a base profile mode; Windows Settings shows paired gear but not a scriptable report. This tool prints a **fixed text or JSON snapshot** for recon notes, CI logs, or quick lab checks.

## Requirements

- Windows 10/11
- Bluetooth adapter enabled
- [DMD](https://dlang.org/download.html) 2.100+ and [DUB](https://dub.pm/)

## Build

```powershell
dub build --build=release
# or
.\build.ps1
```

Binary: `bluetooth-scanner.exe` in the project root (or `dub run --`).

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

## Project layout

```text
source/
  app.d                 CLI entry
  win32/
    bluetooth.d         API structs + static size checks
    errors.d              GetLastError helper
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

## Sample output

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

## CI / testing

```powershell
.\scripts\test-all.ps1
```

On machines **with** a Bluetooth radio, live scans must succeed. On **GitHub Actions** (and other VMs without a radio), the same script still passes by checking struct layout, CLI parsing, and JSON error output (`ok: false`) when the stack returns no handle.

## Limits

- Windows only (uses `Bthprops.lib`).
- Best for enumeration, not pairing, spoofing, or exploitation.
- Service list is raw GUIDs unless you map them yourself.
- Unknown devices need discoverable mode and enough `--timeout`.

## License

MIT. See [LICENSE](LICENSE).
