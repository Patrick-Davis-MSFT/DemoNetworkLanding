@description('The name of the network security group')
param nsgName string

@description('The location where the network security group will be created')
param location string = resourceGroup().location

@description('Tags to apply to the network security group')
param tags object = {}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-07-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

@description('The name of the created network security group')
output nsgName string = networkSecurityGroup.name

@description('The resource ID of the created network security group')
output nsgId string = networkSecurityGroup.id
