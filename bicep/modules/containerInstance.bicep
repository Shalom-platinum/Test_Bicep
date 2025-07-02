@description('Container Instance Name')
param containerInstanceName string

@description('Location')
param location string

@description('Private Subnet ID for ACI')
param subnetId string

@description('ACR Login Server')
param acrName string

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerInstanceName
  location: location
  properties: {
    containers: [
      {
        name: containerInstanceName
        properties: {
          image: '${acrName}/sample-app:latest'
          resources: {
            requests: {
              cpu: 1
              memoryInGb: 2
            }
          }
          ports: [
            {
              port: 80
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'tcp'
          port: 80
        }
      ]
    }
  }
}
