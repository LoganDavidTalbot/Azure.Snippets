﻿#-- ======================================================================
#-- Az PowerShell Script
#-- ======================================================================
#-- ======================================================================
#-- Author:      Logan Talbot (https://www.logantalbot.com/)
#-- Create Date: 2020/02/05
#-- Description: Create Azure Data Lake Folders for Gen2. 
#--              Uses Az module commands and Azure REST API HTTPS calls. 
#-- ======================================================================
#-- ======================================================================

param(
    [Parameter(Mandatory=$true)][string]$dataLakeStoreName,
	[Parameter(Mandatory=$true)][string]$applicationId,
	[Parameter(Mandatory=$true)][string]$applicationKey,
    [Parameter(Mandatory=$true)][string]$tenantid,
    [Parameter(Mandatory=$true)][string]$containerName,
    [Parameter(Mandatory=$true)][string]$groupId,
    [Parameter(Mandatory=$true)][string]$userId,
    [Parameter(Mandatory=$true)][string]$resourceGroupName
    
)
#------Setup Request required modules

$AadTenant = $tenantid  # <--  AAD tenant ID
$AadAppId = $applicationId # <--  App Id of the identity to use
$AadAppKey = $applicationKey  # <--  Secret key of this identity


$AdlsAccountName = $dataLakeStoreName # <-- name of your ASLD Gen2 account
$FileSystemName = $containerName # <-- name of the file system to create (lowercase only)

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

#Make call to ADLS Gen2 to create File System
$headers = @{
    "x-ms-version" = "2018-11-09"
    "Authorization" = "Bearer $($accessToken)"   
}

if ($accessToken)
{
    Write-Host 'Got Access Token'
}
else 
{
    Write-Error 'Fail to get Access Token'    
}

$url = "https://$AdlsAccountName.dfs.core.windows.net/$($FileSystemName)?resource=filesystem"

$getFileSystem = Get-AzRmStorageContainer -Name $containerName -accountName $dataLakeStoreName -ResourceGroupName $resourceGroupName  -ErrorAction SilentlyContinue
if (!($getFileSystem)) {
    Write-Host 'Creating file system...'
$url = "https://$AdlsAccountName.dfs.core.windows.net/$($FileSystemName)?resource=filesystem" 
    Write-Host 'API url:', $url
    Invoke-RestMethod -Uri $url  -Headers $headers -Method Put

    Write-Host 'Created file system...'
    Write-Host 'Creating directory...'
}
else {
    Write-Host "Found directory '$AdlsAccountName', for storage account name '$FileSystemName'"
}

$adlsfolderlist = @(
    ('Data','/Data'),
    ('Failed','/Data/Error'),
    ('Processed','/Data/Processed')
)

for ($i=0; $i -lt $adlsfolderlist.count; $i++)
{

	$adlsfoldernametocreate = $adlsfolderlist[$i][0]
    $folderfullpathtocreate = -join($adlsfolderlist[$i][1],$adlsfoldernametocreate)
    
    $url = "https://$AdlsAccountName.dfs.core.windows.net/$($FileSystemName)$($adlsfolderlist[$i][1])?resource=directory"

    Write-Host 'directory creation URL:', $url
    Invoke-RestMethod -Uri $url  -Headers $headers -Method Put
}

Write-Host 'Created directories...'

Write-Host 'Assigning directories permissions...'

function Set-Permissions {
    param( $path, $permissions )
    Write-Host "Setting permissions for '$($path)'"

    $url = "https://$AdlsAccountName.dfs.core.windows.net/$($path)?action=setAccessControl"
    $headers = @{
        "x-ms-version" = "2018-11-09"
        "Authorization" = "Bearer $($accessToken)"
        "x-ms-acl" = "$($permissions)"
    }
    Write-Host 'Permissions URL:', $url
    Write-Host 'Permissions: ', $permissions
    Invoke-RestMethod -Uri $url  -Headers $headers -Method Patch
}

function Get-PermissionFormat {
    param( $permissionType, $objectId )
    $string = "$($permissionType):$($objectId):rwx"
    return $string
}

$groupPermissions = Get-PermissionFormat -permissionType "group" -objectId $groupId
$userPermissions = Get-PermissionFormat -permissionType "user" -objectId $userId
Set-Permissions -path "$($FileSystemName)/" -permissions "$($groupPermissions),$($userPermissions)"

for ($i=0; $i -lt $adlsfolderlist.count; $i++)
{

	$adlsfoldernametocreate = $adlsfolderlist[$i][0]
    $folderfullpathtocreate = -join($adlsfolderlist[$i][1],$adlsfoldernametocreate)
    
    $url = "https://$AdlsAccountName.dfs.core.windows.net/$($FileSystemName)$($adlsfolderlist[$i][1])?resource=directory"
    Set-Permissions -path "$($FileSystemName)$($adlsfolderlist[$i][1])" -permissions "$($groupPermissions),$($userPermissions),default:$($groupPermissions),default:$($userPermissions)"
}

