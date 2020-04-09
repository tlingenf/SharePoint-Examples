using Microsoft.SharePoint.Client;
using OfficeDevPnP.Core;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

/*
 * ##########################################################################################################
# Disclaimer
# The sample scripts are not supported under any Microsoft standard support program or service.
#
# The sample scripts are provided AS IS without warranty of any kind. Microsoft further disclaims all
# implied warranties including, without limitation, any implied warranties of merchantability or of fitness
# for a particular purpose. The entire risk arising out of the use or performance of the sample scripts and
# documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the
# creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without
# limitation, damages for loss of business profits, business interruption, loss of business information,
# or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, 
# even if Microsoft has been advised of the possibility of such damages.
##########################################################################################################
*/

namespace SPExamples.Console.CodeExamples
{
    class CSOMLargeFileUpload
    {
        private const string siteUrl = "https://tenant.sharepoint.com/sites/destSiteUrl";

        public CSOMLargeFileUpload()
        {
            // Authenticate using Azure AD Application, App-Only Credentials, employ the PnPCore AuthenticationManager for assistance
            AuthenticationManager authManager = new AuthenticationManager();
            using (var context = authManager.GetAzureADAppOnlyAuthenticatedContext(
               siteUrl,
               ConfigurationManager.AppSettings["clientId"] as string,
               ConfigurationManager.AppSettings["tenantId"] as string,
               ConfigurationManager.AppSettings["pfxPath"] as string,
               ConfigurationManager.AppSettings["pfxPass"] as string))
            {
                // Recommended header to prioritize requests and help with throttling
                // More Info: https://docs.microsoft.com/en-us/sharepoint/dev/general-development/how-to-avoid-getting-throttled-or-blocked-in-sharepoint-online#BKMK_Bestpracticestohandlethrottling
                context.ExecutingWebRequest += delegate (object sender, WebRequestEventArgs e)
                {
                    e.WebRequestExecutor.WebRequest.UserAgent = "NONISV|Contoso|Demo1/1.0";
                };

                string instanceId = ProgramUtilities.GenerateRandomeString();

                // Files.Add - this one will fail
                try
                {
                    SimpleUpload(context, "Documents", Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SP2013_LargeFile1.pptx"), $"SP2013_LargeFile1_{instanceId}.pptx");
                    System.Console.ForegroundColor = ConsoleColor.Green;
                    System.Console.WriteLine("SaveBinaryDirect Suceeded");
                }
                catch (Exception ex)
                {
                    System.Console.ForegroundColor = ConsoleColor.Red;
                    System.Console.WriteLine("SimpleUpload Failed");
                    System.Console.WriteLine(string.Format("Exception while uploading file to the target site {0}.", ex.ToString()));
                    System.Console.ForegroundColor = ConsoleColor.White;
                }

                // SaveBinaryDirect - will fail since WebDav has issues with cliams auth
                try
                {
                    SaveBinaryDirect(context, "Documents", Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SP2013_LargeFile2.pptx"), $"SP2013_LargeFile2_{instanceId}.pptx");
                    System.Console.ForegroundColor = ConsoleColor.Green;
                    System.Console.WriteLine("SaveBinaryDirect Suceeded");
                }
                catch (Exception ex)
                {
                    System.Console.ForegroundColor = ConsoleColor.Red;
                    System.Console.WriteLine("SaveBinaryDirect Failed");
                    System.Console.WriteLine(string.Format("Exception while uploading file to the target site {0}.", ex.ToString()));
                    System.Console.ForegroundColor = ConsoleColor.White;
                }

                // UploadContentStream - will succeed
                try
                {
                    UploadDocumentContentStream(context, "Documents", Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "SP2013_LargeFile3.pptx"), $"SP2013_LargeFile3_{instanceId}.pptx");
                    System.Console.ForegroundColor = ConsoleColor.Green;
                    System.Console.WriteLine("UploadDocumentContentStream Suceeded");
                }
                catch (Exception ex)
                {
                    System.Console.ForegroundColor = ConsoleColor.Red;
                    System.Console.WriteLine("UploadDocumentContentStream Failed");
                    System.Console.WriteLine(string.Format("Exception while uploading file to the target site {0}.", ex.ToString()));
                    System.Console.ForegroundColor = ConsoleColor.White;
                }

                // Chunked File Upload - will succeed
                try
                {
                    UploadFileSlicePerSlice(context, "Documents", Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "verylargefile.txt"), $"verylargefile_{instanceId}.txt", 5);
                    System.Console.ForegroundColor = ConsoleColor.Green;
                    System.Console.WriteLine("UploadFileSlicePerSlice Suceeded");
                }
                catch (Exception ex)
                {
                    System.Console.ForegroundColor = ConsoleColor.Red;
                    System.Console.WriteLine("UploadFileSlicePerSlice Failed");
                    System.Console.WriteLine(string.Format("Exception while uploading file to the target site {0}.", ex.ToString()));
                    System.Console.ForegroundColor = ConsoleColor.White;
                }
            }
        }

