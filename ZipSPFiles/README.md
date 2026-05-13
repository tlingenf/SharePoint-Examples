# ZipSPFiles

Azure Functions (dotnet-isolated, .NET 8) project that:
1. Reads files from a SharePoint folder using Microsoft Graph.
2. Builds a ZIP in temporary storage.
3. Uploads the ZIP back to the same SharePoint document library folder.

## What the function does

Function name: CreateZIPFromSPFiles

Trigger: HTTP (GET or POST)

Input:
- Query string: folderPath
- Or JSON body:
  {
    "folderPath": "https://contoso.sharepoint.com/sites/Finance/Shared Documents/Invoices"
  }

Important input requirement:
- folderPath must be an absolute SharePoint URL and must include:
  - Site path (for example /sites/Finance)
  - Library name (for example Shared Documents)
  - Optional subfolder path

Output:
- zipFilePath: SharePoint path where the ZIP was written
- webUrl: Browser URL for the ZIP file
- fileName: Generated ZIP filename

## Prerequisites

- .NET SDK 8
- Azure Functions Core Tools v4
- PowerShell 7+
- Microsoft Graph PowerShell module
- Access to:
  - Azure Function App (for managed identity)
  - Target SharePoint site and library
  - Entra admin privileges to grant application permissions

Install Graph PowerShell module (if needed):

```powershell
Install-Module Microsoft.Graph -Scope CurrentUser
```

## Configure the Function App

The function reads settings from environment variables (local.settings.json for local runs, App Settings in Azure for deployed app).

### Required auth settings

For local development with client secret flow:
- TENANT_ID: Entra tenant ID
- CLIENT_ID: App registration client ID (or managed identity client ID when hosted)
- CLIENT_SECRET: App registration secret (local only)

For Azure hosted managed identity flow:
- CLIENT_ID: User-assigned managed identity client ID (optional if using system-assigned identity)

### Requested environment variables

Add these settings exactly:

- GRAPH_SCOPE: https://graph.microsoft.com/.default
  - Microsoft Graph app-only scope used when requesting tokens.
  - Default in code is the same value, but set it explicitly for clarity.

- FILE_FILTER_PATTERN: (?i)-invoice.pdf$
  - Regex used to skip matching files while building the ZIP.
  - This pattern excludes any file name ending in -invoice.pdf (case-insensitive).

- ZIP_UPLOAD_CHUNK_SIZE_BYTES: 327680
  - Chunk size used for upload sessions.
  - Must be a positive integer and a multiple of 327680 bytes.

- ZIP_UPLOAD_CONFLICT_BEHAVIOR: replace
  - Conflict behavior used by Graph upload session.
  - replace overwrites existing file if the generated ZIP name already exists.

### local.settings.json example

```json
{
  "IsEncrypted": false,
  "Values": {
    "AzureWebJobsStorage": "UseDevelopmentStorage=true",
    "FUNCTIONS_WORKER_RUNTIME": "dotnet-isolated",
    "TENANT_ID": "<tenant-guid>",
    "CLIENT_ID": "<app-or-managed-identity-client-id>",
    "CLIENT_SECRET": "<secret-for-local-dev-only>",
    "GRAPH_SCOPE": "https://graph.microsoft.com/.default",
    "FILE_FILTER_PATTERN": "(?i)-invoice.pdf$",
    "ZIP_UPLOAD_CHUNK_SIZE_BYTES": "327680",
    "ZIP_UPLOAD_CONFLICT_BEHAVIOR": "replace"
  }
}
```

For Azure, configure the same keys in Function App -> Settings -> Environment variables (App Settings). Do not store local.settings.json secrets in source control.

## Grant managed identity app permissions (Sites.Selected)

Use Set-AppPermissions.ps1 to assign Sites.Selected application permission from both:
- Microsoft Graph
- SharePoint Online

Script file:
- Set-AppPermissions.ps1

Run with display name:

```powershell
./Set-AppPermissions.ps1 -ManagedIdentityDisplayName "<function-app-managed-identity-display-name>"
```

Or run with client ID:

```powershell
./Set-AppPermissions.ps1 -ManagedIdentityDisplayName "placeholder" -ManagedIdentityClientId "<managed-identity-client-id>"
```

What this script does:
- Connects to Graph with AppRoleAssignment.ReadWrite.All and Application.Read.All
- Locates the managed identity service principal
- Assigns Sites.Selected app role from Graph and SharePoint service principals

## Grant app principal rights to the destination SharePoint site

After Sites.Selected is assigned, grant the app principal access to the specific site using Grant-SitePermission.ps1.

Note:
- The repository script name is Grant-SitePermission.ps1 (singular).
- If you refer to Grant-SitePermissions.ps1 in internal docs, use the singular filename when executing.

Script file:
- Grant-SitePermission.ps1

Run:

```powershell
./Grant-SitePermission.ps1 `
  -SiteUrl "https://contoso.sharepoint.com/sites/Finance" `
  -AppClientId "<managed-identity-or-app-client-id>" `
  -AppDisplayName "<managed-identity-display-name>"
```

What this script does:
- Connects to Graph with Sites.FullControl.All
- Resolves the target SharePoint site ID
- Grants write role to the app principal on that site

## Build and run locally

Build:

```powershell
dotnet build
```

Run Functions host:

```powershell
func start
```

## Invoke the function

GET example:

```text
http://localhost:7071/api/CreateZIPFromSPFiles?folderPath=https://contoso.sharepoint.com/sites/Finance/Shared%20Documents/Invoices
```

POST example body:

```json
{
  "folderPath": "https://contoso.sharepoint.com/sites/Finance/Shared Documents/Invoices"
}
```

## Troubleshooting

- Error: Local authentication requires TENANT_ID, CLIENT_ID, and CLIENT_SECRET
  - Add all three settings for local execution.

- Error: ZIP_UPLOAD_CHUNK_SIZE_BYTES must be a multiple of 327680 bytes
  - Use 327680, 655360, 983040, etc.

- Site or library not found
  - Verify folderPath includes the correct site and library names.

- Access denied to SharePoint or Graph
  - Confirm both scripts were executed successfully and admin consent was granted where required.
