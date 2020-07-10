using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace SPExamples.Rest.Netcore
{
    class GraphRestClient : HttpClient, ISharePointClient
    {
        private IConfiguration _configuration;

        public GraphRestClient(IConfiguration configuration, string accessToken) : base()
        {
            this.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
            this.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
            _configuration = configuration;
        }

        public Task<string> CheckInFileAsync(string siteId, string fileId, string comment)
        {
            throw new NotImplementedException();
        }

        public Task<string> CheckOutFileAsync(string siteId, string fileId, string comment)
        {
            throw new NotImplementedException();
        }

        public Task<bool> FileExistsAsync(string siteId, string fileId)
        {
            throw new NotImplementedException();
        }

        public Task<string> GetFileProperties(string siteId, string fileId)
        {
            throw new NotImplementedException();
        }

        public Task<string> GetListItemAsync(string siteId, string listId, string itemId)
        {
            throw new NotImplementedException();
        }

        public Task<string> SetListItemAsync(string siteId, string listId, string itemId, Dictionary<string, string> values)
        {
            throw new NotImplementedException();
        }

        public async Task<string> UploadFileAsync(string siteId, string localFilePath, string folderId, string filename)
        {
            var nameValue = "";
            var requestContent = new StringContent("{ \"item\": { \"@microsoft.graph.conflictBehavior\": \"rename\" } }", Encoding.UTF8, "application/json");
            var response = await this.PostAsync($"https://graph.microsoft.com/v1.0/drives/b!tRxIgIpErUCerPpxiXd25J2k1pOlLe9Kia6QDzpUS5H3y3NZEMC3TpbK2cppmZ1X/items/01FJYWQCKBTHKTTXYNGVGICMO2X3D75VCO/createUploadSession", requestContent);
            var responseContent = await response.Content.ReadAsStringAsync();
            return responseContent;
        }
    }
}
