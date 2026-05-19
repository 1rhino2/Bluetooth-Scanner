module output.report;

import std.format : format;
import std.stdio;
import std.string;

import scanner.device;

void printBanner()
{
    writeln();
    writeln("========================================");
    writeln("   Windows Bluetooth Device Scanner");
    writeln("========================================");
    writeln();
}

void printDevice(size_t index, const DeviceRecord d)
{
    writeln();
    writeln("[+]", "Device #", index);
    writeln("    Address      :", d.address);
    writeln("    Name         :", d.name);
    writeln("    Class        :", format("0x%08X", d.classOfDevice));
    writeln("    Kind         :", d.deviceKind);
    writeln("    Connected    :", d.connected ? "yes" : "no");
    writeln("    Remembered   :", d.remembered ? "yes" : "no");
    writeln("    Authenticated:", d.authenticated ? "yes" : "no");
    if (d.lastSeen.length)
        writeln("    Last seen    :", d.lastSeen);
    if (d.lastUsed.length)
        writeln("    Last used    :", d.lastUsed);
    if (d.services !is null)
    {
        if (d.services.length == 0)
            writeln("    Services     : (none listed)");
        else
        {
            writeln("    Services     :");
            foreach (s; d.services)
                writeln("      -", s);
        }
    }
}

void printScanResult(const ScanResult result, bool verboseError)
{
    if (result.error !is null)
    {
        writeln("[!] Scan failed:", result.error);
        if (verboseError)
        {
            writeln("[?] Common causes:");
            writeln("    - Bluetooth radio disabled or no adapter");
            writeln("    - Bluetooth stack not available to this user");
        }
        return;
    }

    if (result.devices.length == 0)
    {
        writeln("[*] No devices matched this scan.");
        writeln("[?] Enable discoverable mode, increase --timeout, or drop --no-inquiry.");
        return;
    }

    size_t i = 1;
    foreach (d; result.devices)
    {
        printDevice(i, d);
        i++;
    }
    writeln();
    writeln("[*] Found", result.devices.length, "device(s).");
}
