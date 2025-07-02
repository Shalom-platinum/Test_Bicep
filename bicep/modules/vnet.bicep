@description('Name of the virtual network')
param vnetName string

@description('Resource location')
param location string

@description('VNET address space')
param addressPrefix string

@description('Public subnet address prefix')
param publicSubnetPrefix string

@description('Private subnet address prefix')
param privateACISubnetPrefix string

@description('Private subnet address prefix')
param privateAKSSubnetPrefix string

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'public-subnet'
        properties: {
          addressPrefix: publicSubnetPrefix
        }
      }
      {
        name: 'aci-subnet'
        properties: {
          addressPrefix: privateACISubnetPrefix
        }
      }
      {
        name: 'aks-subnet'
        properties: {
          addressPrefix: privateAKSSubnetPrefix
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output publicSubnetId string = vnet.properties.subnets[0].id
output privateACISubnetId string = vnet.properties.subnets[1].id
output privateAKSSubnetId string = vnet.properties.subnets[2].id
