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

            ExecuteSpRest().Wait();

            //Console.WriteLine("Press any key to continue ...");
            //Console.ReadKey();
        }

        static async Task ExecuteSpRest()
        {
            // SharePoint API Access Token
            Console.WriteLine("Logging in to the SharePoint API.");
            List<string> spScopes = new List<string>
            {
                $"https://{configuration["SharePointHostName"]}/.default"
            };
            var spAccessToken = await InteractiveLogin(spScopes);

            var spclient = new SpRestClient(configuration, spAccessToken);

            Console.Write("GetListItemAsysnc");
            Console.WriteLine(await spclient.GetListItemAsync("https://m365x612691.sharepoint.com/sites/ClassicSPRecords", "Documents", "3"));

            Console.WriteLine("");
            Console.Write("UploadFileAsync");
            var uploadResponse = await spclient.UploadFileAsync("https://m365x612691.sharepoint.com/sites/ClassicSPRecords", Path.Combine(AppContext.BaseDirectory, "SP2013_LargeFile.pptx"), "/sites/ClassicSPRecords/Documents", $"myfile_{RandomString(6)}.pptx");
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
            var updateResponse = await spclient.SetListItemAsync("https://m365x612691.sharepoint.com/sites/ClassicSPRecords", "Documents", uploadOjbect["d"]["ID"].ToString(), values);
            Console.WriteLine(updateResponse);

            Console.Write("CheckIn");
            var checkInResponse = await spclient.CheckInFileAsync("https://m365x612691.sharepoint.com/sites/ClassicSPRecords", $"{folderId}/{filename}", "checked in using REST");
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
