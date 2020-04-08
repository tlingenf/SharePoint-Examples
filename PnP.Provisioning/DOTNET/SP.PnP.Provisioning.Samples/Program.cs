using Microsoft.Identity.Client;
using OfficeDevPnP.Core.Framework.Provisioning.Model;
using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Threading.Tasks;

namespace SP.PnP.Templates
{
    class Program
    {
        static void Main(string[] args)
        {
            MainAsync(args).Wait();
        }

        static async Task MainAsync(string[] args)
        {
            string sourceSiteUrl = args[0];
            string destSiteUrl = args[1];

            if (string.IsNullOrEmpty(sourceSiteUrl))
                throw new ArgumentNullException("argument1");

            if (string.IsNullOrEmpty(sourceSiteUrl))
                throw new ArgumentNullException("argument2");


            var certificate = new X509Certificate2(System.IO.Path.Combine(AppContext.BaseDirectory, ConfigurationManager.AppSettings["pfxPath"] as string), ConfigurationManager.AppSettings["pfxPass"] as string);
            IConfidentialClientApplication app = ConfidentialClientApplicationBuilder
                .Create(ConfigurationManager.AppSettings["clientId"] as string)
                .WithCertificate(certificate)
                .WithTenantId(ConfigurationManager.AppSettings["tenantId"] as string)
                .Build();

            Uri sourceUri = new Uri(sourceSiteUrl);
            AuthenticationResult auth = await app.AcquireTokenForClient(new string[] { $"https://{sourceUri.Host}/.default" }).ExecuteAsync();

            string resourceFolder;
            ProvisioningTemplate template = ProvisioningHelper.GetProvisioningTemplate(sourceSiteUrl, auth.AccessToken, out resourceFolder);
            ProvisioningHelper.ApplyProvisioningTemplate(destSiteUrl, template, resourceFolder, auth.AccessToken);
        }
    }
}
