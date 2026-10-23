using System;
using System.IO;
using System.Security.Cryptography;

namespace EQEmu_Patcher
{
    internal static class PatchFileMatch
    {
        internal static bool Matches(string path, string relativeName, string expected)
        {
            if (!File.Exists(path) || string.IsNullOrEmpty(expected)) return false;
            using (var md5 = MD5.Create())
            using (var stream = File.OpenRead(path))
                if (Equal(md5.ComputeHash(stream), expected)) return true;

            // Map collections have historically shipped with both Windows and Unix
            // newlines. Only maps may ignore this difference; binaries stay exact.
            string name = (relativeName ?? "").Replace('\\', '/');
            if (!name.StartsWith("maps/", StringComparison.OrdinalIgnoreCase) ||
                !name.EndsWith(".txt", StringComparison.OrdinalIgnoreCase)) return false;
            byte[] original = File.ReadAllBytes(path);
            using (var lf = new MemoryStream())
            using (var crlf = new MemoryStream())
            using (var md5 = MD5.Create())
            {
                for (int i = 0; i < original.Length; ++i)
                {
                    byte b = original[i];
                    if (b == 13 && i + 1 < original.Length && original[i + 1] == 10) continue;
                    lf.WriteByte(b);
                    if (b == 10) crlf.WriteByte(13);
                    crlf.WriteByte(b);
                }
                return Equal(md5.ComputeHash(lf.ToArray()), expected) ||
                    Equal(md5.ComputeHash(crlf.ToArray()), expected);
            }
        }

        private static bool Equal(byte[] hash, string expected)
        {
            return string.Equals(BitConverter.ToString(hash).Replace("-", ""),
                expected, StringComparison.OrdinalIgnoreCase);
        }
    }
}
