# ------------------------------------------------------------------------------
#  Copyright (c) Microsoft Corporation.  All Rights Reserved.  Licensed under the MIT License.  See License in the project root for license information.
# ------------------------------------------------------------------------------

Set-StrictMode -Version 2

$Permissions_msGraphApplicationId = '00000003-0000-0000-c000-000000000000'

# Entry point to the state of the Permissions 'class'
$_permissions = $null

# These '_'-prefixed functions are provided for tests to simulate the initial state of the class
# as well as providing visibility into its state for deeper validations

function _Permissions_Initialize {
    # Testing note: Pester alters runtime behavior so that variables defined at script
    # scope do not actually show up at script scope via 'script:' at runtime (!), so
    # we'll just use the Get-Variable command to explicitly obtain the variable object for it
    $permissionsVariable = Get-Variable _permissions

    # This structure models the state of the permissions class
    $permissionsVariable.Value = [PSCustomObject] @{
        msGraphPermissionsRequestUri = "https://graph.microsoft.com/v1.0/servicePrincipals?`$filter=appId eq '$Permissions_msGraphApplicationId'"
        msGraphServicePrincipal = $null
        isFromInvokeMgGraphRequest = $false
    }
}

function _Permissions_State {
    $_permissions
}

function Permissions_GetPermissionsData([bool] $online) {
    # Make a REST request to MS Graph to get the permissions data from the Microsoft Graph service principal
    if ( $online -or ! $_permissions.msGraphServicePrincipal -or ! $_permissions.isFromInvokeMgGraphRequest ) {
        try {
            $restResult = Invoke-MgGraphRequest -method GET -OutputType PSObject $_permissions.msGraphPermissionsRequestUri

            if ( $restResult ) {
                $_permissions.msGraphServicePrincipal = $restResult | Select-Object -ExpandProperty value
                $_permissions.isFromInvokeMgGraphRequest = $true
            }
        } catch [System.Management.Automation.ValidationMetadataException], [System.Net.Http.HttpRequestException] {
            if ( $online ) {
                throw
            }
            # We can't get the data from MS Graph, so just use a local static (possibly stale) copy
            $_permissions.msGraphServicePrincipal = Get-Content $PSScriptRoot/MSGraphServicePrincipalPermissions.json | Out-String | ConvertFrom-Json
        }
    }

    # Filter out the unwanted fields and leave only the appRoleAssignments and
    # oauth2PermissionScope objects
    $_permissions.msGraphServicePrincipal | Select-Object oauth2PermissionScopes, appRoles
}

function Permissions_GetOauthData( [PSCustomObject] $permissionsData ) {
    foreach ( $oauth2grant in $permissionsData.oauth2PermissionScopes ) {
        $description = If ($oauth2grant.type -eq 'Admin') {
            $oauth2grant.adminConsentDescription
        } elseif ($oauth2grant.type -eq 'User') {
            $oauth2grant.userConsentDescription
        }

        $entry = [ordered] @{
            Id = $oauth2grant.id
            PermissionType = 'Delegated'
            Consent = $oauth2grant.type
            Name = $oauth2grant.value
            Description = $description
        }

        $permissions = [PSCustomObject] $entry
        $permissions.PSTypeNames.Insert(0, 'Microsoft.Graph.Custom.Permission')
        $permissions
    }
}

function Permissions_GetAppRolesData( [PSCustomObject] $permissionsData ) {
    foreach ( $appRole in $permissionsData.appRoles ) {

        $consent = if ($appRole.origin -eq 'Application') {
            'Admin'
        } elseif ($appRole.origin -eq 'Delegated') {
            'User'
        }

        $entry = [ordered] @{
            Id = $appRole.id
            PermissionType = 'Application'
            Consent = $consent
            Name = $appRole.value
            Description = $appRole.description
        }

        $permissions = [PSCustomObject] $entry
        $permissions.PSTypeNames.Insert(0, 'Microsoft.Graph.Custom.Permission')
        $permissions
    }
}

_Permissions_Initialize

