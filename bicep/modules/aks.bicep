@description('AKS Cluster Name')
param aksClusterName string

@description('Location')
param location string

@description('Private subnet ID')
param privateAKSSubnetId string

@description('ACR Name')
param acrName string

@description('Service Principal ID')
param servicePrincipalId string

@secure()
@description('Service Principal Secret')
param servicePrincipalSecret string

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-02-01' = {
  name: aksClusterName
  location: location
  properties: {
    servicePrincipalProfile: {
      clientId: servicePrincipalId
      secret: servicePrincipalSecret
    }
    dnsPrefix: toLower(aksClusterName)
    enableRBAC: true
    kubernetesVersion: '1.31.2'
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      serviceCidr: '10.0.3.0/24'
      dnsServiceIP: '10.0.3.10'
    }
    apiServerAccessProfile: {
      enablePrivateCluster: true
    }
    agentPoolProfiles: [
      {
        name: 'systempool'
        count: 2
        vmSize: 'Standard_A2_v2'
        mode: 'System'
        osDiskSizeGB: 100
        vnetSubnetID: privateAKSSubnetId
      }
      {
        name: 'userpool'
        count: 2
        minCount: 2
        maxCount: 5
        enableAutoScaling: true
        vmSize: 'Standard_DS2_v2'
        mode: 'User'
        vnetSubnetID: privateAKSSubnetId
      }
    ]
    addonProfiles: {
      omsagent: {
        enabled: true
      }
    }
    aadProfile: {
      managed: true
      enableAzureRBAC: true
    }
  }
}

output aksClusterId string = aksCluster.id
