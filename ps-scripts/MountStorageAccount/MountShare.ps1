﻿function Mount-Share {

param(
 [Parameter(Mandatory=$True)]
 [string]$File
)

$JSON = Get-Content $File | Out-String | ConvertFrom-Json

# These commands require you to be logged into your Azure account, run Login-AzAccount if you haven't
# already logged in.
$storageAccount = Get-AzStorageAccount -ResourceGroupName $JSON.parameters.resourceGroupName.value -Name $JSON.parameters.storageAccountName.value
$storageAccountKeys = Get-AzStorageAccountKey -ResourceGroupName $JSON.parameters.resourceGroupName.value -Name $JSON.parameters.storageAccountName.value
$fileShare = Get-AzStorageShare -Context $storageAccount.Context | Where-Object { 
    $_.Name -eq $JSON.parameters.fileShareName.value -and $_.IsSnapshot -eq $false
}

if ($fileShare -eq $null) {
    throw [System.Exception]::new("Azure file share not found")
}

# The value given to the root parameter of the New-PSDrive cmdlet is the host address for the storage account, 
# <storage-account>.file.core.windows.net for Azure Public Regions. $fileShare.StorageUri.PrimaryUri.Host is 
# used because non-Public Azure regions, such as sovereign clouds or Azure Stack deployments, will have different 
# hosts for Azure file shares (and other storage resources).
$password = ConvertTo-SecureString -String $storageAccountKeys[0].Value -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList "AZURE\$($storageAccount.StorageAccountName)", $password
New-PSDrive -Name $JSON.parameters.PSDriveLetter.value -PSProvider FileSystem -Root "\\$($fileShare.StorageUri.PrimaryUri.Host)\$($fileShare.Name)" -Credential $credential -Persist

}

$work = mount-share -File .\mountShare.parameter.json
Set-Location -path ($work.name + ":\") 
New-Item -ItemType Directory -Path ($work.name + ":\Test")