        private void SimpleUpload(ClientContext context, string libraryName, string localFilePath, string destFileName)
        {
            Web web = context.Web;
            FileCreationInformation newFile = new FileCreationInformation();
            newFile.Content = System.IO.File.ReadAllBytes(localFilePath);
            newFile.Url = destFileName;

            // Get instances to the given library
            List docs = web.Lists.GetByTitle(libraryName);
            // Add file to the library
            Microsoft.SharePoint.Client.File uploadFile = docs.RootFolder.Files.Add(newFile);
            context.Load(uploadFile);
            context.ExecuteQueryWithIncrementalRetry(10, 30);
        }

        public void SaveBinaryDirect(ClientContext ctx, string libraryName, string localFilePath, string destFileName)
        {
            Web web = ctx.Web;

            List docs = ctx.Web.Lists.GetByTitle(libraryName);
            ctx.Load(docs, l => l.RootFolder);
            // Get the information about the folder that will hold the file
            ctx.Load(docs.RootFolder, f => f.ServerRelativeUrl);
            ctx.ExecuteQueryWithIncrementalRetry(10, 30);

            using (FileStream fs = new FileStream(localFilePath, FileMode.Open))
            {
                Microsoft.SharePoint.Client.File.SaveBinaryDirect(ctx, string.Format("{0}/{1}", docs.RootFolder.ServerRelativeUrl, destFileName), fs, true);
            }

        }

        public void UploadDocumentContentStream(ClientContext ctx, string libraryName, string localFilePath, string destFileName)
        {

            Web web = ctx.Web;

            using (FileStream fs = new FileStream(localFilePath, FileMode.Open))
            {
                FileCreationInformation flciNewFile = new FileCreationInformation();

                // This is the key difference for the first case - using ContentStream property
                flciNewFile.ContentStream = fs;
                flciNewFile.Url = System.IO.Path.GetFileName(destFileName);
                flciNewFile.Overwrite = true;

                List docs = web.Lists.GetByTitle(libraryName);
                Microsoft.SharePoint.Client.File uploadFile = docs.RootFolder.Files.Add(flciNewFile);

                ctx.Load(uploadFile);
                ctx.ExecuteQueryWithIncrementalRetry(10, 30);
            }
        }

