module output.device_class;

import std.format : format;

string describeClassOfDevice(ulong cod)
{
    auto major = (cod >> 8) & 0x1F;
    auto minor = (cod >> 2) & 0x3F;

    string majorName;
    switch (major)
    {
    case 0x01: majorName = "Computer"; break;
    case 0x02: majorName = "Phone"; break;
    case 0x03: majorName = "LAN/Network"; break;
    case 0x04: majorName = "Audio/Video"; break;
    case 0x05: majorName = "Peripheral"; break;
    case 0x06: majorName = "Imaging"; break;
    case 0x07: majorName = "Wearable"; break;
    case 0x08: majorName = "Toy"; break;
    case 0x09: majorName = "Health"; break;
    default: majorName = "Misc/Unknown"; break;
    }

    return format("%s (major=0x%02X minor=0x%02X)", majorName, major, minor);
}
