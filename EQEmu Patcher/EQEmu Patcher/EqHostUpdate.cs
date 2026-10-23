using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;

namespace EQEmu_Patcher
{
    // eqhost is player-owned configuration: patch its active login address only.
    internal static class EqHostUpdate
    {
        private static readonly Regex Section = new Regex(@"^[ \t]*\[LoginServer\][^\r\n]*(?:\r\n|\n|$)", RegexOptions.Multiline | RegexOptions.IgnoreCase);
        private static readonly Regex NextSection = new Regex(@"^[ \t]*\[", RegexOptions.Multiline);
        private static readonly Regex Host = new Regex(@"^([ \t]*Host[ \t]*=[ \t]*)([^ \t\r\n;#]*)", RegexOptions.Multiline | RegexOptions.IgnoreCase);

        private static string Decode(byte[] data, out Encoding encoding, out byte[] prefix)
        {
            var skip = 0;
            encoding = Encoding.GetEncoding(28591); // reversible mapping for BOM-less bytes
            if (data.Length >= 2 && data[0] == 0xff && data[1] == 0xfe)
            {
                if (data.Length >= 4 && data[2] == 0 && data[3] == 0) throw new InvalidDataException("UTF-32 eqhost is unsupported; original file preserved.");
                encoding = new UnicodeEncoding(false, false, true); skip = 2;
            }
            else if (data.Length >= 2 && data[0] == 0xfe && data[1] == 0xff) { encoding = new UnicodeEncoding(true, false, true); skip = 2; }
            else if (data.Length >= 3 && data[0] == 0xef && data[1] == 0xbb && data[2] == 0xbf) skip = 3;
            prefix = data.Take(skip).ToArray();
            return encoding.GetString(data, skip, data.Length - skip);
        }

        private static void BodyRange(string text, Match section, out int start, out int length)
        {
            start = section.Index + section.Length;
            var next = NextSection.Match(text, start);
            length = (next.Success ? next.Index : text.Length) - start;
        }

        public static byte[] Merge(byte[] original, byte[] downloaded)
        {
            Encoding incomingEncoding, encoding; byte[] incomingPrefix, prefix;
            var incoming = Decode(downloaded, out incomingEncoding, out incomingPrefix);
            var incomingSection = Section.Match(incoming);
            if (!incomingSection.Success) throw new InvalidDataException("Downloaded login configuration has no LoginServer section.");
            int start, length; BodyRange(incoming, incomingSection, out start, out length);
            var hostMatch = Host.Match(incoming.Substring(start, length));
            if (!hostMatch.Success || hostMatch.Groups[2].Length == 0) throw new InvalidDataException("Downloaded login configuration has no Host address.");
            var host = hostMatch.Groups[2].Value;
            var text = Decode(original, out encoding, out prefix);
            var newline = text.Contains("\r\n") ? "\r\n" : "\n";
            var section = Section.Match(text);
            if (!section.Success)
            {
                if (text.Length != 0 && !text.EndsWith("\n")) text += newline;
                text += "[LoginServer]" + newline + "Host=" + host + newline;
            }
            else
            {
                BodyRange(text, section, out start, out length);
                var body = text.Substring(start, length);
                var replacement = Host.IsMatch(body) ? Host.Replace(body, m => m.Groups[1].Value + host) :
                    (section.Value.EndsWith("\n") ? "" : newline) + "Host=" + host + newline + body;
                text = text.Substring(0, start) + replacement + text.Substring(start + length);
            }
            return prefix.Concat(encoding.GetBytes(text)).ToArray();
        }

        public static void Apply(string path, byte[] downloaded)
        {
            var original = File.ReadAllBytes(path);
            var merged = Merge(original, downloaded);
            if (original.SequenceEqual(merged)) return;
            var backup = path + ".thc-host.bak";
            if (!File.Exists(backup)) File.Copy(path, backup);
            var temporary = path + ".thc-host-" + Guid.NewGuid().ToString("N") + ".tmp";
            try { File.WriteAllBytes(temporary, merged); File.Replace(temporary, path, null); }
            finally { if (File.Exists(temporary)) File.Delete(temporary); }
        }
    }
}
