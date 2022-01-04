using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Identity.Client;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace SPExamples.Rest.Netcore
{
    class Program
    {
        public static IConfigurationRoot configuration;

        static void Main(string[] args)
        {
            ConfigureAppAsync(args).Wait();

            if (args[0].ToLower() == "-graph")
            {
                //ExecuteGraphRest().Wait();
                DownloadFile().Wait();
            }
            else
            {
                ExecuteSpRest().Wait();
            }
        }

        static async Task DownloadFile()
        {
            var spSiteUrl = configuration["SharePointSiteUrl"] as string;
            var spDocLib = configuration["DocumentLibraryName"] as string;
            var spSiteUri = new Uri(spSiteUrl);

            // SharePoint API Access Token
            Console.WriteLine("Logging in to the SharePoint API.");
            List<string> spScopes = new List<string>
            {
                $"https://{spSiteUri.Host}/.default"
            };
            var spAccessToken = await InteractiveLogin(spScopes);

            var spclient = new SpRestClient(configuration, spAccessToken);

            await spclient.DownloadFileChunkAsync(spSiteUrl, "temp.pptx", "Shared%20Documents/SP2013_LargeFile.pptx");
        }

        static async Task ExecuteSpRest()
        {
            var spSiteUrl = configuration["SharePointSiteUrl"] as string;
            var spDocLib = configuration["DocumentLibraryName"] as string;
            var spSiteUri = new Uri(spSiteUrl);

            // SharePoint API Access Token
            Console.WriteLine("Logging in to the SharePoint API.");
            List<string> spScopes = new List<string>
            {
                $"https://{spSiteUri.Host}/.default"
            };
            var spAccessToken = await InteractiveLogin(spScopes);

            var spclient = new SpRestClient(configuration, spAccessToken);

            Console.Write("GetListItemAsysnc");
            Console.WriteLine(await spclient.GetListItemAsync(spSiteUrl, "Documents", "3"));

            var newFileName = $"myfile_{RandomString(6)}.pptx";

            Console.WriteLine("");
            Console.Write("UploadFileAsync");
            var uploadResponse = await spclient.UploadFileAsync(spSiteUrl, Path.Combine(AppContext.BaseDirectory, "SP2013_LargeFile.pptx"), $"{spSiteUri.AbsolutePath}/{spDocLib}", newFileName);
            var uploadOjbect = JObject.Parse(uploadResponse);
            Console.WriteLine(uploadResponse);

            Console.WriteLine("");
            Console.Write("SetListItemAsync");
            Dictionary<string, string> values = new Dictionary<string, string>
            {
                { "Number Field", "42" },
                { "Text Field", "here is some text" },
                { "Multi-Choice Field", "Choice 1,Choice 4" }
            };
            var updateResponse = await spclient.SetListItemAsync(spSiteUrl, spDocLib, uploadOjbect["d"]["ID"].ToString(), values);
            Console.WriteLine(updateResponse);

            Console.Write("CheckIn");
            var checkInResponse = await spclient.CheckInFileAsync(spSiteUrl, $"{spSiteUri.AbsolutePath}/{spDocLib}/{newFileName}", "checked in using REST");
        }

        static async Task ExecuteGraphRest()
        {
            var spSiteUrl = configuration["SharePointSiteUrl"] as string;
            var spDocLib = configuration["DocumentLibraryName"] as string;
            var spSiteUri = new Uri(spSiteUrl);
            var newFileName = $"myfile_{RandomString(6)}.pptx";

            // SharePoint API Access Token
            Console.WriteLine("Logging in to the Graph API.");
            List<string> spScopes = new List<string>
            {
                $"https://graph.microsoft.com/.default"
            };
            var spAccessToken = await InteractiveLogin(spScopes);

            var graphclient = new GraphRestClient(configuration, spAccessToken);
            var uploadResult = await graphclient.UploadFileAsync(
                $"{spSiteUri.Host}:{spSiteUri.AbsolutePath}",
                Path.Combine(AppContext.BaseDirectory, "SP2013_LargeFile.pptx"),
                spDocLib,
                newFileName);

        }

        public static async Task<string> InteractiveLogin(IEnumerable<string> scopes)
        {
            IPublicClientApplication app = PublicClientApplicationBuilder
                .Create(configuration["appId"])
                .WithTenantId(configuration["tenantId"])
                .WithRedirectUri("http://localhost")
                .Build();

            AuthenticationResult auth = await app.AcquireTokenInteractive(scopes)
                .ExecuteAsync();

            return auth.AccessToken;
        }


        static async Task ConfigureAppAsync(string[] args)
        {
            configuration = new ConfigurationBuilder()
                .SetBasePath(Directory.GetParent(AppContext.BaseDirectory).FullName)
                .AddJsonFile("appsettings.json", false)
                .AddJsonFile("appSettings.json.user", true)
                .Build();
        }

        private static Random random = new Random();
        public static string RandomString(int length)
        {
            const string chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
            return new string(Enumerable.Repeat(chars, length)
              .Select(s => s[random.Next(s.Length)]).ToArray());
        }
    }
}
