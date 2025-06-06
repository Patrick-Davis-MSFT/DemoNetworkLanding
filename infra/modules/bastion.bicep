@description('The name of the virtual network where the bastion subnet will be created')
param vnetName string

@description('The bastion subnet definition')
param bastionSubnet object

// Reference the existing virtual network
resource existingVnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: vnetName
}

// Create the bastion subnet
resource bastionSubnetResource 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' = {
  name: bastionSubnet.name
  parent: existingVnet
  properties: {
    addressPrefix: bastionSubnet.addressPrefix
    // Bastion subnet typically doesn't need NSG
    // Azure Bastion manages its own security rules
  }
}

@description('The resource ID of the created bastion subnet')
output bastionSubnetId string = bastionSubnetResource.id

@description('The name of the created bastion subnet')
output bastionSubnetName string = bastionSubnetResource.name
