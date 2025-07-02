@description('Azure Container Registry name')
param acrName string

@description('Location')
param location string

@description('SKU for ACR')
param sku string = 'Standard'

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrId string = acr.id
