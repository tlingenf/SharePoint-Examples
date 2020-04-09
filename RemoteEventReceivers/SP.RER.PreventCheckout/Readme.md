This solution will prevent the ability to check-out documents located in SharePoint. This **provider-hosted SharePoint add-in** is composed of a SharePoint Add-in and a remote web service. When deployed to a site, a **remote event receiver** will register for the *ItemCheckingOut* event on the default Documents library.  The remote event receiver code simply cancels the check out event with an error message stating that the library does not support checking out documents.

#Projects in Solution
**SPDisallowCheckout** - Web scoped SharePoint Add-in that registers the remote event receiver.
**SPDisallowCheckoutWeb** - Web service that associates the event receiver with the Documents library and is called when the event fires.


**SharePoint version: 2013+, SPO**