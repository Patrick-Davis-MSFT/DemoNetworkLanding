@description('The name of the virtual network where the gateway subnet will be created')
param vnetName string

@description('The gateway subnet definition')
param gatewaySubnet object

// Reference the existing virtual network
resource existingVnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: vnetName
}

// Create the gateway subnet
resource gatewaySubnetResource 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: gatewaySubnet.name
  parent: existingVnet
  properties: {
    addressPrefix: gatewaySubnet.addressPrefix
    // Gateway subnet typically doesn't need NSG
    // serviceEndpoints and delegations are not typically used with gateway subnets
  }
}

@description('The resource ID of the created gateway subnet')
output gatewaySubnetId string = gatewaySubnetResource.id

@description('The name of the created gateway subnet')
output gatewaySubnetName string = gatewaySubnetResource.name