        public Microsoft.SharePoint.Client.File UploadFileSlicePerSlice(ClientContext ctx, string libraryName, string localFilePath, string destFileName, int fileChunkSizeInMB = 3)
        {
            // Each sliced upload requires a unique id
            Guid uploadId = Guid.NewGuid();

            // Get to folder to upload into 
            List docs = ctx.Web.Lists.GetByTitle(libraryName);
            ctx.Load(docs, l => l.RootFolder);
            // Get the information about the folder that will hold the file
            ctx.Load(docs.RootFolder, f => f.ServerRelativeUrl);
            ctx.ExecuteQueryWithIncrementalRetry(10, 30);

            // File object 
            Microsoft.SharePoint.Client.File uploadFile;

            // Calculate block size in bytes
            int blockSize = fileChunkSizeInMB * 1024 * 1024;

            // Get the size of the file
            long fileSize = new FileInfo(localFilePath).Length;

            if (fileSize <= blockSize)
            {
                // Use regular approach
                using (FileStream fs = new FileStream(localFilePath, FileMode.Open))
                {
                    FileCreationInformation fileInfo = new FileCreationInformation();
                    fileInfo.ContentStream = fs;
                    fileInfo.Url = destFileName;
                    fileInfo.Overwrite = true;
                    uploadFile = docs.RootFolder.Files.Add(fileInfo);
                    ctx.Load(uploadFile);
                    ctx.ExecuteQueryWithIncrementalRetry(10, 30);
                    // return the file object for the uploaded file
                    return uploadFile;
                }
            }
            else
            {
                // Use large file upload approach
                ClientResult<long> bytesUploaded = null;

                FileStream fs = null;
                try
                {
                    fs = System.IO.File.Open(localFilePath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite);
                    using (BinaryReader br = new BinaryReader(fs))
                    {
                        byte[] buffer = new byte[blockSize];
                        long fileoffset = 0;
                        long totalBytesRead = 0;
                        int bytesRead;
                        bool first = true;

                        // Read data from filesystem in blocks 
                        while ((bytesRead = br.Read(buffer, 0, buffer.Length)) > 0)
                        {
                            if (bytesUploaded != null)
                            {
                                System.Console.ForegroundColor = ConsoleColor.Yellow;
                                System.Console.WriteLine($"{bytesUploaded.Value} bytes uploaded");
                            }

                            totalBytesRead = totalBytesRead + bytesRead;

                            if (first)
                            {
                                using (MemoryStream contentStream = new MemoryStream())
                                {
                                    // Add an empty file.
                                    FileCreationInformation fileInfo = new FileCreationInformation();
                                    fileInfo.ContentStream = contentStream;
                                    fileInfo.Url = destFileName;
                                    fileInfo.Overwrite = true;
                                    uploadFile = docs.RootFolder.Files.Add(fileInfo);

                                    // Start upload by uploading the first slice. 
                                    using (MemoryStream s = new MemoryStream(buffer))
                                    {
                                        // Call the start upload method on the first slice
                                        bytesUploaded = uploadFile.StartUpload(uploadId, s);
                                        ctx.ExecuteQueryWithIncrementalRetry(10, 30);
                                        // fileoffset is the pointer where the next slice will be added
                                        fileoffset = bytesUploaded.Value;
                                    }

                                    // we can only start the upload once
                                    first = false;
                                }
                            }
                            else
                            {
                                // Get a reference to our file
                                uploadFile = ctx.Web.GetFileByServerRelativeUrl(docs.RootFolder.ServerRelativeUrl + System.IO.Path.AltDirectorySeparatorChar + destFileName);

                                if (totalBytesRead == fileSize)
                                {
                                    // We've reached the end of the file
                                    using (MemoryStream s = new MemoryStream(buffer, 0, bytesRead))
                                    {
                                        // End sliced upload by calling FinishUpload
                                        uploadFile = uploadFile.FinishUpload(uploadId, fileoffset, s);
                                        ctx.ExecuteQueryWithIncrementalRetry(10, 30);

                                        // return the file object for the uploaded file
                                        return uploadFile;
                                    }
                                }
                                else
                                {
                                    using (MemoryStream s = new MemoryStream(buffer))
                                    {
                                        // Continue sliced upload
                                        bytesUploaded = uploadFile.ContinueUpload(uploadId, fileoffset, s);
                                        ctx.ExecuteQueryWithIncrementalRetry(10, 30);
                                        // update fileoffset for the next slice
                                        fileoffset = bytesUploaded.Value;
                                    }
                                }
                            }

                        } // while ((bytesRead = br.Read(buffer, 0, buffer.Length)) > 0)
                    }
                }
                finally
                {
                    if (fs != null)
                    {
                        fs.Dispose();
                    }
                }
            }

            return null;
        }


        public static void Run()
        {
            var newCodeExample = new CSOMLargeFileUpload();
        }
    }
}
