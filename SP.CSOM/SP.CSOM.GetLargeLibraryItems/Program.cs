using Microsoft.SharePoint.Client;
using System;
using System.Security;

namespace ODfBSyncCSOM
{
    class Program
    {
        static void Main(string[] args)
        {
            LibraryItems li = new LibraryItems();

            var securePassword = new SecureString();
            foreach (char c in "z@aaaaaaaaaaaa")
            {
                securePassword.AppendChar(c);
            }

            var cred = new SharePointOnlineCredentials("user@domain.com", securePassword);

            li.GetAllLibraryItems("https://tenant-my.sharepoint.com/personal/user_domain_com", cred, "Documents");
        }
    }
}
