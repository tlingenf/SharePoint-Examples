using System;
using Microsoft.SharePoint.Client;
using System.Linq;

namespace SP.Powershell.Helper
{
    public static class SPPSHelper
    {
        public static System.Collections.Generic.List<ListItem> GetListItems(Microsoft.SharePoint.Client.List list, int batchSize)
        {
            System.Collections.Generic.List<ListItem> returnListItems = new System.Collections.Generic.List<ListItem>();

            var query = new Microsoft.SharePoint.Client.CamlQuery();
            query.ViewXml = string.Format("<View Scope='RecursiveAll'><RowLimit>{0}(</RowLimit></View>", batchSize);

            do
            {
                var batchListItems = list.GetItems(query);
                list.Context.Load(batchListItems, i => i.Include(
                    item => item.HasUniqueRoleAssignments, 
                    item => item.Id),
                    items => items.ListItemCollectionPosition
                );
                list.Context.ExecuteQuery();
                returnListItems.AddRange(batchListItems.Where(item => item.HasUniqueRoleAssignments));
                query.ListItemCollectionPosition = batchListItems.ListItemCollectionPosition;
            } while (query.ListItemCollectionPosition != null);

            return returnListItems;
        }
    }
}