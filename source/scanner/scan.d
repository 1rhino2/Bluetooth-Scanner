module scanner.scan;

import std.array;
import std.algorithm;
import std.conv;
import std.format : format;
import std.string;
import std.utf;

import core.sys.windows.windows;

import win32.bluetooth;
import win32.errors;
import scanner.device;
import scanner.options;
import output.device_class;

private string formatMac(const BLUETOOTH_ADDRESS addr)
{
    return addr.rgBytes[].map!(b => format("%02X", cast(uint)b)).join(":");
}

private string readDeviceName(const BLUETOOTH_DEVICE_INFO info)
{
    size_t n = 0;
    while (n < info.szName.length && info.szName[n] != 0)
        n++;
    if (n == 0)
        return "<unknown>";
    return toUTF8(info.szName[0 .. n]);
}

private string formatSystemTime(const SYSTEMTIME st)
{
    if (st.wYear < 1980)
        return "";
    return format("%04u-%02u-%02u %02u:%02u:%02u",
        st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);
}

private string formatGuid(const GUID g)
{
    return format("{%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X}",
        g.Data1, g.Data2, g.Data3,
        g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3],
        g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7]);
}

private string[] queryInstalledServices(BLUETOOTH_DEVICE_INFO info)
{
    DWORD count = 0;
    auto err = BluetoothEnumerateInstalledServices(null, &info, &count, null);
    if (err != ERROR_SUCCESS || count == 0)
        return null;

    auto guids = new GUID[count];
    err = BluetoothEnumerateInstalledServices(null, &info, &count, guids.ptr);
    if (err != ERROR_SUCCESS)
        return null;

    string[] out_;
    out_.reserve = count;
    foreach (g; guids)
        out_ ~= formatGuid(g);
    return out_;
}

private DeviceRecord recordFromInfo(const BLUETOOTH_DEVICE_INFO info, const ScanOptions opts)
{
    DeviceRecord r;
    r.address = formatMac(info.Address);
    r.name = readDeviceName(info);
    r.classOfDevice = info.ulClassofDevice;
    r.deviceKind = describeClassOfDevice(info.ulClassofDevice);
    r.connected = info.fConnected != 0;
    r.remembered = info.fRemembered != 0;
    r.authenticated = info.fAuthenticated != 0;
    r.lastSeen = formatSystemTime(info.stLastSeen);
    r.lastUsed = formatSystemTime(info.stLastUsed);
    if (opts.queryServices)
    {
        auto copy = info;
        r.services = queryInstalledServices(copy);
    }
    return r;
}

ScanResult scanDevices(const ScanOptions opts)
{
    auto params = defaultSearchParams();
    params.fReturnAuthenticated = opts.returnAuthenticated ? 1 : 0;
    params.fReturnRemembered = opts.returnRemembered ? 1 : 0;
    params.fReturnUnknown = opts.returnUnknown ? 1 : 0;
    params.fReturnConnected = opts.returnConnected ? 1 : 0;
    params.fIssueInquiry = opts.issueInquiry ? 1 : 0;
    params.cTimeoutMultiplier = opts.timeoutMultiplier;

    auto info = emptyDeviceInfo();
    auto hFind = BluetoothFindFirstDevice(&params, &info);
    if (hFind is null)
        return ScanResult([], win32LastError());

    DeviceRecord[] list;
    scope (exit)
        BluetoothFindDeviceClose(hFind);

    do
        list ~= recordFromInfo(info, opts);
    while (BluetoothFindNextDevice(hFind, &info) != 0);

    return ScanResult(list, null);
}
