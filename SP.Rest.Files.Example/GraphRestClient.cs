using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;

namespace SPExamples.Rest.Netcore
{
    class GraphRestClient : HttpClient
    {
        public GraphRestClient(string accessToken) : base()
        {
            this.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", accessToken);
            this.DefaultRequestHeaders.Accept.Add(new System.Net.Http.Headers.MediaTypeWithQualityHeaderValue("application/json"));
        }
    }
}
