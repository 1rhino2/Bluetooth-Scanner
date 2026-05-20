# bluetooth-scanner

Windows Bluetooth device enumerator in D. One static binary, no extra runtime deps beyond the OS stack.

Lists paired and nearby devices with address, name, class, pairing state, and optional service GUIDs. Output is plain text or JSON for logs, lab notes, or CI.

## Build

```powershell
dub build --build=release
```

## Test

```powershell
powershell -File scripts/test-all.ps1
```

## Usage

```powershell
.\btscan.exe
.\btscan.exe --json
```

## CI

GitHub Actions runs on push (see `.github/workflows/ci.yml`).

## License

MIT
