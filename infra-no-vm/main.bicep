targetScope = 'subscription'

param dnsNameList array = [
  'privatelink.vaultcore.azure.net'
  'privatelink.queue.${environment().suffixes.storage}'
  'privatelink.table.${environment().suffixes.storage}'
  'privatelink.file.${environment().suffixes.storage}'
  'privatelink.blob.${environment().suffixes.storage}'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.documents.azure.com'
  'privatelink.mongo.cosmos.azure.com'
  'privatelink.mongocluster.cosmos.azure.com'
  'privatelink.redis.cache.windows.net'
  'privatelink.services.ai.azure.com'
  'privatelink.search.windows.net'

]

param hubVnetName string
param hubVnetAddress string
param nsgHubName string
param hubSubnetDef array

param permServVnetName string
param permServVnetAddress string 
param permServNSGName string
param permServSnetDef array

param appVnetName string
param appVnetAddress string
param appNSGName string
param appSnetDef array

param gatewaySubnet object
param bastionSubnet object

param keyVaultName string
param keyVaultSkuName string = 'standard'
param enableKeyVault bool = true

param resourceGroupName string
param location string
var tags = { License: 'MIT' }
var resourceToken = toLower(substring(uniqueString(subscription().id, resourceGroupName, location), 0, 5))

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module nsgHub './modules/nsgModule.bicep' = {
  name: 'nsgHub'
  scope: rg
  params: {
    nsgName: '${nsgHubName}-${resourceToken}'
    location: location 
    tags: {}
  }
}


module nsgPermServices './modules/nsgModule.bicep' = {
  name: 'nsgPermServices'
  scope: rg
  params: {
    nsgName: '${permServNSGName}-${resourceToken}'
    location: location 
    tags: {}
  }
}

module nsgApp './modules/nsgModule.bicep' = {
  name: 'appNSGName'
  scope: rg
  params: {
    nsgName: '${appNSGName}-${resourceToken}'
    location: location 
    tags: {}
  }
}

module hubVnet './modules/vnet.bicep' = {
  name: 'hubVnet'
  scope: rg
  params: {
    vnetName: '${hubVnetName}-${resourceToken}'
    vnetAddress: hubVnetAddress
    subnetDef: hubSubnetDef
    nsgId: nsgHub.outputs.nsgId
    location: location
    tags: tags
  }
}

module hubGatewaySubnet './modules/gatewaySubnet.bicep' = {
  name: 'hubGatewaySubnet'
  scope: rg
  params: {
    vnetName: hubVnet.outputs.vnetName
    gatewaySubnet: gatewaySubnet
  }
}

module hubBastionSubnet './modules/bastion.bicep' = {
  name: 'hubBastionSubnet'
  scope: rg
  dependsOn: [
    hubGatewaySubnet
  ]
  params: {
    vnetName: hubVnet.outputs.vnetName
    bastionSubnet: bastionSubnet
  }
}

module permServVnet './modules/vnet.bicep' = {
  name: 'permServVnet'
  scope: rg
  params: {
    vnetName: '${permServVnetName}-${resourceToken}'
    vnetAddress: permServVnetAddress
    subnetDef: permServSnetDef
    nsgId: nsgPermServices.outputs.nsgId
    location: location
    tags: tags
  }
}

module appVnet './modules/vnet.bicep' = {
  name: 'appVnet'
  scope: rg
  params: {
    vnetName: '${appVnetName}-${resourceToken}'
    vnetAddress: appVnetAddress
    subnetDef: appSnetDef
    nsgId: nsgApp.outputs.nsgId
    location: location
    tags: tags
  }
}

module vnetPeerings './modules/vnetPeerings.bicep' = {
  name: 'vnetPeerings'
  scope: rg
  params: {
    hubVnetId: hubVnet.outputs.vnetId
    hubVnetName: hubVnet.outputs.vnetName
    permServVnetId: permServVnet.outputs.vnetId
    permServVnetName: permServVnet.outputs.vnetName
    appVnetId: appVnet.outputs.vnetId
    appVnetName: appVnet.outputs.vnetName
  }
}

module privateDnsZones './modules/privateDNS.bicep' = [for dnsZoneName in dnsNameList: {
  name: 'privateDns-${replace(dnsZoneName, '.', '-')}'
  scope: rg
  params: {
    dnsZoneName: dnsZoneName
    hubVnetId: hubVnet.outputs.vnetId
    permServVnetId: permServVnet.outputs.vnetId
    appVnetId: appVnet.outputs.vnetId
    resourceToken: resourceToken
    tags: tags
  }
}]

// =====================================================================
// Key Vault with Private Endpoint Integration
// =====================================================================

module keyVault './modules/keyVault.bicep' = if (enableKeyVault) {
  name: 'keyVault'
  scope: rg
  params: {
    keyVaultName: '${keyVaultName}-${resourceToken}'
    location: location
    tenantId: tenant().tenantId
    skuName: keyVaultSkuName
    tags: tags
  }
  dependsOn: [
    hubVnet
  ]
}

module keyVaultPrivateEndpoint './modules/keyVaultPrivateEndpoint.bicep' = if (enableKeyVault) {
  name: 'keyVaultPrivateEndpoint'
  scope: rg
  params: {
    privateEndpointName: '${keyVaultName}-pe-${resourceToken}'
    location: location
    keyVaultId: keyVault.outputs.keyVaultId
    subnetId: '${hubVnet.outputs.vnetId}/subnets/${hubSubnetDef[0].name}'
    privateDnsZoneId: privateDnsZones[0].outputs.privateDnsZoneId
    tags: tags
  }
  dependsOn: [
    privateDnsZones
  ]
}
