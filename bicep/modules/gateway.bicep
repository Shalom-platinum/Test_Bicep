@description('Name of the Application Gateway')
param gatewayName string

@description('Location for the Application Gateway')
param location string = resourceGroup().location

@description('Name of the virtual network')
param vnetName string

@description('Name of the subnet for Application Gateway')
param subnetName string

@description('SKU name for the Application Gateway')
@allowed([
  'Basic'
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
])
param skuName string = 'Basic'

@description('SKU tier for the Application Gateway')
@allowed([
  'Basic'
  'Standard'
])
param skuTier string = 'Basic'

@description('Number of instances for the Application Gateway')
@minValue(1)
@maxValue(10)
param capacity int = 1

// Public IP address resource
resource publicIP 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: '${gatewayName}-pip'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

// Application Gateway resource
resource applicationGateway 'Microsoft.Network/applicationGateways@2021-05-01' = {
  name: gatewayName
  location: location
  properties: {
    sku: {
      name: skuName
      tier: skuTier
      capacity: capacity
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', VnetName, SubnetName) // Replace with your subnet ID
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGwPublicFrontendIp'
        properties: {
          publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'defaultBackendPool'
        properties: {}
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'defaultHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
        }
      }
    ]
    httpListeners: [
      {
        name: 'defaultListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', gatewayName, 'appGwPublicFrontendIp')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', gatewayName, 'port_80')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'defaultRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', gatewayName, 'defaultListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', gatewayName, 'defaultBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', gatewayName, 'defaultHttpSettings')
          }
        }
      }
    ]
  }
}

@description('Application Gateway ID')
output gatewayId string = applicationGateway.id

@description('Public IP Address ID')
output publicIPId string = publicIP.id

@description('Public IP Address')
output publicIPAddress string = publicIP.properties.ipAddress
