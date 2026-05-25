// HubFiles.cs
//
// Single-file .NET 8 console app for the Peakboard Hub Public API
// FileManagement endpoints (/v1/files*). Targets the `dismantle` folder.
//
// Setup:
//     dotnet new console -o HubFiles
//     Replace the generated Program.cs with this file
//     setx PEAKBOARD_API_KEY "<your-key>"        (Windows)
//     export PEAKBOARD_API_KEY=<your-key>        (Linux/macOS)
//
// Usage:
//     dotnet run -- list
//     dotnet run -- upload <localFile>
//     dotnet run -- download <headId> <outFile>

using System.Net.Http.Headers;
using System.Text.Json;

const string Base = "https://api.peakboard.com/public-api";
const string Folder = "dismantle";

var apiKey = Environment.GetEnvironmentVariable("PEAKBOARD_API_KEY")
    ?? throw new InvalidOperationException("Set PEAKBOARD_API_KEY in the environment.");

using var http = new HttpClient();
var token = await GetTokenAsync(apiKey);
http.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

if (args.Length == 0)
{
    Usage();
    return;
}

switch (args[0])
{
    case "list":
        await ListAsync();
        break;
    case "upload" when args.Length >= 2:
        await UploadAsync(args[1]);
        break;
    case "download" when args.Length >= 3:
        await DownloadAsync(long.Parse(args[1]), args[2]);
        break;
    default:
        Usage();
        break;
}

async Task<string> GetTokenAsync(string key)
{
    using var req = new HttpRequestMessage(HttpMethod.Get, $"{Base}/v2/auth/token");
    req.Headers.Add("apiKey", key);
    var resp = await http.SendAsync(req);
    resp.EnsureSuccessStatusCode();
    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    return doc.RootElement.GetProperty("accessToken").GetString()!;
}

async Task ListAsync()
{
    var resp = await http.GetAsync($"{Base}/v1/files?path=/{Folder}");
    resp.EnsureSuccessStatusCode();
    using var doc = JsonDocument.Parse(await resp.Content.ReadAsStringAsync());
    Console.WriteLine($"{"headId",-8}{"size",-10}{"name"}");
    foreach (var f in doc.RootElement.GetProperty("data").GetProperty("files").EnumerateArray())
    {
        Console.WriteLine($"{f.GetProperty("headId").GetInt64(),-8}{f.GetProperty("size").GetInt64(),-10}{f.GetProperty("name").GetString()}");
    }
}

async Task UploadAsync(string localPath)
{
    using var content = new MultipartFormDataContent
    {
        { new StringContent(Folder), "Path" },
        { new StringContent("hub-cs-sample"), "Username" },
    };
    var fileBytes = await File.ReadAllBytesAsync(localPath);
    content.Add(new ByteArrayContent(fileBytes), "File", Path.GetFileName(localPath));

    var resp = await http.PostAsync($"{Base}/v1/files", content);
    resp.EnsureSuccessStatusCode();
    Console.WriteLine($"Uploaded {localPath} to /{Folder} (use `list` to find the new headId).");
}

async Task DownloadAsync(long headId, string outPath)
{
    var bytes = await http.GetByteArrayAsync($"{Base}/v1/files/{headId}/download");
    await File.WriteAllBytesAsync(outPath, bytes);
    Console.WriteLine($"Wrote {bytes.Length} bytes to {outPath}");
}

void Usage()
{
    Console.Error.WriteLine("Usage:");
    Console.Error.WriteLine("  dotnet run -- list");
    Console.Error.WriteLine("  dotnet run -- upload   <localFile>");
    Console.Error.WriteLine("  dotnet run -- download <headId> <outFile>");
}
