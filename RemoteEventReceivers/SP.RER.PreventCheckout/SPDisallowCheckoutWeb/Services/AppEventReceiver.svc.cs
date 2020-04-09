using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Reflection;
using System.Text;
using Microsoft.SharePoint.Client;
using Microsoft.SharePoint.Client.EventReceivers;

namespace SPDisallowCheckoutWeb.Services
{
    public class AppEventReceiver : IRemoteEventService
    {
        const string ReceiverName = "CancelCheckoutEventReceiver";

        /// <summary>
        /// Handles app events that occur after the app is installed or upgraded, or when app is being uninstalled.
        /// </summary>
        /// <param name="properties">Holds information about the app event.</param>
        /// <returns>Holds information returned from the app event.</returns>
        public SPRemoteEventResult ProcessEvent(SPRemoteEventProperties properties)
        {
            SPRemoteEventResult result = new SPRemoteEventResult();

            using (ClientContext clientContext = TokenHelper.CreateAppEventClientContext(properties, useAppWeb: false))
            {
                if (clientContext != null)
                {
                    var documentLib = clientContext.Web.Lists.GetByTitle("Documents");
                    clientContext.Load(clientContext.Web);
                    clientContext.Load(documentLib);
                    clientContext.ExecuteQuery();

                    if (properties.EventType == SPRemoteEventType.AppInstalled)
                    {
                        string remoteUrl = ConfigurationManager.AppSettings["ReceiverUri"] as string;

                        EventReceiverDefinitionCreationInformation receiverCreationInfo = new EventReceiverDefinitionCreationInformation()
                        {
                            EventType = EventReceiverType.ItemCheckingOut,
                            ReceiverAssembly = Assembly.GetExecutingAssembly().FullName,
                            ReceiverName = ReceiverName,
                            ReceiverClass = "SPDisallowCheckoutWeb.Services.CancelCheckoutEventReceiver",
                            ReceiverUrl = remoteUrl,
                            SequenceNumber = 11000
                        };

                        documentLib.EventReceivers.Add(receiverCreationInfo);
                        clientContext.ExecuteQuery();
                    }

                    if (properties.EventType == SPRemoteEventType.AppUninstalling)
                    {
                        EventReceiverDefinitionCollection eventReceivers = documentLib.EventReceivers;
                        clientContext.Load(eventReceivers);
                        clientContext.ExecuteQuery();

                        foreach (EventReceiverDefinition receiver in eventReceivers)
                        {
                            if (receiver.ReceiverName == ReceiverName)
                            {
                                receiver.DeleteObject();
                            }
                        }

                        clientContext.ExecuteQuery();
                    }
                }
            }

            return result;
        }

        /// <summary>
        /// This method is a required placeholder, but is not used by app events.
        /// </summary>
        /// <param name="properties">Unused.</param>
        public void ProcessOneWayEvent(SPRemoteEventProperties properties)
        {
            throw new NotImplementedException();
        }

    }
}
