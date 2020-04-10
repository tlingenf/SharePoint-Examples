using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.Taxonomy;
using OfficeDevPnP.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace SP.MMSTest
{
    class Program
    {
        static void Main(string[] args)
        {
            AuthenticationManager authman = new AuthenticationManager();
            using (var ctx = authman.GetWebLoginClientContext("https://trlingen.sharepoint.com"))
            {
                try
                {
                    TaxonomySession taxonomySession = TaxonomySession.GetTaxonomySession(ctx);
                    TermStore termStore = taxonomySession.GetDefaultKeywordsTermStore();
                    ctx.Load(termStore);
                    var termGroups = ctx.LoadQuery(termStore.Groups.Where(x => !x.IsSiteCollectionGroup && !x.IsSystemGroup && x.Name != "People" && x.Name != "Search Dictionaries").Include(
                        tg => tg.Description,
                        tg => tg.Id,
                        tg => tg.Name,
                        tg => tg.TermSets.Include(
                            ts => ts.CustomSortOrder,
                            ts => ts.Description,
                            ts => ts.Id,
                            ts => ts.IsAvailableForTagging,
                            ts => ts.IsOpenForTermCreation,
                            ts => ts.Name)));
                    ctx.ExecuteQuery();
                }
                catch (Exception ex)
                {

                }
            }
        }
    }
}
