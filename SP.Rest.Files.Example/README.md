```
Disclaimer
This sample code, scripts, and other resources are not supported under any Microsoft standard support program or service or of the sample author and are meant for illustrative purposes only. The sample code, scripts, and resources are provided AS IS without warranty of any kind. Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. The entire risk arising out of the use or performance of this material and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the sample be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the samples or documentation, even if Microsoft has been advised of the possibility of such damages.
```

# About This Solution

This sample solution is provided by Travis Lingenfelder, Premier Field Engineer, Microsoft.

The purpose of this sample is to illustrate how to work with SharePoint files using REST methods only (No CSOM).

# Setup The Sample

## SharePoint Destination Library
You will need to create a destination SharePoint site and library in order to run the sample. When setting up the library you will need to create some additional columns according to the following table:

|Column Name|Type|Notes|
| --- | --- | --- |
|Text Field|Single line of text| |
|Number Field|Number| |
|Multi-Choice Field|Choice|Allow multiple choices|

## Azure AD Application
