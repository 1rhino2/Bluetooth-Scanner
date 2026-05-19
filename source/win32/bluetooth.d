module win32.bluetooth;

// Win32 Bluetooth discovery API (bluetoothapis.h). Struct layouts must match exactly.

pragma(lib, "Bthprops.lib");

import core.sys.windows.windows;

enum : uint
{
    BLUETOOTH_MAX_NAME_SIZE = 248,
}

extern (Windows) nothrow @nogc
{
    alias BLUETOOTH_HANDLE = void*;

    union BLUETOOTH_ADDRESS
    {
        ulong ullLong;
        ubyte[6] rgBytes;
    }

    struct BLUETOOTH_DEVICE_SEARCH_PARAMS
    {
        DWORD dwSize;
        BOOL fReturnAuthenticated;
        BOOL fReturnRemembered;
        BOOL fReturnUnknown;
        BOOL fReturnConnected;
        BOOL fIssueInquiry;
        UCHAR cTimeoutMultiplier;
        BLUETOOTH_HANDLE hRadio;
    }

    struct BLUETOOTH_DEVICE_INFO
    {
        DWORD dwSize;
        BLUETOOTH_ADDRESS Address;
        ULONG ulClassofDevice;
        BOOL fConnected;
        BOOL fRemembered;
        BOOL fAuthenticated;
        SYSTEMTIME stLastSeen;
        SYSTEMTIME stLastUsed;
        WCHAR[BLUETOOTH_MAX_NAME_SIZE] szName;
    }

    BLUETOOTH_HANDLE BluetoothFindFirstDevice(
        BLUETOOTH_DEVICE_SEARCH_PARAMS* pbtsp,
        BLUETOOTH_DEVICE_INFO* pbtdi);

    BOOL BluetoothFindNextDevice(BLUETOOTH_HANDLE hFind, BLUETOOTH_DEVICE_INFO* pbtdi);

    BOOL BluetoothFindDeviceClose(BLUETOOTH_HANDLE hFind);

    DWORD BluetoothEnumerateInstalledServices(
        BLUETOOTH_HANDLE hRadio,
        BLUETOOTH_DEVICE_INFO* pbtdi,
        DWORD* pcServices,
        GUID* pGuidServices);
}

// dwSize is validated strictly by the API (Win64, MSVC layout).
static assert(BLUETOOTH_DEVICE_SEARCH_PARAMS.sizeof == 40);
static assert(BLUETOOTH_DEVICE_INFO.sizeof == 560);

BLUETOOTH_DEVICE_SEARCH_PARAMS defaultSearchParams() nothrow @nogc
{
    BLUETOOTH_DEVICE_SEARCH_PARAMS p;
    p.dwSize = BLUETOOTH_DEVICE_SEARCH_PARAMS.sizeof;
    p.fReturnAuthenticated = true;
    p.fReturnRemembered = true;
    p.fReturnUnknown = true;
    p.fReturnConnected = true;
    p.fIssueInquiry = true;
    p.cTimeoutMultiplier = 4;
    p.hRadio = null;
    return p;
}

BLUETOOTH_DEVICE_INFO emptyDeviceInfo() nothrow @nogc
{
    BLUETOOTH_DEVICE_INFO info;
    info.dwSize = BLUETOOTH_DEVICE_INFO.sizeof;
    return info;
}
