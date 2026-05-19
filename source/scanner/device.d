module scanner.device;

struct DeviceRecord
{
    string address;
    string name;
    ulong classOfDevice;
    string deviceKind;
    bool connected;
    bool remembered;
    bool authenticated;
    string lastSeen;
    string lastUsed;
    string[] services;
}

struct ScanResult
{
    DeviceRecord[] devices;
    string error; // set when BluetoothFindFirstDevice fails
}
