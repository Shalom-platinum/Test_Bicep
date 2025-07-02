@description('SQL Server Name')
param sqlServerName string

@description('SQL Database Name')
param sqlDatabaseNameAPI string

@description('SQL Database Name')
param sqlDatabaseNameAUTH string

@description('Location')
param location string

@description('SQL admin username')
param adminUsername string

@secure()
@description('SQL admin password')
param adminPassword string

@description('VNET ID')
param vnetId string

@description('Private Subnet ID')
param privateACISubnetId string

resource sqlServer 'Microsoft.Sql/servers@2022-05-01-preview' = {
  name: sqlServerName
  location: location
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    administratorLogin: adminUsername
    administratorLoginPassword: adminPassword
    version: '12.0'
  }
}

resource APIsqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: '${sqlServerName}-${sqlDatabaseNameAPI}'
  parent: sqlServer
  location: location
  properties: { 
  }
}

resource AUTHsqlDatabase 'Microsoft.Sql/servers/databases@2022-05-01-preview' = {
  name: '${sqlServerName}-${sqlDatabaseNameAUTH}'
  parent: sqlServer
  location: location
  properties: {
  }
}


resource privateEndpoint 'Microsoft.Network/privateEndpoints@2022-07-01' = {
  name: '${sqlServerName}-privateendpoint'
  location: location
  properties: {
    subnet: {
      id: privateACISubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'sqlserverConnection'
        properties: {
          privateLinkServiceId: sqlServer.id
          groupIds: [
            'sqlServer'
          ]
        }
      }
    ]
  }
}

output sqlServerFullyQualifiedDomainName string = sqlServer.properties.fullyQualifiedDomainName
