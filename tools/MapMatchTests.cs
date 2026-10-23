using System;
using System.IO;
using System.Text;
using System.Security.Cryptography;
using EQEmu_Patcher;

class MapMatchTests
{
    static int checks;
    static string Hash(string text)
    {
        using (var md5 = MD5.Create())
            return BitConverter.ToString(md5.ComputeHash(Encoding.UTF8.GetBytes(text))).Replace("-", "").ToLowerInvariant();
    }
    static void Check(bool result, string message)
    {
        ++checks;
        if (!result) throw new Exception(message);
    }
    static int Main()
    {
        string path = Path.Combine(Path.GetTempPath(), "thc-map-match-" + Guid.NewGuid().ToString("N"));
        try
        {
            string lf = "L 1, 2, 3, 4, 5, 6, 0, 0, 0\nP 1, 2, 3, 0, 0, 0, 2, Bazaar\n";
            string crlf = lf.Replace("\n", "\r\n");
            foreach (string text in new[] { lf, crlf })
            {
                File.WriteAllBytes(path, Encoding.UTF8.GetBytes(text));
                Check(PatchFileMatch.Matches(path, "maps/bazaar.txt", Hash(text)), "exact map");
                Check(PatchFileMatch.Matches(path, "maps/bazaar.txt", Hash(lf)), "LF manifest");
                Check(PatchFileMatch.Matches(path, "MAPS\\My Maps\\bazaar_1.TXT", Hash(crlf).ToUpperInvariant()), "CRLF manifest, nested path, case");
                Check(!PatchFileMatch.Matches(path, "maps/bazaar.txt", Hash(lf.Replace("Bazaar", "Changed"))), "real map change must download");
                string opposite = text == lf ? crlf : lf;
                Check(!PatchFileMatch.Matches(path, "eqhost.txt", Hash(opposite)), "non-map text exact only");
                Check(!PatchFileMatch.Matches(path, "maps/bazaar.eqg", Hash(opposite)), "binary exact only");
                Check(!PatchFileMatch.Matches(path, "other/maps/bazaar.txt", Hash(opposite)), "only map root");
                Check(!PatchFileMatch.Matches(path, "maps/bazaar.txt", "invalid"), "invalid hash");
            }
            File.WriteAllBytes(path, Encoding.UTF8.GetBytes("a\rb\r\nc\n"));
            Check(PatchFileMatch.Matches(path, "maps/test.txt", Hash("a\rb\nc\n")), "lone CR preserved");
            Check(!PatchFileMatch.Matches(path, "maps/test.txt", Hash("a\nb\nc\n")), "lone CR is not LF");
            File.WriteAllBytes(path, new byte[0]);
            Check(PatchFileMatch.Matches(path, "maps/test.txt", Hash("")), "empty map");
            Check(!PatchFileMatch.Matches(path, "maps/test.txt", null), "null hash");
            File.Delete(path);
            Check(!PatchFileMatch.Matches(path, "maps/test.txt", Hash("")), "missing map");
            Console.WriteLine(checks + " production map matching checks passed");
            return 0;
        }
        catch (Exception ex) { Console.Error.WriteLine(ex); return 1; }
        finally { if (File.Exists(path)) File.Delete(path); }
    }
}
