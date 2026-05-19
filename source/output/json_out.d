module output.json_out;

import std.array;
import std.conv;
import std.format : format, formattedWrite;
import std.stdio;
import std.string;

import scanner.device;

private string jsonEscape(string s)
{
    auto b = appender!string();
    foreach (c; s)
    {
        switch (c)
        {
        case '\\': b.put('\\'); b.put('\\'); break;
        case '"': b.put('\\'); b.put('"'); break;
        case '\n': b.put('\\'); b.put('n'); break;
        case '\r': b.put('\\'); b.put('r'); break;
        case '\t': b.put('\\'); b.put('t'); break;
        default:
            if (cast(uint)c < 0x20)
            {
                char[8] esc = void;
                auto n = formattedWrite(esc[], "\\u%04x", cast(uint)c);
                b.put(esc[0 .. n]);
            }
            else
                b.put(c);
        }
    }
    return b.data;
}

private void writeDeviceJson(ref Appender!string b, const DeviceRecord d)
{
    b.put("{");
    b.put("\"address\":\""); b.put(jsonEscape(d.address)); b.put("\"");
    b.put(",\"name\":\""); b.put(jsonEscape(d.name)); b.put("\"");
    b.put(",\"class_of_device\":\""); b.put(format("0x%08X", d.classOfDevice)); b.put("\"");
    b.put(",\"kind\":\""); b.put(jsonEscape(d.deviceKind)); b.put("\"");
    b.put(",\"connected\":"); b.put(d.connected ? "true" : "false");
    b.put(",\"remembered\":"); b.put(d.remembered ? "true" : "false");
    b.put(",\"authenticated\":"); b.put(d.authenticated ? "true" : "false");
    if (d.lastSeen.length)
    {
        b.put(",\"last_seen\":\""); b.put(jsonEscape(d.lastSeen)); b.put("\"");
    }
    if (d.lastUsed.length)
    {
        b.put(",\"last_used\":\""); b.put(jsonEscape(d.lastUsed)); b.put("\"");
    }
    if (d.services !is null)
    {
        b.put(",\"services\":[");
        foreach (i, s; d.services)
        {
            if (i) b.put(",");
            b.put("\""); b.put(jsonEscape(s)); b.put("\"");
        }
        b.put("]");
    }
    b.put("}");
}

void writeScanJson(const ScanResult result, File output)
{
    auto b = appender!string();
    b.put("{");
    if (result.error !is null)
    {
        b.put("\"ok\":false,\"error\":\"");
        b.put(jsonEscape(result.error));
        b.put("\"");
    }
    else
    {
        b.put("\"ok\":true,\"count\":");
        b.put(to!string(result.devices.length));
        b.put(",\"devices\":[");
        foreach (i, d; result.devices)
        {
            if (i) b.put(",");
            writeDeviceJson(b, d);
        }
        b.put("]");
    }
    b.put("}");
    output.write(b.data);
}
