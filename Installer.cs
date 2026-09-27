using System;
using System.Diagnostics;
using System.IO;
using System.IO.Compression;
using System.Reflection;

internal static class Installer
{
    private const string ResourceName = "Payload.zip";

    private static int Main(string[] args)
    {
        try
        {
            bool extractOnly = args.Length == 2 && args[0] == "--extract-only";
            if (args.Length != 0 && !extractOnly)
            {
                Console.Error.WriteLine("Usage: CS2-Discord-RPC-Setup.exe [--extract-only <folder>]");
                return 2;
            }

            string installDir = extractOnly
                ? Path.GetFullPath(args[1])
                : Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "CS2 RPC");

            Console.Title = "CS2 Discord RPC Installer";
            Console.WriteLine("CS2 Discord RPC Installer");
            Console.WriteLine("Installing to: " + installDir);
            Console.WriteLine();
            ExtractPayload(installDir);
            Console.WriteLine("Application files installed.");

            if (extractOnly) return 0;

            Console.WriteLine("Starting the guided setup...");
            Console.WriteLine();
            string setupPath = Path.Combine(installDir, "Setup.cmd");
            var startInfo = new ProcessStartInfo("cmd.exe", "/d /c \"\"" + setupPath + "\"\"");
            startInfo.WorkingDirectory = installDir;
            startInfo.UseShellExecute = false;
            using (Process setup = Process.Start(startInfo))
            {
                if (setup == null) throw new InvalidOperationException("Could not start Setup.cmd.");
                setup.WaitForExit();
                return setup.ExitCode;
            }
        }
        catch (Exception error)
        {
            Console.Error.WriteLine("Installation failed: " + error.Message);
            Console.WriteLine("Press Enter to close.");
            Console.ReadLine();
            return 1;
        }
    }

    private static void ExtractPayload(string installDir)
    {
        Directory.CreateDirectory(installDir);
        string root = Path.GetFullPath(installDir).TrimEnd(Path.DirectorySeparatorChar) + Path.DirectorySeparatorChar;
        Stream payload = Assembly.GetExecutingAssembly().GetManifestResourceStream(ResourceName);
        if (payload == null) throw new InvalidOperationException("The application payload is missing.");

        using (payload)
        using (var archive = new ZipArchive(payload, ZipArchiveMode.Read))
        {
            foreach (ZipArchiveEntry entry in archive.Entries)
            {
                string relative = entry.FullName.Replace('/', Path.DirectorySeparatorChar);
                string target = Path.GetFullPath(Path.Combine(installDir, relative));
                if (!target.StartsWith(root, StringComparison.OrdinalIgnoreCase))
                    throw new InvalidDataException("An invalid path was found in the installer payload.");

                if (entry.FullName.EndsWith("/"))
                {
                    Directory.CreateDirectory(target);
                    continue;
                }

                Directory.CreateDirectory(Path.GetDirectoryName(target));
                using (Stream input = entry.Open())
                using (Stream output = new FileStream(target, FileMode.Create, FileAccess.Write, FileShare.None))
                    input.CopyTo(output);
            }
        }
    }
}
