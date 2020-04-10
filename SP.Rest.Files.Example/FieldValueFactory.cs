using Newtonsoft.Json.Linq;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Text;
using System.Threading.Tasks;

namespace SPExamples.Rest.Netcore
{
    public static class FieldValueFactory
    {
        public static async Task<string> FormatJsonValue(HttpClient httpClient, string siteId, string listId, string fieldName, string fieldValue)
        {
            try
            {
                var response = await httpClient.GetAsync($"{siteId}/_api/web/lists/getbytitle('{listId}')/Fields/getbytitle('{fieldName}')");
                var fieldDefJson = JObject.Parse(await response.Content.ReadAsStringAsync());

                switch (fieldDefJson["d"]["TypeAsString"].ToString())
                {
                    case "MultiChoice":
                        return FormatMultiChoiceValue(fieldDefJson, fieldValue);
                        break;

                    case "Number":
                        return FormatNumberValue(fieldDefJson, fieldValue);
                        break;

                    default:
                        return FormatSingleLineTextValue(fieldDefJson, fieldValue);
                }
            }
            catch (Exception ex)
            {
                return null;
            }
        }

        private static string FormatSingleLineTextValue(JObject fieldDefJson, string fieldValue)
        {
            return $"\"{fieldDefJson["d"]["StaticName"].ToString()}\": \"{fieldValue}\"";
        }

        private static string FormatNumberValue(JObject fieldDefJson, string fieldValue)
        {
            return $"\"{fieldDefJson["d"]["StaticName"].ToString()}\": {fieldValue}";
        }

        private static string FormatMultiChoiceValue(JObject fieldDefJson, string fieldValue)
        {
            string[] values = fieldValue.Split(new string[] { ",", ";", "#;" }, StringSplitOptions.RemoveEmptyEntries);
            if (values.Length > 1)
            {
                for (int i = 0; i < values.Length; i++)
                {
                    values[i] = string.Concat('"', values[i], '"');
                }
                return $"\"{fieldDefJson["d"]["StaticName"]}\": {{ \"__metadata\": {{ \"type\" : \"Collection(Edm.String)\" }}, \"results\": [ {string.Join(", ", values)} ] }}";
            }
            else
            {
                return FormatSingleLineTextValue(fieldDefJson, fieldValue);
            }
        }
    }
}
