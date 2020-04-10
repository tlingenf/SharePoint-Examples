using Microsoft.Extensions.Configuration;
using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace SPExamples.Rest.Netcore
{
    public class SpRestClient : HttpClient, ISharePointClient
    {
        private IConfiguration _configuration;
        private int _chunkSize = 0;
        private string _requestDigest;

        public SpRestClient(IConfiguration configuration, string accessToken): base ()
        {
            this.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
            this.DefaultRequestHeaders.TryAddWithoutValidation("Accept", "application/json;odata=verbose");
            _configuration = configuration;
            _chunkSize = Convert.ToInt32(configuration["UploadBufferSizeMB"]) * 1024 * 1024;
        }

        public async Task<string> GetListItemAsync(string siteId, string listId, string itemId)
        {
            var response = await this.GetAsync($"{siteId}/_api/web/lists/getbytitle('{listId}')/items({itemId})");
            return await response.Content.ReadAsStringAsync();
        }

        public async Task<string> UploadFileAsync(string siteId, string localFilePath, string folderId, string filename)
        {
            string result = null;

            // chunking only works if the file exists
            if (await this.FileExistsAsync(siteId, $"{folderId}/{filename}") == false)
            {
                // file does not exist, chunked upload methods require a file to already exist, create empty file
                await this.CreateEmptyFileAsync(siteId, folderId, filename);
            }
            
            result = await this.UploadFileChunkAsync(siteId, localFilePath, folderId, filename);

            return await this.GetFileProperties(siteId, $"{folderId}/{filename}");
        }

        private async Task CreateEmptyFileAsync(string siteId, string folderId, string filename)
        {
            string requestDigest = await this.GetRequestDigest(siteId);
            HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, $"{siteId}/_api/web/getfolderbyserverrelativeurl('{folderId}')/files/add(url='{filename}',overwrite=false)");
            request.Headers.Add("X-RequestDigest", requestDigest);
            request.Content = new StringContent("placeholder text");
            var response = await this.SendAsync(request);
        }

        private async Task<string> UploadFileChunkAsync(string siteId, string localFilePath, string folderId, string filename)
        {
            Guid uploadJobId = Guid.NewGuid();
            string requestDigest = await this.GetRequestDigest(siteId);
            var offset = 0L;
            var firstChunk = true;
            HttpRequestMessage request;
            HttpResponseMessage response = null;

            using (var inputStream = System.IO.File.OpenRead(localFilePath))
            {
                var buffer = new byte[_chunkSize];
                int bytesRead;
                while ((bytesRead = inputStream.Read(buffer, 0, buffer.Length)) > 0)
                {
                    if (firstChunk)
                    {
                        // https://docs.microsoft.com/en-us/previous-versions/office/developer/sharepoint-rest-reference/dn450841(v=office.15)?redirectedfrom=MSDN#startupload-method

                        request = new HttpRequestMessage(HttpMethod.Post, $"{siteId}/_api/web/getfilebyserverrelativeurl('{folderId}/{filename}')/startupload(uploadId=guid'{uploadJobId}')");
                        request.Headers.Add("X-RequestDigest", requestDigest);
                        request.Content = new ByteArrayContent(buffer);
                        response = await this.SendAsync(request);
                        firstChunk = false;
                    }
                    else if (inputStream.Position == inputStream.Length)
                    {
                        request = new HttpRequestMessage(HttpMethod.Post, $"{siteId}/_api/web/getfilebyserverrelativeurl('{folderId}/{filename}')/finishupload(uploadId=guid'{uploadJobId}',fileOffset={offset})");
                        request.Headers.Add("X-RequestDigest", requestDigest);
                        var finalBuffer = new byte[bytesRead];
                        Array.Copy(buffer, finalBuffer, finalBuffer.Length);
                        request.Content = new ByteArrayContent(finalBuffer);
                        response = await this.SendAsync(request);
                    }
                    else
                    {
                        request = new HttpRequestMessage(HttpMethod.Post, $"{siteId}/_api/web/getfilebyserverrelativeurl('{folderId}/{filename}')/continueupload(uploadId=guid'{uploadJobId}',fileOffset={offset})");
                        request.Headers.Add("X-RequestDigest", requestDigest);
                        request.Content = new ByteArrayContent(buffer);
                        response = await this.SendAsync(request);
                    }

                    if (response.StatusCode != HttpStatusCode.OK)
                        throw new HttpRequestException("Unable to upload file.");

                    offset += bytesRead;
                    Console.WriteLine("{0:P} completed", (((float)offset / (float)inputStream.Length)));
                }
            }

            return await response?.Content.ReadAsStringAsync();
        }

        public async Task<string> GetFileProperties(string siteId, string fileId)
        {
            var response = await this.GetAsync($"{siteId}/_api/web/getfilebyserverrelativeurl('{fileId}')/ListItemAllFields");
            return await response.Content.ReadAsStringAsync();
        }

        public async Task<string> SetListItemAsync(string siteId, string listId, string itemId, Dictionary<string, string> values)
        {
            var itemPropsString = await this.GetListItemAsync(siteId, listId, itemId);
            var jObject = JObject.Parse(itemPropsString);
            var requestDigest = await this.GetRequestDigest(siteId);

            StringBuilder jsonbody = new StringBuilder();
            jsonbody.Append("{ \"__metadata\": { \"type\": \"");
            jsonbody.Append(jObject["d"]["__metadata"]["type"]);
            jsonbody.Append("\"}, ");

            for (int j = 0; j < values.Count(); j++)
            {
                jsonbody.Append(await FieldValueFactory.FormatJsonValue(this, siteId, listId, values.ElementAt(j).Key, values.ElementAt(j).Value));
                if (j < values.Count() - 1)
                {
                    jsonbody.Append(", ");
                }
            }

            jsonbody.Append("}");

            var request = new HttpRequestMessage(HttpMethod.Post, $"{siteId}/_api/web/lists/getbytitle('{listId}')/items({itemId})");
            request.Headers.Add("X-RequestDigest", requestDigest); // protection against scripting attacks
            request.Headers.Add("IF-MATCH", jObject["d"]["__metadata"]["etag"].ToString()); // concurrency control
            request.Headers.Add("X-HTTP-Method", "MERGE");
            request.Content = new StringContent(jsonbody.ToString());
            request.Content.Headers.Clear();
            request.Content.Headers.TryAddWithoutValidation("Content-Type", "application/json;odata=verbose");
            var response = await this.SendAsync(request);
            return await response.Content.ReadAsStringAsync();
        }

        public async Task<bool> IsCheckOutRequired(string siteId, string listId)
        {
            var response = await this.GetAsync($"{siteId}/_api/web/lists/getbytitle('{listId}')?$select=ForceCheckout");
            var jObject = JObject.Parse(await response.Content.ReadAsStringAsync());
            return bool.Parse(jObject["d"]["ForceCheckout"].ToString());
        }

        public async Task<string> CheckInFileAsync(string siteId, string fileId, string comment)
        {
            var filePropsString = await this.GetFileProperties(siteId, fileId);
            var jObject = JObject.Parse(filePropsString);
            var requestDigest = await this.GetRequestDigest(siteId);
            var request = new HttpRequestMessage(HttpMethod.Post, $"{siteId}/_api/web/getfilebyserverrelativeurl('{fileId}')/CheckIn(comment='{comment}', checkintype=0)");
            request.Headers.Add("X-RequestDigest", requestDigest); // protection against scripting attacks
            request.Headers.Add("IF-MATCH", jObject["d"]["__metadata"]["etag"].ToString()); // concurrency control
            var response = await this.SendAsync(request);
            return await response.Content.ReadAsStringAsync();
        }

        public async Task<string> CheckOutFileAsync(string siteId, string fileId, string comment)
        {
            var filePropsString = await this.GetFileProperties(siteId, fileId);
            var jObject = JObject.Parse(filePropsString);
            var requestDigest = await this.GetRequestDigest(siteId);
            var request = new HttpRequestMessage(HttpMethod.Post, $"{siteId}/_api/web/getfilebyserverrelativeurl('{fileId}')/CheckOut()");
            request.Headers.Add("X-RequestDigest", requestDigest); // protection against scripting attacks
            request.Headers.Add("IF-MATCH", jObject["d"]["__metadata"]["etag"].ToString()); // concurrency control
            var response = await this.SendAsync(request);
            return await response.Content.ReadAsStringAsync();
        }

        public async Task<bool> FileExistsAsync(string siteId, string fileId)
        {
            bool isSuccess = false;
            try
            {
                var response = await this.GetAsync($"{siteId}/_api/web/getfilebyserverrelativeurl('{fileId}')");
                isSuccess = true;

                if (response.StatusCode == HttpStatusCode.NotFound)
                    isSuccess = false;
                else
                    throw new Exception("Not Found");
            }
            catch (Exception ex)
            {
                throw;
            }
            return isSuccess;
        }

        private async Task<string> GetRequestDigest(string siteUrl)
        {
            if (string.IsNullOrEmpty(siteUrl))
                throw new ArgumentNullException(nameof(siteUrl));

            // note: this code assumes the request digetst is still valid and does not handle expired values
            if (string.IsNullOrEmpty(_requestDigest))
            {
                HttpRequestMessage request = new HttpRequestMessage();
                request.Method = HttpMethod.Post;
                request.RequestUri = new Uri($"{siteUrl}/_api/contextinfo");
                var response = await this.SendAsync(request);

                if (response.StatusCode == HttpStatusCode.OK)
                {
                    var jobject = JObject.Parse(await response.Content.ReadAsStringAsync());
                    _requestDigest = jobject["d"]["GetContextWebInformation"]["FormDigestValue"].ToString();
                }
            }

            return _requestDigest;
        }

    }
}
