@description('Private DNS zone name that already exists')
param dnsZoneName string

@description('Resource ID of the AKS spoke VNet')
param aksSpokeVnetId string

@description('Link name for the AKS spoke VNet')
param aksSpokeLinkName string

@description('Tags to apply to the DNS link')
param tags object = {}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: dnsZoneName
}

resource aksSpokeVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  name: aksSpokeLinkName
  parent: privateDnsZone
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: aksSpokeVnetId
    }
  }
}

output privateDnsVnetLinkId string = aksSpokeVnetLink.id
