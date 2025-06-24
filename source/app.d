// Link with Windows Bluetooth library
pragma(lib, "Bthprops.lib");

import core.sys.windows.windows;
import std.stdio;
import std.string;
import std.conv;
import std.algorithm;

// Minimal Windows Bluetooth API bindings for device discovery
extern (Windows)
{
    alias HANDLE = void*;
    struct BLUETOOTH_DEVICE_SEARCH_PARAMS
    {
        DWORD dwSize;
        BOOL fReturnAuthenticated;
        BOOL fReturnRemembered;
        BOOL fReturnUnknown;
        BOOL fReturnConnected;
        BOOL fIssueInquiry;
        UCHAR cTimeoutMultiplier;
        HANDLE hRadio;
    }

    struct BLUETOOTH_DEVICE_INFO
    {
        DWORD dwSize;
        ubyte[6] address;
        ULONG ulClassofDevice;
        BOOL fConnected;
        BOOL fRemembered;
        BOOL fAuthenticated;
        wchar[248] szName;
    }

    HANDLE BluetoothFindFirstDevice(const BLUETOOTH_DEVICE_SEARCH_PARAMS*, BLUETOOTH_DEVICE_INFO*);
    BOOL BluetoothFindNextDevice(HANDLE, BLUETOOTH_DEVICE_INFO*);
    BOOL BluetoothFindDeviceClose(HANDLE);
}

void printDeviceInfo(size_t count, ref BLUETOOTH_DEVICE_INFO deviceInfo)
{
    string addr = deviceInfo.address[0 .. 6].map!(b => format("%02X", b)).join(":");
    wchar nullChar = 0;
    auto nameLen = countUntil(deviceInfo.szName[], nullChar);
    string name = to!string(deviceInfo.szName[0 .. nameLen]);
    writeln("\n[+] Device #", count);
    writeln("    Address      : ", addr);
    writeln("    Name         : ", (name.length ? name : "<unknown>"));
    writeln("    Class        : ", format("0x%08X", deviceInfo.ulClassofDevice));
    writeln("    Connected    : ", deviceInfo.fConnected ? "Yes" : "No");
    writeln("    Remembered   : ", deviceInfo.fRemembered ? "Yes" : "No");
    writeln("    Authenticated: ", deviceInfo.fAuthenticated ? "Yes" : "No");
}

void printBanner()
{
    writeln("\n========================================");
    writeln("   Windows Bluetooth Device Scanner");
    writeln("========================================\n");
    writeln("  Fast, simple, and pentest-ready!");
    writeln("  Scans for nearby Bluetooth devices.");
    writeln("  Press Enter to start scanning.\n");
}

void printSummary(size_t count)
{
    if (count == 0)
    {
        writeln("\n[*] No Bluetooth devices found.");
        writeln("[?] Try these tips:");
        writeln("   - Move closer to devices");
        writeln("   - Enable device discoverable mode");
        writeln("   - Ensure Bluetooth is ON");
        writeln("   - Restart Bluetooth or your PC");
        writeln("   - Try running as Administrator");
    }
    else
    {
        writeln("\n[*] Scan complete. Found ", count, " device(s).");
        writeln("[i] Use this info for further Bluetooth pentesting or enumeration.");
    }
}

void main()
{
    while (true)
    {
        printBanner();
        writeln("[*] Scanning for Bluetooth devices... (this is quick!)\n");

        BLUETOOTH_DEVICE_SEARCH_PARAMS searchParams;
        searchParams.dwSize = BLUETOOTH_DEVICE_SEARCH_PARAMS.sizeof;
        searchParams.fReturnAuthenticated = true;
        searchParams.fReturnRemembered = true;
        searchParams.fReturnUnknown = true;
        searchParams.fReturnConnected = true;
        searchParams.fIssueInquiry = true;
        searchParams.cTimeoutMultiplier = 1; // Fastest scan (~1.5s)
        searchParams.hRadio = null;

        BLUETOOTH_DEVICE_INFO deviceInfo;
        deviceInfo.dwSize = BLUETOOTH_DEVICE_INFO.sizeof;

        auto hFind = BluetoothFindFirstDevice(&searchParams, &deviceInfo);
        size_t count = 0;
        bool scanSuccess = false;
        if (hFind !is null)
        {
            scanSuccess = true;
            do
            {
                count++;
                printDeviceInfo(count, deviceInfo);
            }
            while (BluetoothFindNextDevice(hFind, &deviceInfo));
            BluetoothFindDeviceClose(hFind);
        }

        if (!scanSuccess || count == 0)
        {
            writeln("\n[!] No Bluetooth devices found or Bluetooth is off.");
            writeln("[?] Make sure Bluetooth is enabled and your device is discoverable.");
            writeln("[?] Troubleshooting:");
            writeln("   - Check if Bluetooth is enabled in Windows settings");
            writeln("   - Ensure your device is not in airplane mode");
            writeln("   - Try restarting your Bluetooth radio or PC");
            writeln("   - Move closer to target devices");
            writeln("   - Try running as Administrator");
            writeln("\n[?] Press Enter to retry, or type 'q' then Enter to quit.");
            string input = stdin.readln().strip();
            if (input.length && (input[0] == 'q' || input[0] == 'Q'))
            {
                writeln("[i] Exiting. Stay safe!");
                break;
            }
            continue;
        }

        printSummary(count);
        writeln("\n[Press Enter to scan again, or type 'q' then Enter to quit]");
        string input = stdin.readln().strip();
        if (input.length && (input[0] == 'q' || input[0] == 'Q'))
        {
            writeln("[i] Exiting. Happy hunting!");
            break;
        }
    }
}
// Made with love by @1rhino2
