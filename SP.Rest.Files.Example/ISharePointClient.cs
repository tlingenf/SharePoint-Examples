using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;

namespace SPExamples.Rest.Netcore
{
    public interface ISharePointClient
    {
        Task<string> GetListItemAsync(string siteId, string listId, string itemId);

        Task<string> UploadFileAsync(string siteId, string localFilePath, string folderId, string filename);

        Task<string> CheckInFileAsync(string siteId, string fileId, string comment);

        Task<string> CheckOutFileAsync(string siteId, string fileId, string comment);

        Task<string> GetFileProperties(string siteId, string fileId);

        Task<bool> FileExistsAsync(string siteId, string fileId);

        Task<string> SetListItemAsync(string siteId, string listId, string itemId, Dictionary<string, string> values);
    }
}
