using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Net;
using System.Security.Cryptography;
using System.Net.Http;
using System.Threading;
using YamlDotNet.Core.Tokens;
using System.Runtime.InteropServices.ComTypes;
using System.Windows.Forms;

namespace EQEmu_Patcher
{
    /* General Utility Methods */
    class UtilityLibrary
    {
        //Download a file to current directory
        public static async Task<string> DownloadFile(CancellationTokenSource cts, string url, string outFile)
        {

            try
            {
                var client = new HttpClient();
                var response = await client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, cts.Token);
                response.EnsureSuccessStatusCode();
                using (var stream = await response.Content.ReadAsStreamAsync())
                {
                    var outPath = outFile.Replace("/", "\\");
                    if (outFile.Contains("\\")) { //Make directory if needed.
                        string dir = System.IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\" + outFile.Substring(0, outFile.LastIndexOf("\\"));
                        Directory.CreateDirectory(dir);
                    }
                    outPath = System.IO.Path.GetDirectoryName(Application.ExecutablePath) + "\\" + outFile;

                    using (var w = File.Create(outPath)) {
                        await stream.CopyToAsync(w, 81920, cts.Token);
                    }
                }
            } catch(ArgumentNullException e)
            {
                return "ArgumentNullExpception: " + e.Message;
            } catch(HttpRequestException e)
            {
                return "HttpRequestException: " + e.Message;
            } catch (Exception e)
            {
                return "Exception: " + e.Message;
            }
            return "";
        }

        // Download will grab a remote URL's file and return the data as a byte array
        public static async Task<byte[]> Download(CancellationTokenSource cts, string url)
        {
            var client = new HttpClient();
            var response = await client.GetAsync(url, HttpCompletionOption.ResponseHeadersRead, cts.Token);
            response.EnsureSuccessStatusCode();
            using (var stream = await response.Content.ReadAsStreamAsync())
            {
                using (var w = new MemoryStream())
                {
                    await stream.CopyToAsync(w, 81920, cts.Token);
                    return w.ToArray();
                }
            }
        }

        public static string GetMD5(string filename)
        {
            using (var md5 = MD5.Create())
            {
                using (var stream = File.OpenRead(filename))
                {
                    var hash = md5.ComputeHash(stream);

                    StringBuilder sb = new StringBuilder();

                    for (int i = 0; i < hash.Length; i++)
                    {
                        sb.Append(hash[i].ToString("X2"));
                    }

                    return sb.ToString();
                }
            }
        }

        public static System.Diagnostics.Process StartEverquest()
        {
            var workingDirectory = System.IO.Path.GetDirectoryName(Application.ExecutablePath);
            var launcherPath = System.IO.Path.Combine(workingDirectory, "THC_Launcher.cmd");

            if (File.Exists(launcherPath))
            {
                var launcherStartInfo = new System.Diagnostics.ProcessStartInfo
                {
                    FileName = launcherPath,
                    WorkingDirectory = workingDirectory,
                    UseShellExecute = true
                };

                return System.Diagnostics.Process.Start(launcherStartInfo);
            }

            var startInfo = new System.Diagnostics.ProcessStartInfo
            {
                FileName = System.IO.Path.Combine(workingDirectory, "eqgame.exe"),
                Arguments = "patchme",
                WorkingDirectory = workingDirectory
            };

            return System.Diagnostics.Process.Start(startInfo);
        }

        //Pass the working directory (or later, you can pass another directory) and it returns a hash if the file is found
        public static string GetEverquestExecutableHash(string path)
        {
            var di = new System.IO.DirectoryInfo(path);
            var files = di.GetFiles("eqgame.exe");
            if (files == null || files.Length == 0)
            {
                return "";
            }
            return UtilityLibrary.GetMD5(files[0].FullName);
        }

        public static string GetEverquestExecutablePath(string path)
        {
            var di = new System.IO.DirectoryInfo(path);
            var files = di.GetFiles("eqgame.exe");
            if (files == null || files.Length == 0)
            {
                return "";
            }

            return files[0].FullName;
        }

        public static bool IsTheHeroChroniclesRoF2Executable(string filename)
        {
            if (filename == "" || !File.Exists(filename))
            {
                return false;
            }

            byte[] bytes = File.ReadAllBytes(filename);
            return MatchesAASliderGate(bytes, 0x2095D0) && MatchesAASliderGate(bytes, 0x20962B);
        }

        private static bool MatchesAASliderGate(byte[] bytes, int offset)
        {
            if (bytes.Length <= offset + 14)
            {
                return false;
            }

            if (
                bytes[offset] != 0x80 ||
                bytes[offset + 1] != 0x7C ||
                bytes[offset + 2] != 0x24 ||
                bytes[offset + 3] != 0x17
            )
            {
                return false;
            }

            if (bytes[offset + 4] != 0x33 && bytes[offset + 4] != 0x01)
            {
                return false;
            }

            return (
                bytes[offset + 5] == 0x72 &&
                bytes[offset + 6] == 0x1F &&
                bytes[offset + 7] == 0x80 &&
                bytes[offset + 8] == 0x3D &&
                bytes[offset + 9] == 0xC2 &&
                bytes[offset + 10] == 0x09 &&
                bytes[offset + 11] == 0xDE &&
                bytes[offset + 12] == 0x00 &&
                bytes[offset + 13] == 0x00
            );
        }

        // Returns true only if the path is a relative and does not contain ..
        public static bool IsPathChild(string path)
        {
            // get the absolute path
            var absPath = Path.GetFullPath(path);
            var basePath = Path.GetDirectoryName(Application.ExecutablePath); 
            // check if absPath contains basePath
            if (!absPath.Contains(basePath))
            {
                return false;
            }
            if (path.Contains("..\\"))
            {
                return false;
            }
            return true;
        }
    }
}
