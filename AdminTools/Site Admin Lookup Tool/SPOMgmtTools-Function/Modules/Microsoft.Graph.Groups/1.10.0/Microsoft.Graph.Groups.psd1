#
# Module manifest for module 'Microsoft.Graph.Groups'
#
# Generated by: Microsoft Corporation
#
# Generated on: 6/22/2022
#

@{

# Script module or binary module file associated with this manifest.
RootModule = './Microsoft.Graph.Groups.psm1'

# Version number of this module.
ModuleVersion = '1.10.0'

# Supported PSEditions
CompatiblePSEditions = 'Core', 'Desktop'

# ID used to uniquely identify this module
GUID = '50bc9e18-e281-4208-8913-c9e1bef6083d'

# Author of this module
Author = 'Microsoft Corporation'

# Company or vendor of this module
CompanyName = 'Microsoft Corporation'

# Copyright statement for this module
Copyright = 'Microsoft Corporation. All rights reserved.'

# Description of the functionality provided by this module
Description = 'Microsoft Graph PowerShell Cmdlets'

# Minimum version of the PowerShell engine required by this module
PowerShellVersion = '5.1'

# Name of the PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
DotNetFrameworkVersion = '4.7.2'

# Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
# ClrVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @(@{ModuleName = 'Microsoft.Graph.Authentication'; ModuleVersion = '1.10.0'; })

# Assemblies that must be loaded prior to importing this module
RequiredAssemblies = './bin/Microsoft.Graph.Groups.private.dll'

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = './Microsoft.Graph.Groups.format.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
FunctionsToExport = 'Add-MgGroupDriveListContentTypeCopy', 
               'Add-MgGroupDriveListContentTypeCopyFromContentTypeHub', 
               'Add-MgGroupFavorite', 'Add-MgGroupSite', 
               'Add-MgGroupSiteContentTypeCopy', 
               'Add-MgGroupSiteContentTypeCopyFromContentTypeHub', 
               'Add-MgGroupSiteListContentTypeCopy', 
               'Add-MgGroupSiteListContentTypeCopyFromContentTypeHub', 
               'Add-MgGroupToLifecyclePolicy', 
               'Confirm-MgGroupGrantedPermissionForApp', 
               'Confirm-MgGroupMemberGroup', 'Confirm-MgGroupMemberObject', 
               'Confirm-MgGroupPermissionGrantMemberGroup', 
               'Confirm-MgGroupPermissionGrantMemberObject', 
               'Copy-MgGroupDriveItem', 
               'Copy-MgGroupDriveListContentTypeToDefaultContentLocation', 
               'Copy-MgGroupDriveRoot', 'Copy-MgGroupOnenoteNotebook', 
               'Copy-MgGroupOnenotePageToSection', 
               'Copy-MgGroupOnenoteSectionToNotebook', 
               'Copy-MgGroupOnenoteSectionToSectionGroup', 
               'Copy-MgGroupSiteContentTypeToDefaultContentLocation', 
               'Copy-MgGroupSiteListContentTypeToDefaultContentLocation', 
               'Get-MgGroup', 'Get-MgGroupAcceptedSender', 
               'Get-MgGroupAcceptedSenderByRef', 'Get-MgGroupById', 
               'Get-MgGroupCalendarEventDelta', 'Get-MgGroupCalendarSchedule', 
               'Get-MgGroupConversation', 'Get-MgGroupConversationThread', 
               'Get-MgGroupConversationThreadPost', 
               'Get-MgGroupConversationThreadPostAttachment', 
               'Get-MgGroupConversationThreadPostExtension', 
               'Get-MgGroupConversationThreadPostInReplyToAttachment', 
               'Get-MgGroupConversationThreadPostInReplyToExtension', 
               'Get-MgGroupConversationThreadPostInReplyToMention', 
               'Get-MgGroupConversationThreadPostInReplyToMultiValueExtendedProperty', 
               'Get-MgGroupConversationThreadPostInReplyToSingleValueExtendedProperty', 
               'Get-MgGroupConversationThreadPostMention', 
               'Get-MgGroupConversationThreadPostMultiValueExtendedProperty', 
               'Get-MgGroupConversationThreadPostSingleValueExtendedProperty', 
               'Get-MgGroupCreatedOnBehalfOf', 'Get-MgGroupDelta', 
               'Get-MgGroupDriveItemActivityByInterval', 
               'Get-MgGroupDriveItemDelta', 
               'Get-MgGroupDriveItemListItemActivityByInterval', 
               'Get-MgGroupDriveListContentTypeCompatibleHubContentType', 
               'Get-MgGroupDriveListItemActivityByInterval', 
               'Get-MgGroupDriveListItemDelta', 
               'Get-MgGroupDriveRootActivityByInterval', 
               'Get-MgGroupDriveRootDelta', 
               'Get-MgGroupDriveRootListItemActivityByInterval', 
               'Get-MgGroupEndpoint', 'Get-MgGroupEventDelta', 
               'Get-MgGroupExtension', 'Get-MgGroupLifecyclePolicy', 
               'Get-MgGroupMember', 'Get-MgGroupMemberByRef', 
               'Get-MgGroupMemberGroup', 'Get-MgGroupMemberObject', 
               'Get-MgGroupMemberOf', 'Get-MgGroupMemberWithLicenseError', 
               'Get-MgGroupOnenoteNotebookFromWebUrl', 
               'Get-MgGroupOnenoteRecentNotebook', 'Get-MgGroupOwner', 
               'Get-MgGroupOwnerByRef', 'Get-MgGroupPermissionGrant', 
               'Get-MgGroupPermissionGrantAvailableExtensionProperty', 
               'Get-MgGroupPermissionGrantById', 
               'Get-MgGroupPermissionGrantMemberGroup', 
               'Get-MgGroupPermissionGrantMemberObject', 
               'Get-MgGroupPermissionGrantUserOwnedObject', 'Get-MgGroupPhoto', 
               'Get-MgGroupPhotoContent', 'Get-MgGroupRejectedSender', 
               'Get-MgGroupRejectedSenderByRef', 'Get-MgGroupSetting', 
               'Get-MgGroupSiteActivityByInterval', 
               'Get-MgGroupSiteApplicableContentTypeForList', 
               'Get-MgGroupSiteByPath', 
               'Get-MgGroupSiteContentTypeCompatibleHubContentType', 
               'Get-MgGroupSiteDelta', 
               'Get-MgGroupSiteListContentTypeCompatibleHubContentType', 
               'Get-MgGroupSiteListItemActivityByInterval', 
               'Get-MgGroupSiteListItemDelta', 'Get-MgGroupThread', 
               'Get-MgGroupThreadPost', 'Get-MgGroupThreadPostAttachment', 
               'Get-MgGroupThreadPostExtension', 
               'Get-MgGroupThreadPostInReplyToAttachment', 
               'Get-MgGroupThreadPostInReplyToExtension', 
               'Get-MgGroupThreadPostInReplyToMention', 
               'Get-MgGroupThreadPostInReplyToMultiValueExtendedProperty', 
               'Get-MgGroupThreadPostInReplyToSingleValueExtendedProperty', 
               'Get-MgGroupThreadPostMention', 
               'Get-MgGroupThreadPostMultiValueExtendedProperty', 
               'Get-MgGroupThreadPostSingleValueExtendedProperty', 
               'Get-MgGroupTransitiveMember', 'Get-MgGroupTransitiveMemberOf', 
               'Get-MgGroupUserOwnedObject', 'Get-MgUserJoinedGroup', 
               'Grant-MgGroupDriveItemPermission', 
               'Grant-MgGroupDriveRootPermission', 'Grant-MgGroupSitePermission', 
               'Invoke-MgAcceptGroupCalendarEvent', 
               'Invoke-MgAcceptGroupCalendarEventTentatively', 
               'Invoke-MgAcceptGroupEvent', 'Invoke-MgAcceptGroupEventTentatively', 
               'Invoke-MgCalendarGroupCalendar', 'Invoke-MgCheckinGroupDriveItem', 
               'Invoke-MgCheckinGroupDriveRoot', 'Invoke-MgCheckoutGroupDriveItem', 
               'Invoke-MgCheckoutGroupDriveRoot', 
               'Invoke-MgDeclineGroupCalendarEvent', 'Invoke-MgDeclineGroupEvent', 
               'Invoke-MgDismissGroupCalendarEventReminder', 
               'Invoke-MgDismissGroupEventReminder', 
               'Invoke-MgExtractGroupDriveItemSensitivityLabel', 
               'Invoke-MgExtractGroupDriveRootSensitivityLabel', 
               'Invoke-MgFollowGroupDriveItem', 'Invoke-MgFollowGroupDriveRoot', 
               'Invoke-MgForwardGroupCalendarEvent', 
               'Invoke-MgForwardGroupConversationThreadPost', 
               'Invoke-MgForwardGroupConversationThreadPostInReplyTo', 
               'Invoke-MgForwardGroupEvent', 'Invoke-MgForwardGroupThreadPost', 
               'Invoke-MgForwardGroupThreadPostInReplyTo', 'Invoke-MgGraphGroup', 
               'Invoke-MgGraphGroupDrive', 'Invoke-MgInviteGroupDriveItem', 
               'Invoke-MgInviteGroupDriveRoot', 'Invoke-MgPreviewGroupDriveItem', 
               'Invoke-MgPreviewGroupDriveRoot', 
               'Invoke-MgPreviewGroupOnenotePage', 
               'Invoke-MgReauthorizeGroupDriveItemSubscription', 
               'Invoke-MgReauthorizeGroupDriveListSubscription', 
               'Invoke-MgReauthorizeGroupDriveRootSubscription', 
               'Invoke-MgReauthorizeGroupSiteListSubscription', 
               'Invoke-MgRecentGroupDrive', 'Invoke-MgRenewGroup', 
               'Invoke-MgRenewGroupLifecyclePolicy', 
               'Invoke-MgReplyGroupConversationThread', 
               'Invoke-MgReplyGroupConversationThreadPost', 
               'Invoke-MgReplyGroupConversationThreadPostInReplyTo', 
               'Invoke-MgReplyGroupThread', 'Invoke-MgReplyGroupThreadPost', 
               'Invoke-MgReplyGroupThreadPostInReplyTo', 
               'Invoke-MgSnoozeGroupCalendarEventReminder', 
               'Invoke-MgSnoozeGroupEventReminder', 
               'Invoke-MgSubscribeGroupByMail', 'Invoke-MgUnfollowGroupDriveItem', 
               'Invoke-MgUnfollowGroupDriveRoot', 
               'Join-MgGroupDriveListContentTypeWithHubSite', 
               'Join-MgGroupSiteContentTypeWithHubSite', 
               'Join-MgGroupSiteListContentTypeWithHubSite', 'New-MgGroup', 
               'New-MgGroupAcceptedSenderByRef', 'New-MgGroupConversation', 
               'New-MgGroupConversationThread', 
               'New-MgGroupConversationThreadPost', 
               'New-MgGroupConversationThreadPostAttachment', 
               'New-MgGroupConversationThreadPostAttachmentUploadSession', 
               'New-MgGroupConversationThreadPostExtension', 
               'New-MgGroupConversationThreadPostInReplyToAttachment', 
               'New-MgGroupConversationThreadPostInReplyToAttachmentUploadSession', 
               'New-MgGroupConversationThreadPostInReplyToExtension', 
               'New-MgGroupConversationThreadPostInReplyToMention', 
               'New-MgGroupConversationThreadPostInReplyToMultiValueExtendedProperty', 
               'New-MgGroupConversationThreadPostInReplyToSingleValueExtendedProperty', 
               'New-MgGroupConversationThreadPostMention', 
               'New-MgGroupConversationThreadPostMultiValueExtendedProperty', 
               'New-MgGroupConversationThreadPostSingleValueExtendedProperty', 
               'New-MgGroupDriveItemLink', 'New-MgGroupDriveItemListItemLink', 
               'New-MgGroupDriveItemUploadSession', 'New-MgGroupDriveListItemLink', 
               'New-MgGroupDriveRootLink', 'New-MgGroupDriveRootListItemLink', 
               'New-MgGroupDriveRootUploadSession', 'New-MgGroupEndpoint', 
               'New-MgGroupExtension', 'New-MgGroupLifecyclePolicy', 
               'New-MgGroupMember', 'New-MgGroupMemberByRef', 
               'New-MgGroupOwnerByRef', 'New-MgGroupPermissionGrant', 
               'New-MgGroupPhoto', 'New-MgGroupRejectedSenderByRef', 
               'New-MgGroupSetting', 'New-MgGroupSiteListItemLink', 
               'New-MgGroupThread', 'New-MgGroupThreadPost', 
               'New-MgGroupThreadPostAttachment', 
               'New-MgGroupThreadPostAttachmentUploadSession', 
               'New-MgGroupThreadPostExtension', 
               'New-MgGroupThreadPostInReplyToAttachment', 
               'New-MgGroupThreadPostInReplyToAttachmentUploadSession', 
               'New-MgGroupThreadPostInReplyToExtension', 
               'New-MgGroupThreadPostInReplyToMention', 
               'New-MgGroupThreadPostInReplyToMultiValueExtendedProperty', 
               'New-MgGroupThreadPostInReplyToSingleValueExtendedProperty', 
               'New-MgGroupThreadPostMention', 
               'New-MgGroupThreadPostMultiValueExtendedProperty', 
               'New-MgGroupThreadPostSingleValueExtendedProperty', 
               'New-MgUserJoinedGroup', 'Publish-MgGroupDriveListContentType', 
               'Publish-MgGroupSiteContentType', 
               'Publish-MgGroupSiteListContentType', 'Publish-MgGroupSitePage', 
               'Remove-MgGroup', 'Remove-MgGroupAcceptedSenderByRef', 
               'Remove-MgGroupConversation', 'Remove-MgGroupConversationThread', 
               'Remove-MgGroupConversationThreadPost', 
               'Remove-MgGroupConversationThreadPostAttachment', 
               'Remove-MgGroupConversationThreadPostExtension', 
               'Remove-MgGroupConversationThreadPostInReplyToAttachment', 
               'Remove-MgGroupConversationThreadPostInReplyToExtension', 
               'Remove-MgGroupConversationThreadPostInReplyToMention', 
               'Remove-MgGroupConversationThreadPostInReplyToMultiValueExtendedProperty', 
               'Remove-MgGroupConversationThreadPostInReplyToSingleValueExtendedProperty', 
               'Remove-MgGroupConversationThreadPostMention', 
               'Remove-MgGroupConversationThreadPostMultiValueExtendedProperty', 
               'Remove-MgGroupConversationThreadPostSingleValueExtendedProperty', 
               'Remove-MgGroupEndpoint', 'Remove-MgGroupExtension', 
               'Remove-MgGroupFavorite', 'Remove-MgGroupFromLifecyclePolicy', 
               'Remove-MgGroupLifecyclePolicy', 'Remove-MgGroupMemberByRef', 
               'Remove-MgGroupOwnerByRef', 'Remove-MgGroupPermissionGrant', 
               'Remove-MgGroupPhoto', 'Remove-MgGroupRejectedSenderByRef', 
               'Remove-MgGroupSetting', 'Remove-MgGroupSite', 'Remove-MgGroupThread', 
               'Remove-MgGroupThreadPost', 'Remove-MgGroupThreadPostAttachment', 
               'Remove-MgGroupThreadPostExtension', 
               'Remove-MgGroupThreadPostInReplyToAttachment', 
               'Remove-MgGroupThreadPostInReplyToExtension', 
               'Remove-MgGroupThreadPostInReplyToMention', 
               'Remove-MgGroupThreadPostInReplyToMultiValueExtendedProperty', 
               'Remove-MgGroupThreadPostInReplyToSingleValueExtendedProperty', 
               'Remove-MgGroupThreadPostMention', 
               'Remove-MgGroupThreadPostMultiValueExtendedProperty', 
               'Remove-MgGroupThreadPostSingleValueExtendedProperty', 
               'Reset-MgGroupUnseenCount', 'Restore-MgGroupDriveItem', 
               'Restore-MgGroupDriveItemListItemDocumentSetVersion', 
               'Restore-MgGroupDriveItemListItemVersion', 
               'Restore-MgGroupDriveItemVersion', 
               'Restore-MgGroupDriveListItemDocumentSetVersion', 
               'Restore-MgGroupDriveListItemVersion', 'Restore-MgGroupDriveRoot', 
               'Restore-MgGroupDriveRootListItemDocumentSetVersion', 
               'Restore-MgGroupDriveRootListItemVersion', 
               'Restore-MgGroupDriveRootVersion', 
               'Restore-MgGroupSiteListItemDocumentSetVersion', 
               'Restore-MgGroupSiteListItemVersion', 
               'Revoke-MgGroupDriveItemPermissionGrant', 
               'Revoke-MgGroupDriveRootPermissionGrant', 
               'Revoke-MgGroupSitePermissionGrant', 'Search-MgGroupDrive', 
               'Search-MgGroupDriveItem', 'Search-MgGroupDriveRoot', 
               'Set-MgGroupLicense', 'Set-MgGroupPhotoContent', 
               'Stop-MgGroupCalendarEvent', 'Stop-MgGroupEvent', 
               'Test-MgGroupDriveItemPermission', 
               'Test-MgGroupDriveListContentTypePublished', 
               'Test-MgGroupDriveRootPermission', 'Test-MgGroupDynamicMembership', 
               'Test-MgGroupDynamicMembershipRule', 
               'Test-MgGroupPermissionGrantProperty', 'Test-MgGroupProperty', 
               'Test-MgGroupSiteContentTypePublished', 
               'Test-MgGroupSiteListContentTypePublished', 
               'Unpublish-MgGroupDriveListContentType', 
               'Unpublish-MgGroupSiteContentType', 
               'Unpublish-MgGroupSiteListContentType', 'Update-MgGroup', 
               'Update-MgGroupConversation', 'Update-MgGroupConversationThread', 
               'Update-MgGroupConversationThreadPost', 
               'Update-MgGroupConversationThreadPostAttachment', 
               'Update-MgGroupConversationThreadPostExtension', 
               'Update-MgGroupConversationThreadPostInReplyToAttachment', 
               'Update-MgGroupConversationThreadPostInReplyToExtension', 
               'Update-MgGroupConversationThreadPostInReplyToMention', 
               'Update-MgGroupConversationThreadPostInReplyToMultiValueExtendedProperty', 
               'Update-MgGroupConversationThreadPostInReplyToSingleValueExtendedProperty', 
               'Update-MgGroupConversationThreadPostMention', 
               'Update-MgGroupConversationThreadPostMultiValueExtendedProperty', 
               'Update-MgGroupConversationThreadPostSingleValueExtendedProperty', 
               'Update-MgGroupEndpoint', 'Update-MgGroupExtension', 
               'Update-MgGroupLifecyclePolicy', 'Update-MgGroupOnenotePageContent', 
               'Update-MgGroupPermissionGrant', 'Update-MgGroupPhoto', 
               'Update-MgGroupSetting', 'Update-MgGroupThread', 
               'Update-MgGroupThreadPost', 'Update-MgGroupThreadPostAttachment', 
               'Update-MgGroupThreadPostExtension', 
               'Update-MgGroupThreadPostInReplyToAttachment', 
               'Update-MgGroupThreadPostInReplyToExtension', 
               'Update-MgGroupThreadPostInReplyToMention', 
               'Update-MgGroupThreadPostInReplyToMultiValueExtendedProperty', 
               'Update-MgGroupThreadPostInReplyToSingleValueExtendedProperty', 
               'Update-MgGroupThreadPostMention', 
               'Update-MgGroupThreadPostMultiValueExtendedProperty', 
               'Update-MgGroupThreadPostSingleValueExtendedProperty'

# Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
CmdletsToExport = @()

# Variables to export from this module
# VariablesToExport = @()

# Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
AliasesToExport = '*'

# DSC resources to export from this module
# DscResourcesToExport = @()

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
# FileList = @()

# Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
PrivateData = @{

    #Profiles of this module
    Profiles =  @('v1.0','v1.0-beta')

    PSData = @{

        # Tags applied to this module. These help with module discovery in online galleries.
        Tags = 'Microsoft','Office365','Graph','PowerShell'

        # A URL to the license for this module.
        LicenseUri = 'https://aka.ms/devservicesagreement'

        # A URL to the main website for this project.
        ProjectUri = 'https://github.com/microsoftgraph/msgraph-sdk-powershell'

        # A URL to an icon representing this module.
        IconUri = 'https://raw.githubusercontent.com/microsoftgraph/msgraph-sdk-powershell/master/documentation/images/graph_color256.png'

        # ReleaseNotes of this module
        ReleaseNotes = 'See https://aka.ms/GraphPowerShell-Release.'

        # Prerelease string of this module
        # Prerelease = ''

        # Flag to indicate whether the module requires explicit user acceptance for install/update/save
        # RequireLicenseAcceptance = $false

        # External dependent modules of this module
        # ExternalModuleDependencies = @()

    } # End of PSData hashtable

} # End of PrivateData hashtable

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

