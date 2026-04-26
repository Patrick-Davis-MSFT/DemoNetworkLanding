targetScope = 'subscription'

@description('Name of the existing resource group that contains the network')
param resourceGroupName string

@description('Azure region used for Bastion and VM resources')
param location string

@description('Existing hub VNet name created by infra-no-vm deployment')
param hubVnetName string

@description('Hub subnet definitions from infra-no-vm parameters. The first subnet is used for VM placement.')
param hubSubnetDef array

@description('Bastion subnet definition object from infra-no-vm parameters')
param bastionSubnet object

@description('Key Vault name for storing VM credentials')
param keyVaultName string

@description('VM Administrator username')
param vmAdminUsername string = 'openseasmeuser'

@description('VM Administrator password')
@secure()
param vmAdminPassword string

@description('VM size/SKU')
param vmSize string = 'Standard_DS1_v2'

@description('Windows OS version for the VM')
@allowed([
  '2019-datacenter-gensecond'
  '2022-datacenter-g2'
  '2022-datacenter-azure-edition'
])
param windowsOSVersion string = '2022-datacenter-g2'

var tags = {
  License: 'MIT'
}
var resourceToken = toLower(substring(uniqueString(subscription().id, resourceGroupName, location), 0, 5))
var vmSubnetName = string(hubSubnetDef[0].name)
var vmSubnetId = resourceId(subscription().subscriptionId, resourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', hubVnetName, vmSubnetName)
var keyVaultId = resourceId(subscription().subscriptionId, resourceGroupName, 'Microsoft.KeyVault/vaults', keyVaultName)

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' existing = {
  name: resourceGroupName
}

module bastionAndVm './modules/bastion.bicep' = {
  name: 'bastionAndVm'
  scope: rg
  params: {
    vnetName: hubVnetName
    bastionSubnet: bastionSubnet
    vmSubnetId: vmSubnetId
    location: location
    resourceToken: resourceToken
    tags: tags
    vmAdminUsername: vmAdminUsername
    vmAdminPassword: vmAdminPassword
    vmSize: vmSize
    windowsOSVersion: windowsOSVersion
    keyVaultId: keyVaultId
  }
}

output bastionHostId string = bastionAndVm.outputs.bastionHostId
output bastionHostName string = bastionAndVm.outputs.bastionHostName
output vmId string = bastionAndVm.outputs.vmId
output vmName string = bastionAndVm.outputs.vmName
