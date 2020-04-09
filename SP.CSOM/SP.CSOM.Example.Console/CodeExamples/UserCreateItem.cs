using Microsoft.SharePoint.Client;
using OfficeDevPnP.Core;
using System;
using System.Collections.Generic;
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
    class UserCreateItem
    {
        public UserCreateItem()
        {
            var authManager = new AuthenticationManager();
            using (var ctx = authManager.GetWebLoginClientContext("https://tenant.sharepoint.com/sites/destSiteUrl"))
            {
                var user = ctx.Web.CurrentUser;
                ctx.Load(user);
                ctx.ExecuteQuery();
                var list = ctx.Web.Lists.GetByTitle("User Updates");
                var newItem = list.AddItem(new Microsoft.SharePoint.Client.ListItemCreationInformation());
                var dateStamp = DateTime.Now.ToString("MM-dd-yyyyThh-mm-ss");
                newItem["Title"] = $"Created at {dateStamp}";
                newItem["User"] = new[] { new FieldUserValue() { LookupId = user.Id } };
                newItem.Update();
                ctx.ExecuteQuery();
            }
        }

        public static void Run()
        {
            var newCodeExample = new UserCreateItem();

        }
    }
}
