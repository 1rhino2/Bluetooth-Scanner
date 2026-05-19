module app;

import std.conv;
import std.file;
import core.stdc.stdlib : exit;
import std.stdio;
import std.string;

import scanner.device;
import scanner.options;
import scanner.scan;
import output.report;
import output.json_out;

struct CliOptions
{
    bool once;
    bool interactive = true;
    bool showHelp;
    bool queryServices;
    bool noInquiry;
    bool pairedOnly;
    bool jsonStdout;
    string jsonPath;
    ubyte timeout = 4;
    ScanOptions scan;
}

void printUsage()
{
    writeln("bluetooth-scanner - enumerate Bluetooth devices on Windows");
    writeln();
    writeln("usage:");
    writeln("  bluetooth-scanner [options]");
    writeln();
    writeln("options:");
    writeln("  --once              scan once and exit");
    writeln("  --timeout N         inquiry multiplier 1..48 (default 4)");
    writeln("  --fast              same as --timeout 1");
    writeln("  --no-inquiry        paired/remembered cache only");
    writeln("  --paired-only       skip unknown unpaired devices");
    writeln("  --services          list installed service GUIDs");
    writeln("  --json [path]       JSON to stdout or file");
    writeln("  -h, --help          show this help");
    writeln();
    writeln("examples:");
    writeln("  dub run -- --once --fast");
    writeln("  dub run -- --once --services --json scan.json");
}

bool parseArgs(string[] args, ref CliOptions cli, out string err)
{
    cli = CliOptions();
    cli.scan = ScanOptions();

    size_t i = 1;
    while (i < args.length)
    {
        auto arg = args[i];
        if (arg == "-h" || arg == "--help")
            cli.showHelp = true;
        else if (arg == "--once")
            cli.once = true;
        else if (arg == "--fast")
            cli.timeout = 1;
        else if (arg == "--no-inquiry")
            cli.noInquiry = true;
        else if (arg == "--paired-only")
            cli.pairedOnly = true;
        else if (arg == "--services")
            cli.queryServices = true;
        else if (arg == "--json")
        {
            if (i + 1 < args.length && !args[i + 1].startsWith("-"))
            {
                cli.jsonPath = args[i + 1];
                i += 2;
                continue;
            }
            cli.jsonStdout = true;
        }
        else if (arg.startsWith("--json="))
            cli.jsonPath = arg[7 .. $];
        else if (arg == "--timeout")
        {
            if (i + 1 >= args.length)
            {
                err = "--timeout requires a value";
                return false;
            }
            try
                cli.timeout = cast(ubyte)to!uint(args[i + 1]);
            catch (Exception e)
            {
                err = "invalid --timeout value";
                return false;
            }
            i += 2;
            continue;
        }
        else if (arg.startsWith("--timeout="))
        {
            auto v = arg[10 .. $];
            try
                cli.timeout = cast(ubyte)to!uint(v);
            catch (Exception e)
            {
                err = "invalid --timeout value";
                return false;
            }
        }
        else
        {
            err = "unknown option: " ~ arg;
            return false;
        }
        i++;
    }

    cli.scan.timeoutMultiplier = cli.timeout;
    cli.scan.issueInquiry = !cli.noInquiry;
    cli.scan.queryServices = cli.queryServices;
    if (cli.pairedOnly)
        cli.scan.returnUnknown = false;

    string optErr;
    if (!validateScanOptions(cli.scan, optErr))
    {
        err = optErr;
        return false;
    }
    return true;
}

void emitJson(const ScanResult result, const CliOptions cli)
{
    if (cli.jsonPath.length)
    {
        auto f = File(cli.jsonPath, "w");
        writeScanJson(result, f);
        f.close();
        writeln("[*] Wrote ", cli.jsonPath);
    }
    else
        writeScanJson(result, stdout);
}

int runScan(const CliOptions cli)
{
    auto result = scanDevices(cli.scan);

    if (cli.jsonStdout || cli.jsonPath.length)
        emitJson(result, cli);
    else
        printScanResult(result, true);

    if (result.error !is null)
        return 2;
    return result.devices.length ? 0 : 1;
}

void main(string[] args)
{
    CliOptions cli;
    string err;
    if (!parseArgs(args, cli, err))
    {
        if (err.length)
            stderr.writeln("[!]", err);
        printUsage();
        exit(1);
    }

    if (cli.showHelp)
    {
        printUsage();
        exit(0);
    }

    if (cli.once || args.length > 1)
        cli.interactive = false;

    if (!cli.interactive)
    {
        if (!cli.jsonStdout)
        {
            printBanner();
            writeln("[*] Scanning...");
        }
        exit(runScan(cli));
    }

    while (true)
    {
        printBanner();
        writeln("[*] Press Enter to scan (q + Enter to quit).");
        auto line = stdin.readln().strip();
        if (line == "q" || line == "Q")
        {
            writeln("[i] Bye.");
            break;
        }

        writeln("[*] Scanning...");
        runScan(cli);
        writeln();
        writeln("[*] Enter to scan again, q to quit.");
        line = stdin.readln().strip();
        if (line == "q" || line == "Q")
            break;
    }
}
