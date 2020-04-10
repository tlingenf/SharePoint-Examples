using OfficeDevPnP.Core;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Xml;
using System.Xml.Linq;

namespace ContentTypeAttach
{
    class Program
    {
        static void Main(string[] args)
        {
            AuthenticationManager authMan = new AuthenticationManager();
            using (var ctx = authMan.GetWebLoginClientContext("https://xxxxxxxxxx.sharepoint.com/sites/demo2"))
            {
                var folderCt = ctx.Web.ContentTypes.GetById("0x0120");
                ctx.Load(folderCt);
                ctx.ExecuteQuery();
                folderCt.Sealed = false;
                folderCt.Update(false);
                ctx.ExecuteQuery();

                ctx.Load(folderCt, f => f.SchemaXmlWithResourceTokens);
                ctx.ExecuteQuery();

                //XmlDocument xDoc = new XmlDocument();
                //xDoc.LoadXml(folderCt.SchemaXmlWithResourceTokens);
                //var docElem = xDoc.GetElementsByTagName("XmlDocuments");

                //XDocument schemaXml = XDocument.Parse(docElem[0].OuterXml);
                XDocument schemaXml = XDocument.Parse(folderCt.SchemaXmlWithResourceTokens);
                //XDocument receiverXml = XDocument.Parse(@"
                //    <XmlDocuments>
                //        <XmlDocument NamespaceURI=""http://schemas.microsoft.com/sharepoint/events"">
                //            <Receivers xmlns:spe=""http://schemas.microsoft.com/sharepoint/events"">
                //                <Receiver>
                //                    <Name>RemoteEventReceiver1</Name>
                //                    <Type>ItemFileMoving</Type>
                //                    <Assembly>AllEventReceiversWeb, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null</Assembly>
                //                    <Class>AllEventReceiversWeb.Services.RemoteEventReceiver1</Class>
                //                    <SequenceNumber>1</SequenceNumber>
                //                </Receiver>
                //            </Receivers>
                //        </XmlDocument>
                //    </XmlDocuments>
                //");

                XDocument receiverXml = XDocument.Parse(@"
                <ContentType>
                    <XmlDocuments>
                        <XmlDocument NamespaceURI=""http://schemas.microsoft.com/sharepoint/events"">
                            <Receivers xmlns:spe=""http://schemas.microsoft.com/sharepoint/events"">
                                <Receiver>
                                    <Name>RemoteEventReceiver1</Name>
                                    <Type>ItemFileMoving</Type>
                                    <Assembly>AllEventReceiversWeb, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null</Assembly>
                                    <Class>AllEventReceiversWeb.Services.RemoteEventReceiver1</Class>
                                    <SequenceNumber>1</SequenceNumber>
                                </Receiver>
                            </Receivers>
                        </XmlDocument>
                    </XmlDocuments>
                </ContentType>
                ");
                var mergedDoc = schemaXml.MergeXml(receiverXml);

                folderCt.SchemaXmlWithResourceTokens = mergedDoc.ToString();
                folderCt.Update(false);
                ctx.ExecuteQuery();

                //XmlDocument doc = new XmlDocument();
                //doc.LoadXml(folderCt.SchemaXmlWithResourceTokens);
                //XmlNode nodeXmlDocuments;
                //var nodeList = doc.GetElementsByTagName("XmlDocuments");
                //if (nodeList.Count == 1)
                //{
                //    nodeXmlDocuments = nodeList[0];
                //    if (nodeXmlDocuments.HasChildNodes)
                //    {

                //    }
                //}

                Console.WriteLine("Press any key to continue ...");
                Console.ReadKey();
            }
        }
    }

    public static class Extension
    {
        public static XDocument MergeXml(this XDocument xd1, XDocument xd2)
        {
            return new XDocument(
                new XElement(xd2.Root.Name,
                    xd2.Root.Attributes()
                        .Concat(xd1.Root.Attributes())
                        .GroupBy(g => g.Name)
                        .Select(s => s.First()),
                    xd2.Root.Elements()
                        .Concat(xd1.Root.Elements())
                        .GroupBy(g => g.Name)
                        .Select(s => s.First())));


            //return new XDocument(
            //    new XElement(xd2.Root.Name,
            //        xd2.Root.Attributes()
            //            .Concat(xd1.Root.Attributes())
            //            .GroupBy(g => g.Name)
            //            .Select(s => s.First()),
            //        xd2.Root.Elements()
            //            .Concat(xd1.Root.Elements())
            //            .GroupBy(g => g.Name)
            //            .Select(s => s.First())));
        }
    }
}
