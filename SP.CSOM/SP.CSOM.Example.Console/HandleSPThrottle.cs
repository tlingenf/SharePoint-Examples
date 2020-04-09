using Microsoft.SharePoint.Client;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
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

// This code sample was obtained from: https://docs.microsoft.com/en-us/sharepoint/dev/general-development/how-to-avoid-getting-throttled-or-blocked-in-sharepoint-online#how-to-decorate-your-http-traffic-to-avoid-throttling

namespace SPExamples.Console
{
    static class HandleSPThrottle
    {
        public static void ExecuteQueryWithIncrementalRetry(this ClientContext clientContext, int retryCount, int delay)
        {
            int retryAttempts = 0;
            int backoffInterval = delay;
            int retryAfterInterval = 0;
            bool retry = false;
            ClientRequestWrapper wrapper = null;
            if (retryCount <= 0)
                throw new ArgumentException("Provide a retry count greater than zero.");
            if (delay <= 0)
                throw new ArgumentException("Provide a delay greater than zero.");

            // Do while retry attempt is less than retry count
            while (retryAttempts < retryCount)
            {
                try
                {
                    if (!retry)
                    {
                        clientContext.ExecuteQuery();
                        return;
                    }
                    else
                    {
                        // retry the previous request
                        if (wrapper != null && wrapper.Value != null)
                        {
                            clientContext.RetryQuery(wrapper.Value);
                            return;
                        }
                    }
                }
                catch (WebException ex)
                {
                    var response = ex.Response as HttpWebResponse;
                    // Check if request was throttled - http status code 429
                    // Check is request failed due to server unavailable - http status code 503
                    if (response != null && (response.StatusCode == (HttpStatusCode)429 || response.StatusCode == (HttpStatusCode)503))
                    {
                        wrapper = (ClientRequestWrapper)ex.Data["ClientRequest"];
                        retry = true;

                        // Determine the retry after value - use the retry-after header when available
                        string retryAfterHeader = response.GetResponseHeader("Retry-After");
                        if (!string.IsNullOrEmpty(retryAfterHeader))
                        {
                            if (!Int32.TryParse(retryAfterHeader, out retryAfterInterval))
                            {
                                retryAfterInterval = backoffInterval;
                            }
                        }
                        else
                        {
                            retryAfterInterval = backoffInterval;
                        }

                        // Delay for the requested seconds
                        Thread.Sleep(retryAfterInterval * 1000);

                        // Increase counters
                        retryAttempts++;
                        backoffInterval = backoffInterval * 2;
                    }
                    else
                    {
                        throw;
                    }
                }
            }
            throw new MaximumRetryAttemptedException($"Maximum retry attempts {retryCount}, has be attempted.");
        }

        [Serializable]
        public class MaximumRetryAttemptedException : Exception
        {
            public MaximumRetryAttemptedException(string message) : base(message) { }
        }
    }
}
