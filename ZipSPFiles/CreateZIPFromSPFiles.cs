using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Net;
using System.Net.Http.Headers;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Azure.Core;
using Azure.Identity;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Http;
using Microsoft.Graph;
using Microsoft.Graph.Drives.Item.Items.Item.CreateUploadSession;
using Microsoft.Graph.Models;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace Concord.Billing
{
    public static class CreateZIPFromSPFiles
    {
        private const string DefaultGraphScope = "https://graph.microsoft.com/.default";
        private const int DefaultUploadChunkSizeBytes = 320 * 1024;
        private const int UploadChunkSizeUnitBytes = 320 * 1024;
        private const string DefaultUploadConflictBehavior = "replace";

        private const string ManagedIdentityClientIdSetting = "CLIENT_ID";
        private const string ManagedIdentityClientIdLegacySetting = "CLIENT_ID";

        private const string ManagedIdentityTenantIdSetting = "TENANT_ID";
        private const string LocalClientSecretSetting = "CLIENT_SECRET";

        private const string GraphScopeSetting = "GRAPH_SCOPE";
        private const string UploadChunkSizeSetting = "ZIP_UPLOAD_CHUNK_SIZE_BYTES";
        private const string UploadConflictBehaviorSetting = "ZIP_UPLOAD_CONFLICT_BEHAVIOR";
        private const string FilterPatternSetting = "FILE_FILTER_PATTERN";

        [Function("CreateZIPFromSPFiles")]
        public static async Task<HttpResponseData> Run(
            [HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequestData req,
            FunctionContext executionContext)
        {
            ILogger log = executionContext.GetLogger(nameof(CreateZIPFromSPFiles));
            log.LogInformation("CreateZIPFromSPFiles request received.");

            string folderPath = GetQueryParameter(req.Url, "folderPath");

            string requestBody = await new StreamReader(req.Body).ReadToEndAsync();
            if (!string.IsNullOrWhiteSpace(requestBody))
            {
                var body = JsonConvert.DeserializeObject<ZipRequest>(requestBody);
                folderPath = folderPath ?? body?.FolderPath;
            }

            if (string.IsNullOrWhiteSpace(folderPath))
            {
                return await CreateJsonResponse(req, HttpStatusCode.BadRequest, new
                {
                    message = "Provide folderPath in query string or request body. Example: /sites/Finance/Shared Documents/Invoices"
                });
            }

            string tempZipPath = Path.Combine(Path.GetTempPath(), $"{Guid.NewGuid():N}.zip");

            try
            {
                RuntimeConfig runtimeConfig = LoadRuntimeConfig();
                GraphServiceClient graphClient = CreateGraphClient(runtimeConfig);
                SharePointPathInfo pathInfo = ParseSharePointPath(folderPath);

                var site = await graphClient.Sites[$"{pathInfo.HostName}:/{pathInfo.SitePath}"].GetAsync();
                if (site?.Id == null)
                {
                    return await CreateJsonResponse(req, HttpStatusCode.NotFound, new
                    {
                        message = "SharePoint site could not be resolved from folderPath."
                    });
                }

                var drives = await graphClient.Sites[site.Id].Drives.GetAsync();
                Drive resolvedDrive = ResolveDriveForLibrary(pathInfo, drives?.Value);

                if (resolvedDrive?.Id == null)
                {
                    return await CreateJsonResponse(req, HttpStatusCode.NotFound, new
                    {
                        message = $"Document library '{pathInfo.LibraryName}' was not found in site '{pathInfo.SitePath}'."
                    });
                }

                DriveItem folderItem;
                if (string.IsNullOrWhiteSpace(pathInfo.FolderPathWithinLibrary))
                {
                    folderItem = await graphClient.Drives[resolvedDrive.Id].Items["root"].GetAsync();
                }
                else
                {
                    folderItem = await graphClient.Drives[resolvedDrive.Id].Items["root"]
                        .ItemWithPath(pathInfo.FolderPathWithinLibrary)
                        .GetAsync();
                }

                if (folderItem?.Id == null || folderItem.Folder == null)
                {
                    return await CreateJsonResponse(req, HttpStatusCode.NotFound, new
                    {
                        message = "The provided folderPath does not resolve to a folder in SharePoint."
                    });
                }

                Regex filterRegex = null;
                if (!string.IsNullOrWhiteSpace(runtimeConfig.FilterPattern))
                {
                    try
                    {
                        filterRegex = new Regex(runtimeConfig.FilterPattern, RegexOptions.IgnoreCase | RegexOptions.Compiled);
                    }
                    catch (ArgumentException ex)
                    {
                        throw new InvalidOperationException($"{FilterPatternSetting} must be a valid regular expression.", ex);
                    }
                }

                await CreateZipFromFolderAsync(graphClient, resolvedDrive.Id, folderItem.Id, tempZipPath, filterRegex, log);

                string zipFileName = BuildZipName(pathInfo.FolderPathWithinLibrary);
                string uploadPath = string.IsNullOrWhiteSpace(pathInfo.FolderPathWithinLibrary)
                    ? zipFileName
                    : $"{pathInfo.FolderPathWithinLibrary.TrimEnd('/')}/{zipFileName}";

                var uploadSession = await graphClient.Drives[resolvedDrive.Id].Items["root"]
                    .ItemWithPath(uploadPath)
                    .CreateUploadSession
                    .PostAsync(new CreateUploadSessionPostRequestBody
                    {
                        Item = new DriveItemUploadableProperties
                        {
                            AdditionalData = new Dictionary<string, object>
                            {
                                ["@microsoft.graph.conflictBehavior"] = runtimeConfig.UploadConflictBehavior
                            }
                        }
                    });

                if (uploadSession?.UploadUrl == null)
                {
                    throw new InvalidOperationException("Upload session could not be created.");
                }

                log.LogInformation("Uploading ZIP file to SharePoint: {UploadPath}", uploadPath);
                await UploadLargeFileAsync(uploadSession.UploadUrl, tempZipPath, runtimeConfig.UploadChunkSizeBytes);
                log.LogInformation("Upload completed for ZIP file: {UploadPath}", uploadPath);

                var uploadedItem = await graphClient.Drives[resolvedDrive.Id].Items["root"]
                    .ItemWithPath(uploadPath)
                    .GetAsync();

                log.LogInformation("ZIP file path: {webUrl}", uploadedItem?.WebUrl);

                return await CreateJsonResponse(req, HttpStatusCode.OK, new
                {
                    zipFilePath = BuildOutputPath(pathInfo, zipFileName),
                    webUrl = uploadedItem?.WebUrl,
                    fileName = zipFileName
                });
            }
            catch (Exception ex)
            {
                log.LogError(ex, "Failed to ZIP and upload SharePoint files.");
                return await CreateJsonResponse(req, HttpStatusCode.InternalServerError, new
                {
                    message = "Failed to process SharePoint folder.",
                    detail = ex.Message
                });
            }
            finally
            {
                if (File.Exists(tempZipPath))
                {
                    File.Delete(tempZipPath);
                }
            }
        }

        private static GraphServiceClient CreateGraphClient(RuntimeConfig config)
        {
            TokenCredential credential;

            if (IsRunningInAzure())
            {
                // Use managed identity only when hosted in Azure.
                credential = string.IsNullOrWhiteSpace(config.ManagedIdentityClientId)
                    ? new ManagedIdentityCredential()
                    : new ManagedIdentityCredential(config.ManagedIdentityClientId);
            }
            else if (!string.IsNullOrWhiteSpace(config.ManagedIdentityTenantId) &&
                     !string.IsNullOrWhiteSpace(config.ManagedIdentityClientId) &&
                     !string.IsNullOrWhiteSpace(config.LocalClientSecret))
            {
                // Local development uses an explicit app registration secret flow.
                credential = new ClientSecretCredential(
                    config.ManagedIdentityTenantId,
                    config.ManagedIdentityClientId,
                    config.LocalClientSecret);
            }
            else
            {
                throw new InvalidOperationException(
                    "Local authentication requires TENANT_ID, CLIENT_ID, and CLIENT_SECRET. " +
                    "Azure CLI and developer credential fallbacks are disabled.");
            }

            return new GraphServiceClient(credential, new[] { config.GraphScope });
        }

        private static bool IsRunningInAzure()
        {
            return !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("WEBSITE_INSTANCE_ID")) ||
                   !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("IDENTITY_ENDPOINT")) ||
                   !string.IsNullOrWhiteSpace(Environment.GetEnvironmentVariable("MSI_ENDPOINT"));
        }

        private static SharePointPathInfo ParseSharePointPath(string inputPath)
        {
            string hostName = string.Empty;
            string pathOnly = string.Empty;

            if (Uri.TryCreate(inputPath?.Trim(), UriKind.Absolute, out Uri absoluteUri))
            {
                hostName = absoluteUri.Host;
                pathOnly = absoluteUri.AbsolutePath;
            }

            if (string.IsNullOrWhiteSpace(hostName))
            {
                throw new InvalidOperationException("Set SHAREPOINT_HOSTNAME app setting or provide an absolute SharePoint URL as folderPath.");
            }

            string[] segments = pathOnly
                .Trim('/')
                .Split('/', StringSplitOptions.RemoveEmptyEntries)
                .Select(Uri.UnescapeDataString)
                .ToArray();

            if (segments.Length < 3)
            {
                throw new ArgumentException("folderPath must be in the form /sites/{siteName}/{libraryName}/optional/subfolder.");
            }

            if (!string.Equals(segments[0], "sites", StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(segments[0], "teams", StringComparison.OrdinalIgnoreCase))
            {
                throw new ArgumentException("folderPath must start with /sites or /teams.");
            }

            string sitePath = $"{segments[0]}/{segments[1]}";
            string libraryName = segments[2];

            string folderWithinLibrary = segments.Length > 3
                ? string.Join("/", segments.Skip(3))
                : string.Empty;

            return new SharePointPathInfo
            {
                HostName = hostName,
                SitePath = sitePath,
                LibraryName = libraryName,
                FolderPathWithinLibrary = folderWithinLibrary
            };
        }

        private static Drive ResolveDriveForLibrary(SharePointPathInfo pathInfo, IEnumerable<Drive> drives)
        {
            if (drives == null)
            {
                return null;
            }

            Drive byName = drives.FirstOrDefault(d =>
                string.Equals(d.Name, pathInfo.LibraryName, StringComparison.OrdinalIgnoreCase));
            if (byName != null)
            {
                return byName;
            }

            return drives.FirstOrDefault(d =>
                string.Equals(GetLibrarySegmentFromDriveWebUrl(d.WebUrl, pathInfo.SitePath), pathInfo.LibraryName, StringComparison.OrdinalIgnoreCase));
        }

        private static string GetLibrarySegmentFromDriveWebUrl(string driveWebUrl, string sitePath)
        {
            if (!Uri.TryCreate(driveWebUrl, UriKind.Absolute, out Uri driveUri))
            {
                return null;
            }

            string[] segments = driveUri.AbsolutePath
                .Trim('/')
                .Split('/', StringSplitOptions.RemoveEmptyEntries)
                .Select(Uri.UnescapeDataString)
                .ToArray();

            string[] siteSegments = sitePath
                .Trim('/')
                .Split('/', StringSplitOptions.RemoveEmptyEntries)
                .Select(Uri.UnescapeDataString)
                .ToArray();

            if (segments.Length <= siteSegments.Length)
            {
                return null;
            }

            for (int i = 0; i < siteSegments.Length; i++)
            {
                if (!string.Equals(segments[i], siteSegments[i], StringComparison.OrdinalIgnoreCase))
                {
                    return null;
                }
            }

            return segments[siteSegments.Length];
        }

        private static async Task CreateZipFromFolderAsync(
            GraphServiceClient graphClient,
            string driveId,
            string rootFolderItemId,
            string zipPath,
            Regex filterRegex,
            ILogger log)
        {
            using var zipStream = new FileStream(zipPath, FileMode.Create, FileAccess.ReadWrite, FileShare.None);
            using var archive = new ZipArchive(zipStream, ZipArchiveMode.Create, leaveOpen: false);

            await AddFolderEntriesAsync(graphClient, driveId, rootFolderItemId, archive, string.Empty, filterRegex, log);
        }

        private static async Task AddFolderEntriesAsync(
            GraphServiceClient graphClient,
            string driveId,
            string folderItemId,
            ZipArchive archive,
            string relativePrefix,
            Regex filterRegex,
            ILogger log)
        {
            var children = await graphClient.Drives[driveId].Items[folderItemId].Children.GetAsync();
            if (children?.Value == null)
            {
                return;
            }

            foreach (DriveItem item in children.Value)
            {
                string currentRelativePath = string.IsNullOrWhiteSpace(relativePrefix)
                    ? item.Name
                    : $"{relativePrefix}/{item.Name}";

                if (item.Folder != null)
                {
                    await AddFolderEntriesAsync(graphClient, driveId, item.Id, archive, currentRelativePath, filterRegex, log);
                    continue;
                }

                if (item.File == null)
                {
                    continue;
                }

                if (filterRegex != null && filterRegex.IsMatch(currentRelativePath))
                {
                    log.LogInformation("Skipping file due to filterPattern match: {RelativePath}", currentRelativePath);
                    continue;
                }

                log.LogInformation("Adding file to ZIP: {RelativePath}", currentRelativePath);
                using Stream sourceStream = await graphClient.Drives[driveId].Items[item.Id].Content.GetAsync();
                var zipEntry = archive.CreateEntry(currentRelativePath, CompressionLevel.Optimal);
                using Stream entryStream = zipEntry.Open();
                await sourceStream.CopyToAsync(entryStream);
            }
        }

        private static async Task UploadLargeFileAsync(string uploadUrl, string filePath, int maxChunkSize)
        {
            using var fileStream = new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
            using var httpClient = new System.Net.Http.HttpClient();

            long fileSize = fileStream.Length;
            long uploadedBytes = 0;
            byte[] buffer = new byte[maxChunkSize];

            while (uploadedBytes < fileSize)
            {
                int bytesRead = await fileStream.ReadAsync(buffer, 0, buffer.Length);
                if (bytesRead == 0)
                {
                    break;
                }

                long rangeStart = uploadedBytes;
                long rangeEnd = uploadedBytes + bytesRead - 1;

                using var request = new System.Net.Http.HttpRequestMessage(System.Net.Http.HttpMethod.Put, uploadUrl)
                {
                    Content = new System.Net.Http.ByteArrayContent(buffer, 0, bytesRead)
                };
                request.Content.Headers.ContentType = new MediaTypeHeaderValue("application/octet-stream");
                request.Content.Headers.TryAddWithoutValidation("Content-Range", $"bytes {rangeStart}-{rangeEnd}/{fileSize}");

                using System.Net.Http.HttpResponseMessage response = await httpClient.SendAsync(request);

                if (response.StatusCode != HttpStatusCode.Accepted &&
                    response.StatusCode != HttpStatusCode.Created &&
                    response.StatusCode != HttpStatusCode.OK)
                {
                    string errorContent = await response.Content.ReadAsStringAsync();
                    throw new InvalidOperationException($"Chunk upload failed with status {(int)response.StatusCode}: {errorContent}");
                }

                uploadedBytes += bytesRead;
            }
        }

        private static async Task<HttpResponseData> CreateJsonResponse(HttpRequestData req, HttpStatusCode statusCode, object payload)
        {
            HttpResponseData response = req.CreateResponse(statusCode);
            await response.WriteAsJsonAsync(payload);
            return response;
        }

        private static string GetQueryParameter(Uri requestUrl, string key)
        {
            if (requestUrl == null || string.IsNullOrWhiteSpace(requestUrl.Query))
            {
                return null;
            }

            string query = requestUrl.Query.TrimStart('?');
            foreach (string pair in query.Split('&', StringSplitOptions.RemoveEmptyEntries))
            {
                string[] parts = pair.Split('=', 2);
                string name = Uri.UnescapeDataString(parts[0].Replace("+", " "));
                if (!string.Equals(name, key, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                if (parts.Length == 1)
                {
                    return string.Empty;
                }

                return Uri.UnescapeDataString(parts[1].Replace("+", " "));
            }

            return null;
        }

        private static RuntimeConfig LoadRuntimeConfig()
        {
            string managedIdentityClientId = GetFirstNonEmptySetting(ManagedIdentityClientIdSetting, ManagedIdentityClientIdLegacySetting);
            string managedIdentityTenantId = GetSettingOrDefault(ManagedIdentityTenantIdSetting, null);
            string localClientSecret = GetSettingOrDefault(LocalClientSecretSetting, null);
            string graphScope = GetSettingOrDefault(GraphScopeSetting, DefaultGraphScope);
            string uploadConflictBehavior = GetSettingOrDefault(UploadConflictBehaviorSetting, DefaultUploadConflictBehavior);
            string filterPattern = GetSettingOrDefault(FilterPatternSetting, null);
            int uploadChunkSizeBytes = GetIntSettingOrDefault(UploadChunkSizeSetting, DefaultUploadChunkSizeBytes);

            if (uploadChunkSizeBytes <= 0)
            {
                throw new InvalidOperationException($"{UploadChunkSizeSetting} must be greater than 0.");
            }

            if (uploadChunkSizeBytes % UploadChunkSizeUnitBytes != 0)
            {
                throw new InvalidOperationException($"{UploadChunkSizeSetting} must be a multiple of {UploadChunkSizeUnitBytes} bytes.");
            }

            return new RuntimeConfig
            {
                ManagedIdentityClientId = managedIdentityClientId,
                ManagedIdentityTenantId = managedIdentityTenantId,
                LocalClientSecret = localClientSecret,
                GraphScope = graphScope,
                UploadChunkSizeBytes = uploadChunkSizeBytes,
                UploadConflictBehavior = uploadConflictBehavior,
                FilterPattern = filterPattern
            };
        }

        private static string GetFirstNonEmptySetting(params string[] settingNames)
        {
            foreach (string name in settingNames)
            {
                string value = Environment.GetEnvironmentVariable(name);
                if (!string.IsNullOrWhiteSpace(value))
                {
                    return value;
                }
            }

            return null;
        }

        private static string GetSettingOrDefault(string settingName, string defaultValue)
        {
            string value = Environment.GetEnvironmentVariable(settingName);
            return string.IsNullOrWhiteSpace(value) ? defaultValue : value;
        }

        private static int GetIntSettingOrDefault(string settingName, int defaultValue)
        {
            string value = Environment.GetEnvironmentVariable(settingName);
            if (string.IsNullOrWhiteSpace(value))
            {
                return defaultValue;
            }

            if (!int.TryParse(value, out int parsed))
            {
                throw new InvalidOperationException($"{settingName} must be a valid integer.");
            }

            return parsed;
        }

        private static string BuildZipName(string folderPathWithinLibrary)
        {
            string baseName = string.IsNullOrWhiteSpace(folderPathWithinLibrary)
                ? "root"
                : folderPathWithinLibrary.Trim('/').Split('/').Last();

            string safeBaseName = string.Join("_", baseName.Split(Path.GetInvalidFileNameChars(), StringSplitOptions.RemoveEmptyEntries));
            return $"{safeBaseName}_{DateTime.UtcNow:yyyyMMddHHmmss}.zip";
        }

        private static string BuildOutputPath(SharePointPathInfo pathInfo, string zipFileName)
        {
            if (string.IsNullOrWhiteSpace(pathInfo.FolderPathWithinLibrary))
            {
                return $"/{pathInfo.SitePath}/{pathInfo.LibraryName}/{zipFileName}";
            }

            return $"/{pathInfo.SitePath}/{pathInfo.LibraryName}/{pathInfo.FolderPathWithinLibrary}/{zipFileName}";
        }

        private sealed class ZipRequest
        {
            [JsonProperty("folderPath")]
            public string FolderPath { get; set; }
        }

        private sealed class SharePointPathInfo
        {
            public string HostName { get; set; }

            public string SitePath { get; set; }

            public string LibraryName { get; set; }

            public string FolderPathWithinLibrary { get; set; }
        }

        private sealed class RuntimeConfig
        {
            public string ManagedIdentityClientId { get; set; }

            public string ManagedIdentityTenantId { get; set; }

            public string LocalClientSecret { get; set; }

            public string GraphScope { get; set; }

            public int UploadChunkSizeBytes { get; set; }

            public string UploadConflictBehavior { get; set; }

            public string FilterPattern { get; set; }
        }
    }
}
