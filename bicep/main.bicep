targetScope = 'resourceGroup'

@description('Name of the resource group')
param resourceGroupName string

@description('Location for resources')
param location string

@description('VNET address space')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Public Subnet prefix')
param publicSubnetPrefix string = '10.0.1.0/24'

@description('Private Subnet prefix')
param privateACISubnetPrefix string = '10.0.2.0/24'

@description('Private AKS Subnet prefix')
param privateAKSSubnetPrefix string = '10.0.3.0/24'

@description('AKS Cluster Name')
param aksClusterName string

@description('ACR Name')
param acrName string

@description('Key Vault Name')
param keyVaultName string

@description('Azure SQL Server Name')
param sqlServerName string

@description('Azure SQL Database Name for API')
param sqlDatabaseNameAPI string

@description('Azure SQL Database Name for authentication')
param sqlDatabaseNameAUTH string

@description('Admin Username for SQL Server')
param sqlAdminUsername string

@description('Admin Password for SQL Server')
@secure()
param sqlAdminPassword string

@description('Container Instance Name')
param containerInstanceName string

@description('Service Principal ID')
param servicePrincipalId string

@secure()
@description('Service Principal Secret')
param servicePrincipalSecret string

// Resource Group (optional if deploying into existing one)
//resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
//  name: resourceGroupName
//  location: location
//}

// VNET + Subnets
module vnetModule './modules/vnet.bicep' = {
  name: 'vnetDeployment'
  //scope: resourceGroup
  params: {
    vnetName: 'myVnet'
    location: location
    addressPrefix: vnetAddressPrefix
    publicSubnetPrefix: publicSubnetPrefix
    privateACISubnetPrefix: privateACISubnetPrefix
    privateAKSSubnetPrefix: privateAKSSubnetPrefix
  }
}

// Azure Container Registry
module acrModule './modules/acr.bicep' = {
  name: 'acrDeployment'
  //scope: resourceGroup
  params: {
    acrName: acrName
    location: location
    sku: 'Standard'
  }
}

// Key Vault
module kvModule './modules/keyvault.bicep' = {
  name: 'kvDeployment'
  //scope: resourceGroup
  params: {
    keyVaultName: keyVaultName
    location: location
  }
}

// Azure SQL Server + Database + Private Endpoint
module sqlModule './modules/sql.bicep' = {
  name: 'sqlDeployment'
  //scope: resourceGroup
  params: {
    sqlServerName: sqlServerName
    sqlDatabaseNameAPI: sqlDatabaseNameAPI
    sqlDatabaseNameAUTH: sqlDatabaseNameAUTH
    location: location
    adminUsername: sqlAdminUsername
    adminPassword: sqlAdminPassword
    vnetId: vnetModule.outputs.vnetId
    privateACISubnetId: vnetModule.outputs.privateACISubnetId
  }
}

// resource aksSpDeploymentScript 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
//   name: 'aksSpDeploymentScript'
//   location: location
//   kind: 'AzurePowerShell'
//   identity: {
//     type: 'UserAssigned'
//     userAssignedIdentities: {
//       '${managedIdentity.id}': {}
//     }
//   }
//   properties: {
//     azPowerShellVersion: '8.3'
//     retentionInterval: 'P1D'
//     scriptContent: '''
//       $spName = "sp-${aksClusterName}"
      
//       # Create Service Principal
//       $sp = New-AzADServicePrincipal -DisplayName $spName
      
//       # Get credentials
//       $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp.Secret)
//       $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
      
//       # Create output object
//       $output = @{
//         clientId = $sp.ApplicationId
//         clientSecret = $plainPassword
//       }
      
//       # Convert to JSON and set as output
//       $DeploymentScriptOutputs = $output | ConvertTo-Json
//     '''
//   }
// }

// Try to reference existing managed identity
// resource existingManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
//   name: 'deployment-script-identity'
//   scope: resourceGroup()
// }

// Create managed identity if it doesn't exist
// resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
//   name: 'deployment-script-identity'
//   location: location
// }

// Try to reference existing role assignment
// resource existingRoleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' existing = {
//   name: guid(resourceGroup().id, managedIdentity.id, 'Application Administrator')
//   scope: resourceGroup()
// }

// Create role assignment if it doesn't exist
// resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
//   name: guid(resourceGroup().id, managedIdentity.id, 'Application Administrator')
//   properties: {
//     principalId: managedIdentity.properties.principalId
//     roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'f58310d9-a9f6-439a-9e8d-f62e7b41a168') // Application Administrator
//     principalType: 'ServicePrincipal'
//   }
// }

// AKS Cluster
module aksModule './modules/aks.bicep' = {
  name: 'aksDeployment'
  //scope: resourceGroup
  params: {
    aksClusterName: aksClusterName
    location: location
    acrName: acrModule.outputs.acrLoginServer
    privateAKSSubnetId: vnetModule.outputs.privateAKSSubnetId
    servicePrincipalId: servicePrincipalId //aksSpDeploymentScript.properties.outputs.clientId
    servicePrincipalSecret: servicePrincipalSecret //aksSpDeploymentScript.properties.outputs.clientSecret
  }
}

// Container Instance
module containerInstanceModule './modules/containerInstance.bicep' = {
  name: 'aciDeployment'
  //scope: resourceGroup
  params: {
    containerInstanceName: containerInstanceName
    location: location
    subnetId: vnetModule.outputs.privateACISubnetId
    acrName: acrModule.outputs.acrLoginServer
  }
}
