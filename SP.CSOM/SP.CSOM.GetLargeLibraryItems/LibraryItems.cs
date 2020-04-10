/*##########################################################################################################
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
##########################################################################################################*/

using Microsoft.SharePoint.Client;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;
using File = Microsoft.SharePoint.Client.File;

namespace ODfBSyncCSOM
{
    public class LibraryItems
    {
        public void GetAllLibraryItems(string siteUrl, SharePointOnlineCredentials credential, string listName)
        {
            const int batchSize = 5;

            using (ClientContext ctx = new ClientContext(siteUrl))
            {
                ctx.Credentials = credential;

                var web = ctx.Web;
                ctx.Load(web);
                ctx.ExecuteQuery();

                var docLib = web.Lists.GetByTitle(listName);
                ctx.Load(docLib);
                ctx.ExecuteQuery();

                var listQuery = new CamlQuery();
                listQuery.ViewXml = string.Format("<View Scope='RecursiveAll'><Query><OrderBy><FieldRef Name='ID' Ascending='TRUE'/></OrderBy></Query><RowLimit Paged='TRUE'>{0}</RowLimit></View>", batchSize);

                do
                {
                    var items = docLib.GetItems(listQuery);
                    ctx.Load(items);
                    ctx.ExecuteQuery();
                    listQuery.ListItemCollectionPosition = items.ListItemCollectionPosition;
                    GetQueryFiles(items, ctx, Path.GetTempPath());
                }
                while (listQuery.ListItemCollectionPosition != null);
            }
        }

        private void GetQueryFiles(ListItemCollection items, ClientContext ctx, string destFolder)
        {
            foreach (ListItem item in items)
            {
                var fileInfo = File.OpenBinaryDirect(ctx, item.File.ServerRelativeUrl);
                var fsPath = Path.Combine(destFolder, item.File.Name);
                using (var fileStream = System.IO.File.Create(fsPath))
                {
                    fileInfo.Stream.CopyTo(fileStream);
                }
            }
        }
    }
}
