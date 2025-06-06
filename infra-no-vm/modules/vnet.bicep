@description('The name of the virtual network')
param vnetName string

@description('The address space for the virtual network')
param vnetAddress string

@description('Array of subnet definitions')
param subnetDef array

@description('The resource ID of the network security group')
param nsgId string

@description('The location where the virtual network will be created')
param location string = resourceGroup().location

@description('Tags to apply to the virtual network')
param tags object = {}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-07-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [for subnet in subnetDef: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
        networkSecurityGroup: {
          id: nsgId
        }
        delegations: subnet.?delegations ?? []
      }
    }]
  }
}

@description('The name of the created virtual network')
output vnetName string = virtualNetwork.name

@description('The resource ID of the created virtual network')
output vnetId string = virtualNetwork.id

@description('The subnet resource IDs')
output subnetIds array = [for i in range(0, length(subnetDef)): virtualNetwork.properties.subnets[i].id]
