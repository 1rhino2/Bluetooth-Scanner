module scanner.options;

struct ScanOptions
{
    bool returnAuthenticated = true;
    bool returnRemembered = true;
    bool returnUnknown = true;
    bool returnConnected = true;
    bool issueInquiry = true;
    ubyte timeoutMultiplier = 4;
    bool queryServices = false;
}

bool validateScanOptions(ref ScanOptions opts, out string err)
{
    if (opts.timeoutMultiplier < 1 || opts.timeoutMultiplier > 48)
    {
        err = "timeout multiplier must be 1..48 (each step is ~1.28s inquiry time)";
        return false;
    }
    err = null;
    return true;
}
