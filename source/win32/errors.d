module win32.errors;

import core.sys.windows.windows;
import std.conv;
import std.string;
import std.utf;

string win32ErrorMessage(DWORD code)
{
    wchar[512] buf = void;
    enum flags = FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS;
    auto len = FormatMessageW(flags, null, code, 0, buf.ptr, cast(DWORD)buf.length, null);
    if (len == 0)
        return format("Win32 error %s", code);
    auto msg = toUTF8(buf[0 .. len]);
    while (msg.length && (msg[$ - 1] == '\n' || msg[$ - 1] == '\r'))
        msg = msg[0 .. $ - 1];
    return msg;
}

string win32LastError()
{
    return win32ErrorMessage(GetLastError());
}
