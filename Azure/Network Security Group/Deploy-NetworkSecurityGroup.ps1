#-- ======================================================================
#-- Az PowerShell Script
#-- ======================================================================
#-- ======================================================================
#-- Author:      Logan Talbot (https://www.logantalbot.com/)
#-- Create Date: 2020/02/05
#-- Description: Create Network Security Group (NSG) if it does not exist. 
#-- ======================================================================
#-- ======================================================================

#Requires -Version 3.0

Param(
    [string] [Parameter(Mandatory=$true)] $NsgName,
    [string] [Parameter(Mandatory=$true)] $Location,
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName
)

Write-Output 'Network Security Group Name: ',$NsgName,'Location: ',$Location,'Resource Group Name: ', $ResourceGroupName

$nsg=Get-AzNetworkSecurityGroup -Name $NsgName -ResourceGroupName $ResourceGroupName

if (!($nsg)) {
    Write-Output 'Resource Does not exist, creating Network Security Group...'
    New-AzNetworkSecurityGroup -Name $NsgName -Location $Location -ResourceGroupName $ResourceGroupName -ErrorAction SilentlyContinue
    Write-Output 'Created NSG...'
}
else {
    Write-Output 'Network Security Group Does exist...'
}

Write-Output 'Script Complete...'