# SIG # Begin signature block
# MIInuAYJKoZIhvcNAQcCoIInqTCCJ6UCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCXUQeyVlKHCmjX
# wBdm/VkSOw1Jb1oB7wEgvjPf4RNga6CCDYEwggX/MIID56ADAgECAhMzAAACUosz
# qviV8znbAAAAAAJSMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMjEwOTAyMTgzMjU5WhcNMjIwOTAxMTgzMjU5WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQDQ5M+Ps/X7BNuv5B/0I6uoDwj0NJOo1KrVQqO7ggRXccklyTrWL4xMShjIou2I
# sbYnF67wXzVAq5Om4oe+LfzSDOzjcb6ms00gBo0OQaqwQ1BijyJ7NvDf80I1fW9O
# L76Kt0Wpc2zrGhzcHdb7upPrvxvSNNUvxK3sgw7YTt31410vpEp8yfBEl/hd8ZzA
# v47DCgJ5j1zm295s1RVZHNp6MoiQFVOECm4AwK2l28i+YER1JO4IplTH44uvzX9o
# RnJHaMvWzZEpozPy4jNO2DDqbcNs4zh7AWMhE1PWFVA+CHI/En5nASvCvLmuR/t8
# q4bc8XR8QIZJQSp+2U6m2ldNAgMBAAGjggF+MIIBejAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQUNZJaEUGL2Guwt7ZOAu4efEYXedEw
# UAYDVR0RBEkwR6RFMEMxKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1
# ZXJ0byBSaWNvMRYwFAYDVQQFEw0yMzAwMTIrNDY3NTk3MB8GA1UdIwQYMBaAFEhu
# ZOVQBdOCqhc3NyK1bajKdQKVMFQGA1UdHwRNMEswSaBHoEWGQ2h0dHA6Ly93d3cu
# bWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY0NvZFNpZ1BDQTIwMTFfMjAxMS0w
# Ny0wOC5jcmwwYQYIKwYBBQUHAQEEVTBTMFEGCCsGAQUFBzAChkVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY0NvZFNpZ1BDQTIwMTFfMjAx
# MS0wNy0wOC5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0BAQsFAAOCAgEAFkk3
# uSxkTEBh1NtAl7BivIEsAWdgX1qZ+EdZMYbQKasY6IhSLXRMxF1B3OKdR9K/kccp
# kvNcGl8D7YyYS4mhCUMBR+VLrg3f8PUj38A9V5aiY2/Jok7WZFOAmjPRNNGnyeg7
# l0lTiThFqE+2aOs6+heegqAdelGgNJKRHLWRuhGKuLIw5lkgx9Ky+QvZrn/Ddi8u
# TIgWKp+MGG8xY6PBvvjgt9jQShlnPrZ3UY8Bvwy6rynhXBaV0V0TTL0gEx7eh/K1
# o8Miaru6s/7FyqOLeUS4vTHh9TgBL5DtxCYurXbSBVtL1Fj44+Od/6cmC9mmvrti
# yG709Y3Rd3YdJj2f3GJq7Y7KdWq0QYhatKhBeg4fxjhg0yut2g6aM1mxjNPrE48z
# 6HWCNGu9gMK5ZudldRw4a45Z06Aoktof0CqOyTErvq0YjoE4Xpa0+87T/PVUXNqf
# 7Y+qSU7+9LtLQuMYR4w3cSPjuNusvLf9gBnch5RqM7kaDtYWDgLyB42EfsxeMqwK
# WwA+TVi0HrWRqfSx2olbE56hJcEkMjOSKz3sRuupFCX3UroyYf52L+2iVTrda8XW
# esPG62Mnn3T8AuLfzeJFuAbfOSERx7IFZO92UPoXE1uEjL5skl1yTZB3MubgOA4F
# 8KoRNhviFAEST+nG8c8uIsbZeb08SeYQMqjVEmkwggd6MIIFYqADAgECAgphDpDS
# AAAAAAADMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBDZXJ0aWZpY2F0
# ZSBBdXRob3JpdHkgMjAxMTAeFw0xMTA3MDgyMDU5MDlaFw0yNjA3MDgyMTA5MDla
# MH4xCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdS
# ZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMT
# H01pY3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTEwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCr8PpyEBwurdhuqoIQTTS68rZYIZ9CGypr6VpQqrgG
# OBoESbp/wwwe3TdrxhLYC/A4wpkGsMg51QEUMULTiQ15ZId+lGAkbK+eSZzpaF7S
# 35tTsgosw6/ZqSuuegmv15ZZymAaBelmdugyUiYSL+erCFDPs0S3XdjELgN1q2jz
# y23zOlyhFvRGuuA4ZKxuZDV4pqBjDy3TQJP4494HDdVceaVJKecNvqATd76UPe/7
# 4ytaEB9NViiienLgEjq3SV7Y7e1DkYPZe7J7hhvZPrGMXeiJT4Qa8qEvWeSQOy2u
# M1jFtz7+MtOzAz2xsq+SOH7SnYAs9U5WkSE1JcM5bmR/U7qcD60ZI4TL9LoDho33
# X/DQUr+MlIe8wCF0JV8YKLbMJyg4JZg5SjbPfLGSrhwjp6lm7GEfauEoSZ1fiOIl
# XdMhSz5SxLVXPyQD8NF6Wy/VI+NwXQ9RRnez+ADhvKwCgl/bwBWzvRvUVUvnOaEP
# 6SNJvBi4RHxF5MHDcnrgcuck379GmcXvwhxX24ON7E1JMKerjt/sW5+v/N2wZuLB
# l4F77dbtS+dJKacTKKanfWeA5opieF+yL4TXV5xcv3coKPHtbcMojyyPQDdPweGF
# RInECUzF1KVDL3SV9274eCBYLBNdYJWaPk8zhNqwiBfenk70lrC8RqBsmNLg1oiM
# CwIDAQABo4IB7TCCAekwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFEhuZOVQ
# BdOCqhc3NyK1bajKdQKVMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1Ud
# DwQEAwIBhjAPBgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFHItOgIxkEO5FAVO
# 4eqnxzHRI4k0MFoGA1UdHwRTMFEwT6BNoEuGSWh0dHA6Ly9jcmwubWljcm9zb2Z0
# LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcmwwXgYIKwYBBQUHAQEEUjBQME4GCCsGAQUFBzAChkJodHRwOi8vd3d3Lm1p
# Y3Jvc29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dDIwMTFfMjAxMV8wM18y
# Mi5jcnQwgZ8GA1UdIASBlzCBlDCBkQYJKwYBBAGCNy4DMIGDMD8GCCsGAQUFBwIB
# FjNodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2RvY3MvcHJpbWFyeWNw
# cy5odG0wQAYIKwYBBQUHAgIwNB4yIB0ATABlAGcAYQBsAF8AcABvAGwAaQBjAHkA
# XwBzAHQAYQB0AGUAbQBlAG4AdAAuIB0wDQYJKoZIhvcNAQELBQADggIBAGfyhqWY
# 4FR5Gi7T2HRnIpsLlhHhY5KZQpZ90nkMkMFlXy4sPvjDctFtg/6+P+gKyju/R6mj
# 82nbY78iNaWXXWWEkH2LRlBV2AySfNIaSxzzPEKLUtCw/WvjPgcuKZvmPRul1LUd
# d5Q54ulkyUQ9eHoj8xN9ppB0g430yyYCRirCihC7pKkFDJvtaPpoLpWgKj8qa1hJ
# Yx8JaW5amJbkg/TAj/NGK978O9C9Ne9uJa7lryft0N3zDq+ZKJeYTQ49C/IIidYf
# wzIY4vDFLc5bnrRJOQrGCsLGra7lstnbFYhRRVg4MnEnGn+x9Cf43iw6IGmYslmJ
# aG5vp7d0w0AFBqYBKig+gj8TTWYLwLNN9eGPfxxvFX1Fp3blQCplo8NdUmKGwx1j
# NpeG39rz+PIWoZon4c2ll9DuXWNB41sHnIc+BncG0QaxdR8UvmFhtfDcxhsEvt9B
# xw4o7t5lL+yX9qFcltgA1qFGvVnzl6UJS0gQmYAf0AApxbGbpT9Fdx41xtKiop96
# eiL6SJUfq/tHI4D1nvi/a7dLl+LrdXga7Oo3mXkYS//WsyNodeav+vyL6wuA6mk7
# r/ww7QRMjt/fdW1jkT3RnVZOT7+AVyKheBEyIXrvQQqxP/uozKRdwaGIm1dxVk5I
# RcBCyZt2WwqASGv9eZ/BvW1taslScxMNelDNMYIZjTCCGYkCAQEwgZUwfjELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEoMCYGA1UEAxMfTWljcm9z
# b2Z0IENvZGUgU2lnbmluZyBQQ0EgMjAxMQITMwAAAlKLM6r4lfM52wAAAAACUjAN
# BglghkgBZQMEAgEFAKCBrjAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAvBgkqhkiG9w0BCQQxIgQgg/AjHBN8
# e6mKht9bsPKKZfptv1r4xgBDs6Uv+rEzjugwQgYKKwYBBAGCNwIBDDE0MDKgFIAS
# AE0AaQBjAHIAbwBzAG8AZgB0oRqAGGh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbTAN
# BgkqhkiG9w0BAQEFAASCAQBRfj/H0+AaxUDLD2BHsKaqmuC4TprezhYB8hjK91sR
# zfeRelzmZ8ZNTI12yBaI7I27da0fP6yHdSBlZffL4WxOcUXk1zEki9V3hdVXW4ay
# 5V8xU9AUmOu1ipf5jwb6lOzkd/Rh8u74KG/FTJvgd568p8XYnAnB8SYXLdgwl2wb
# 6MUWgep6iwnigr5x4JVBD26bdQMwnjFSPWiKgAbGe1GCaZeEXZQl5VxGsHGveggs
# ZTXmqJbGMDvSAr49AXh+BUg228ZlTIhfngd1g2M1dTh6RDSppaRhYLFkwgX4LrIF
# OokYQKFLv+qBfcE78sGudCgIOJ+0/TY8SeqxWq4WAzbgoYIXFzCCFxMGCisGAQQB
# gjcDAwExghcDMIIW/wYJKoZIhvcNAQcCoIIW8DCCFuwCAQMxDzANBglghkgBZQME
# AgEFADCCAVkGCyqGSIb3DQEJEAEEoIIBSASCAUQwggFAAgEBBgorBgEEAYRZCgMB
# MDEwDQYJYIZIAWUDBAIBBQAEIFxsYZMz4G7gXGR0dx/8gLr6yCV7rZ3cWED9+4Fk
# 8+8hAgZihmEv0oIYEzIwMjIwNjIyMDAzMzQ0Ljc1OFowBIACAfSggdikgdUwgdIx
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1p
# Y3Jvc29mdCBJcmVsYW5kIE9wZXJhdGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhh
# bGVzIFRTUyBFU046MTc5RS00QkIwLTgyNDYxJTAjBgNVBAMTHE1pY3Jvc29mdCBU
# aW1lLVN0YW1wIFNlcnZpY2WgghFmMIIHFDCCBPygAwIBAgITMwAAAYo+OI3SDgL6
# 6AABAAABijANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMK
# V2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0
# IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0Eg
# MjAxMDAeFw0yMTEwMjgxOTI3NDJaFw0yMzAxMjYxOTI3NDJaMIHSMQswCQYDVQQG
# EwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwG
# A1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQg
# SXJlbGFuZCBPcGVyYXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1Mg
# RVNOOjE3OUUtNEJCMC04MjQ2MSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFt
# cCBTZXJ2aWNlMIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAt/+ut6GD
# AyAZvegBhagWd0GoqT8lFHMepoWNOLPPEEoLuya4X3n+K14FvlZwFmKwqap6B+6E
# kITSjkecTSB6QRA4kivdJydlLvKrg8udtBu67LKyjQqwRzDQTRhECxpU30tdBE/A
# eyP95k7qndhIu/OpT4QGyGJUiMDlmZAiDPY5FJkitUgGvwMBHwogJz8FVEBFnViA
# URTJ4kBDiU6ppbv4PI97+vQhpspDK+83gayaiRC3gNTGy3iOie6Psl03cvYIiFcA
# JRP4O0RkeFlv/SQoomz3JtsMd9ooS/XO0vSN9h2DVKONMjaFOgnN5Rk5iCqwmn6q
# sme+haoR/TrCBS0zXjXsWTgkljUBtt17UBbW8RL+9LNw3cjPJ8EYRglMNXCYLM6G
# zCDXEvE9T//sAv+k1c84tmoiZDZBqBgr/SvL+gVsOz3EoDZQ26qTa1bEn/npxMmX
# ctoZSe8SRDqgK0JUWhjKXgnyaOADEB+FtfIi+jdcUJbpPtAL4kWvVSRKipVv8MEu
# YRLexXEDEBi+V4tfKApZhE4ga0p+QCiawHLBZNoj3UQNzM5QVmGai3MnQFbZkhqb
# UDypo9vaWEeVeO35JfdLWjwRgvMX3VKZL57d7jmRjiVlluXjZFLx+rhJL7JYVptO
# PtF1MAtMYlp6OugnOpG+4W4MGHqj7YYfP0UCAwEAAaOCATYwggEyMB0GA1UdDgQW
# BBQj2kPY/WwZ1Jeup0lHhD4xkGkkAzAfBgNVHSMEGDAWgBSfpxVdAF5iXYP05dJl
# pxtTNRnpcjBfBgNVHR8EWDBWMFSgUqBQhk5odHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20vcGtpb3BzL2NybC9NaWNyb3NvZnQlMjBUaW1lLVN0YW1wJTIwUENBJTIwMjAx
# MCgxKS5jcmwwbAYIKwYBBQUHAQEEYDBeMFwGCCsGAQUFBzAChlBodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMFRpbWUtU3Rh
# bXAlMjBQQ0ElMjAyMDEwKDEpLmNydDAMBgNVHRMBAf8EAjAAMBMGA1UdJQQMMAoG
# CCsGAQUFBwMIMA0GCSqGSIb3DQEBCwUAA4ICAQDF9MESsPXDeRtfFo1f575iPfF9
# ARWbeuuNfM583IfTxfzZf2dv/me3DNi/KcNNEnR1TKbZtG7Lsg0cy/pKIEQOJG2f
# YaWwIIKYwuyDJI2Q4kVi5mzbV/0C5+vQQsQcCvfsM8K5X2ffifJi7tqeG0r58Cjg
# we7xBYvguPmjUNxwTWvEjZIPfpjVUoaPCl6qqs0eFUb7bcLhzTEEYBnAj8MENhiP
# 5IJd4Pp5lFqHTtpec67YFmGuO/uIA/TjPBfctM5kUI+uzfyh/yIdtDNtkIz+e/xm
# XSFhiQER0uBjRobQZV6c+0TNtvRNLayU4u7Eekd7OaDXzQR0RuWGaSiwtN6Xc/Po
# NP0rezG6Ovcyow1qMoUkUEQ7qqD0Qq8QFwK0DKCdZSJtyBKMBpjUYCnNUZbYvTTW
# m4DXK5RYgf23bVBJW4Xo5w490HHo4TjWNqz17PqPyMCTnM8HcAqTnPeME0dPYvbd
# wzDMgbumydbJaq/06FImkJ7KXs9jxqDiE2PTeYnaj82n6Q//PqbHuxxJmwQO4fzd
# OgVqAEkG1XDmppVKW/rJxBN3IxyVr6QP9chY2MYVa0bbACI2dvU+R2QJlE5AjoMK
# y68WI1pmFT3JKBrracpy6HUjGrtV+/1U52brrElClVy5Fb8+UZWZLp82cuCztJMM
# SqW+kP5zyVBSvLM+4DCCB3EwggVZoAMCAQICEzMAAAAVxedrngKbSZkAAAAAABUw
# DQYJKoZIhvcNAQELBQAwgYgxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5n
# dG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9y
# YXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBSb290IENlcnRpZmljYXRlIEF1dGhv
# cml0eSAyMDEwMB4XDTIxMDkzMDE4MjIyNVoXDTMwMDkzMDE4MzIyNVowfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwggIiMA0GCSqGSIb3DQEBAQUAA4ICDwAw
# ggIKAoICAQDk4aZM57RyIQt5osvXJHm9DtWC0/3unAcH0qlsTnXIyjVX9gF/bErg
# 4r25PhdgM/9cT8dm95VTcVrifkpa/rg2Z4VGIwy1jRPPdzLAEBjoYH1qUoNEt6aO
# RmsHFPPFdvWGUNzBRMhxXFExN6AKOG6N7dcP2CZTfDlhAnrEqv1yaa8dq6z2Nr41
# JmTamDu6GnszrYBbfowQHJ1S/rboYiXcag/PXfT+jlPP1uyFVk3v3byNpOORj7I5
# LFGc6XBpDco2LXCOMcg1KL3jtIckw+DJj361VI/c+gVVmG1oO5pGve2krnopN6zL
# 64NF50ZuyjLVwIYwXE8s4mKyzbnijYjklqwBSru+cakXW2dg3viSkR4dPf0gz3N9
# QZpGdc3EXzTdEonW/aUgfX782Z5F37ZyL9t9X4C626p+Nuw2TPYrbqgSUei/BQOj
# 0XOmTTd0lBw0gg/wEPK3Rxjtp+iZfD9M269ewvPV2HM9Q07BMzlMjgK8QmguEOqE
# UUbi0b1qGFphAXPKZ6Je1yh2AuIzGHLXpyDwwvoSCtdjbwzJNmSLW6CmgyFdXzB0
# kZSU2LlQ+QuJYfM2BjUYhEfb3BvR/bLUHMVr9lxSUV0S2yW6r1AFemzFER1y7435
# UsSFF5PAPBXbGjfHCBUYP3irRbb1Hode2o+eFnJpxq57t7c+auIurQIDAQABo4IB
# 3TCCAdkwEgYJKwYBBAGCNxUBBAUCAwEAATAjBgkrBgEEAYI3FQIEFgQUKqdS/mTE
# mr6CkTxGNSnPEP8vBO4wHQYDVR0OBBYEFJ+nFV0AXmJdg/Tl0mWnG1M1GelyMFwG
# A1UdIARVMFMwUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTATBgNV
# HSUEDDAKBggrBgEFBQcDCDAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTALBgNV
# HQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTV9lbLj+iiXGJo
# 0T2UkFvXzpoYxDBWBgNVHR8ETzBNMEugSaBHhkVodHRwOi8vY3JsLm1pY3Jvc29m
# dC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5j
# cmwwWgYIKwYBBQUHAQEETjBMMEoGCCsGAQUFBzAChj5odHRwOi8vd3d3Lm1pY3Jv
# c29mdC5jb20vcGtpL2NlcnRzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNydDAN
# BgkqhkiG9w0BAQsFAAOCAgEAnVV9/Cqt4SwfZwExJFvhnnJL/Klv6lwUtj5OR2R4
# sQaTlz0xM7U518JxNj/aZGx80HU5bbsPMeTCj/ts0aGUGCLu6WZnOlNN3Zi6th54
# 2DYunKmCVgADsAW+iehp4LoJ7nvfam++Kctu2D9IdQHZGN5tggz1bSNU5HhTdSRX
# ud2f8449xvNo32X2pFaq95W2KFUn0CS9QKC/GbYSEhFdPSfgQJY4rPf5KYnDvBew
# VIVCs/wMnosZiefwC2qBwoEZQhlSdYo2wh3DYXMuLGt7bj8sCXgU6ZGyqVvfSaN0
# DLzskYDSPeZKPmY7T7uG+jIa2Zb0j/aRAfbOxnT99kxybxCrdTDFNLB62FD+Cljd
# QDzHVG2dY3RILLFORy3BFARxv2T5JL5zbcqOCb2zAVdJVGTZc9d/HltEAY5aGZFr
# DZ+kKNxnGSgkujhLmm77IVRrakURR6nxt67I6IleT53S0Ex2tVdUCbFpAUR+fKFh
# bHP+CrvsQWY9af3LwUFJfn6Tvsv4O+S3Fb+0zj6lMVGEvL8CwYKiexcdFYmNcP7n
# tdAoGokLjzbaukz5m/8K6TT4JDVnK+ANuOaMmdbhIurwJ0I9JZTmdHRbatGePu1+
# oDEzfbzL6Xu/OHBE0ZDxyKs6ijoIYn/ZcGNTTY3ugm2lBRDBcQZqELQdVTNYs6Fw
# ZvKhggLVMIICPgIBATCCAQChgdikgdUwgdIxCzAJBgNVBAYTAlVTMRMwEQYDVQQI
# EwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046MTc5RS00QkIw
# LTgyNDYxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIFNlcnZpY2WiIwoB
# ATAHBgUrDgMCGgMVAIDw82OvG1MFBB2n/4weVqpzV8ShoIGDMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQACBQDmXF8jMCIY
# DzIwMjIwNjIxMjMxNTQ3WhgPMjAyMjA2MjIyMzE1NDdaMHUwOwYKKwYBBAGEWQoE
# ATEtMCswCgIFAOZcXyMCAQAwBwIBAAICcIswCAIBAAIDAMINMAoCBQDmXbCjAgEA
# MDYGCisGAQQBhFkKBAIxKDAmMAwGCisGAQQBhFkKAwKgCjAIAgEAAgMHoSChCjAI
# AgEAAgMBhqAwDQYJKoZIhvcNAQEFBQADgYEAQ2Qk7eFhCCpJJs5eRhIJrkGUh8OB
# YtR5RNUGvTtVmp3tHzJSxjz2Zenv5D5alxyd+iyl+lb4Lr382d5gBVT82qyXRtqL
# goQW+tbIqTpJ854Gu2S6ECe9SCHnTI6szdvklxDZXtZlcOkNLxa/JlMwPDJBCcc5
# d7Ffe73wmEpCA/YxggQNMIIECQIBATCBkzB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMAITMwAAAYo+OI3SDgL66AABAAABijANBglghkgBZQMEAgEFAKCCAUow
# GgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3DQEJBDEiBCC5KSCg
# 6JZdOvrFRcO4b20ftQX2Eh/YL/ja5SUtJLB3gzCB+gYLKoZIhvcNAQkQAi8xgeow
# gecwgeQwgb0EIPS94Kt130q+fvO/fzD4MbWQhQaE7RHkOH6AkjlNVCm9MIGYMIGA
# pH4wfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcT
# B1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UE
# AxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIwMTACEzMAAAGKPjiN0g4C+ugA
# AQAAAYowIgQgakOVhyOeUpu0rxenx5o7ZGxxsphPFeJKen6cOI1ohtowDQYJKoZI
# hvcNAQELBQAEggIAZh1aC0HTc0eF9vN1AL+Hlkhj67QKWn63ut+x+3Kq7IRO34sd
# 493qABBp5Uqgk3aiY9tZ7Qp8fUnCvO1AUG/ghz5fZ6FSfCHl8uthmgMuLrKrO0xG
# r5a8Fei02nGXspN4pO8iRcrl9OiSCv4qZYQnwallueYYXy26/lpEOIoLc1NUE+hQ
# 3/RdiWOzsdQkkJ+GlR1VZyxGO2ehLEgYoGTb6VxODw97U2ZC9DgGIUMUJ1qwXfm4
# 2RXOncS3DH/AdPSQVZ2WC6jup9bSaul1qOYpyrWi5KqA+nCbeS7J90Fx+1wmvkuf
# lJ8ZPYQzsRdQ0kRNImief9CAVdEIV+5FUpQpv8+YvHTyUUqthnPzzlg9UiEYBGE+
# Uh6I/dfd0B5hoTLcr0M+tDrFRVwScucsIs8I6ReTBsCjE5oz6LUH8CFjv6ybdKQ+
# Wn56mdkiE3wf7MWPn/OXz0AaVNJuJ2AKsNfbUdKSIS0RRyFaAhpIBb57GC7N+KJE
# CFF6nQ5Roj7+IjS0CYt7fEEfqYyw13/q4brVbRtjFK1tuUdF3quyMzytkqoItjdt
# yP/7HxyPUXSyMDRrX2l3KKb+CNMqyttbRedQLIKnldqLuuxbdzd54qZJey4HLDGK
# lBj6iRnsL+EVRZwLfYoul5vc4w0FVlDwr5TjAxKzOpmrLr7h3+cFa11Mc1o=
# SIG # End signature block
