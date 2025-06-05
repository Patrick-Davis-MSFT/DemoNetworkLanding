@description('Private DNS zone name to create')
param dnsZoneName string

@description('The resource ID of the hub virtual network')
param hubVnetId string

@description('The resource ID of the permanent services virtual network')
param permServVnetId string

@description('The resource ID of the application virtual network')
param appVnetId string

@description('Tags to apply to the private DNS zone')
param tags object = {}

@description('Resource token for unique naming')
param resourceToken string

// Create private DNS zone
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: dnsZoneName
  location: 'global'
  tags: tags
  properties: {}
}

// Create virtual network link for hub VNet
resource hubVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'link-hub-${resourceToken}'
  parent: privateDnsZone
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetId
    }
  }
}

// Create virtual network link for permanent services VNet
resource permServVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'link-permserv-${resourceToken}'
  parent: privateDnsZone
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: permServVnetId
    }
  }
}

// Create virtual network link for application VNet
resource appVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: 'link-app-${resourceToken}'
  parent: privateDnsZone
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: appVnetId
    }
  }
}

@description('The resource ID of the created private DNS zone')
output privateDnsZoneId string = privateDnsZone.id

@description('The name of the created private DNS zone')
output privateDnsZoneName string = privateDnsZone.name
