targetScope = 'subscription'

param dnsNameList array = [
  'privatelink.vaultcore.azure.net'
  'privatelink.queue.core.windows.net'
  'privatelink.table.core.windows.net'
  'privatelink.file.core.windows.net'
  'privatelink.blob.core.windows.net'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.documents.azure.com'
  'privatelink.mongo.cosmos.azure.com'
  'privatelink.mongocluster.cosmos.azure.com'
  'privatelink.redis.cache.windows.net'
  'privatelink.services.ai.azure.com'

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

param  resourceGroupName string
param location string
var tags = { License: 'MIT' }
var resourceToken = toLower(uniqueString(subscription().id, resourceGroupName, location))

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
