using System;
using System.Collections.Generic;
using System.Linq;
using System.Security;
using System.Text;
using System.Threading.Tasks;
using Microsoft.SharePoint.Client;
using PnP.Framework;
using SP.Powershell.Helper;

namespace ConsoleApp1
{
    class TestApp
    {
        static void Main(string[] args)
        {
            SecureString theSecureString = new System.Net.NetworkCredential("", "a9fw4U3h2T").SecurePassword;
            var authManager = new AuthenticationManager("admin@M365x731247.onmicrosoft.com", theSecureString);

            using (var context = authManager.GetContext("https://m365x731247.sharepoint.com/teams/test-site-28/1-C/1-C-2"))
            {
                List list = context.Site.RootWeb.GetListByTitle("Documents");
                var items = SP.Powershell.Helper.SPPSHelper.GetListItems(list, 1);
            }
        }
    }
}
