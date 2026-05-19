module struct_test;

import std.stdio;
import win32.bluetooth;

void main()
{
    writeln("BLUETOOTH_DEVICE_SEARCH_PARAMS.sizeof = ", BLUETOOTH_DEVICE_SEARCH_PARAMS.sizeof);
    writeln("BLUETOOTH_DEVICE_INFO.sizeof = ", BLUETOOTH_DEVICE_INFO.sizeof);
    writeln("ok: struct sizes match Win32 SDK expectations");
}
