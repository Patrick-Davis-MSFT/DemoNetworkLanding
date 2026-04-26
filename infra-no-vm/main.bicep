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
  'privatelink.redis.azure.net'

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

param aksSpokeVnetName string
param aksSpokeVnetAddress string
param aksSpokeNSGName string
param aksSpokeSnetDef array
param aksSpokeLocation string = 'eastus2'

param gatewaySubnet object
param bastionSubnet object

param keyVaultName string
param keyVaultSkuName string = 'standard'
param enableKeyVault bool = true

param resourceGroupName string
param location string
param createOnlyAksSpoke bool = true
var tags = { License: 'MIT' }
var resourceToken = toLower(substring(uniqueString(subscription().id, resourceGroupName, location), 0, 5))
var hubExistingVnetId = resourceId(subscription().subscriptionId, resourceGroupName, 'Microsoft.Network/virtualNetworks', hubVnetName)
var permServExistingVnetId = resourceId(subscription().subscriptionId, resourceGroupName, 'Microsoft.Network/virtualNetworks', permServVnetName)
var appExistingVnetId = resourceId(subscription().subscriptionId, resourceGroupName, 'Microsoft.Network/virtualNetworks', appVnetName)
var hubSubnetNsgNames = [for subnet in hubSubnetDef: string(subnet.nsgName)]
var permServSubnetNsgNames = [for subnet in permServSnetDef: string(subnet.nsgName)]
var appSubnetNsgNames = [for subnet in appSnetDef: string(subnet.nsgName)]
var aksSubnetNsgNames = [for subnet in aksSpokeSnetDef: string(subnet.nsgName)]
var modeledNsgNames = union(
  [
    nsgHubName
    permServNSGName
    appNSGName
    aksSpokeNSGName
  ],
  hubSubnetNsgNames,
  permServSubnetNsgNames,
  appSubnetNsgNames,
  aksSubnetNsgNames
)

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
}

module nsgRules './modules/nsgModule.bicep' = [for nsgName in modeledNsgNames: {
  name: 'nsgRules-${uniqueString(nsgName)}'
  scope: rg
  params: {
    nsgName: nsgName
  }
}]

module aksSpokeVnet './modules/vnet.bicep' = {
  name: 'aksSpokeVnet'
  scope: rg
  params: {
    vnetName: aksSpokeVnetName
    vnetAddress: aksSpokeVnetAddress
    subnetDef: aksSpokeSnetDef
    nsgId: resourceId(subscription().subscriptionId, resourceGroupName, 'Microsoft.Network/networkSecurityGroups', aksSpokeNSGName)
    location: aksSpokeLocation
    tags: tags
  }
}

module aksSpokePeerings './modules/vnetPeeringsAksSpoke.bicep' = {
  name: 'aksSpokePeerings'
  scope: rg
  params: {
    hubVnetId: hubExistingVnetId
    hubVnetName: hubVnetName
    permServVnetId: permServExistingVnetId
    permServVnetName: permServVnetName
    appVnetId: appExistingVnetId
    appVnetName: appVnetName
    aksSpokeVnetId: aksSpokeVnet.outputs.vnetId
    aksSpokeVnetName: aksSpokeVnet.outputs.vnetName
  }
}

module aksSpokePrivateDnsLinks './modules/privateDnsLinkAksSpoke.bicep' = [for dnsZoneName in dnsNameList: {
  name: 'aksSpokeDnsLink-${replace(dnsZoneName, '.', '-')}'
  scope: rg
  params: {
    dnsZoneName: dnsZoneName
    aksSpokeVnetId: aksSpokeVnet.outputs.vnetId
    aksSpokeLinkName: 'link-aks-${aksSpokeVnetName}'
    tags: tags
  }
}]

module keyVault './modules/keyVault.bicep' = if (enableKeyVault) {
  name: 'keyVault'
  scope: rg
  params: {
    keyVaultName: keyVaultName
    location: location
    tenantId: tenant().tenantId
    skuName: keyVaultSkuName
    tags: tags
  }
}
