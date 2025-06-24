# Bluetooth Device Scanner & Info Grabber (Windows, D)

A basic Bluetooth device scanner for Windows, written in D. Scans for nearby Bluetooth devices, grabs info like device names, classes, and services. Useful for pentesting and physical reconnaissance.

## Features

- Scans for discoverable Bluetooth devices
- Retrieves device names, device classes, and available services
- Outputs results in a pentesting-friendly format

## Requirements

- Windows 10/11
- D compiler (e.g., DMD)
- dub (D package manager)

## Build

```
dub build --build=release
```

## Run

```
dub run
```

## Notes

- Requires Bluetooth hardware and enabled radio
- Run as administrator for best results

## Pentesting Use

- Use this tool to enumerate nearby Bluetooth devices and gather information for further analysis or exploitation.

## License

MIT
