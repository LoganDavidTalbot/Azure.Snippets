#-- ======================================================================
#-- Az PowerShell Script
#-- ======================================================================
#-- ======================================================================
#-- Author:      Logan Talbot (https://www.logantalbot.com/)
#-- Create Date: 2020/02/16
#-- Description: Get a Bearer token using Azure AD Application Authication 
#-- ======================================================================
#-- ======================================================================

param(
	[Parameter(Mandatory=$true)][string]$applicationId,
	[Parameter(Mandatory=$true)][string]$applicationKey,
    [Parameter(Mandatory=$true)][string]$tenantid    
)
#------Setup Request required modules

$AadTenant = $tenantid  # <--  AAD tenant ID
$AadAppId = $applicationId # <--  App Id of the identity to use
$AadAppKey = $applicationKey  # <--  Secret key of this identity

#Get OAuth2 Access Token from Azure AD
$body = @{
    "grant_type" = "client_credentials"
    "client_id" = "$AadAppId"
    "client_secret" = "$AadAppKey"
    "resource" = "https://storage.azure.com"
    "scope" = "https://storage.azure.com/.default"
}
$authResult = Invoke-RestMethod -Uri  "https://login.microsoftonline.com/$AadTenant/oauth2/token" -Body $body -Method Post

$accessToken = $authResult.access_token

if ($accessToken)
{
    Write-Host 'Got Access Token:', $accessToken
}
else
{
    Write-Error 'Fail to get Access Token'    
}