// =====================================================================
// Private Endpoint Module for Azure Key Vault
// =====================================================================
// This module creates a private endpoint for Azure Key Vault and
// integrates it with the existing private DNS infrastructure.
// 
// Key Features:
// - Private endpoint for Key Vault vault service
// - DNS integration with private DNS zone
// - Network interface configuration
// - Private IP allocation from specified subnet
// =====================================================================

@description('Name of the private endpoint')
param privateEndpointName string

@description('Azure region for private endpoint deployment')
param location string = resourceGroup().location

@description('Resource ID of the Key Vault to connect to')
param keyVaultId string

@description('Resource ID of the subnet for private endpoint deployment')
param subnetId string

@description('Resource ID of the private DNS zone')
param privateDnsZoneId string

@description('Tags to apply to the private endpoint')
param tags object = {}

// =====================================================================
// Private Endpoint Resource
// =====================================================================

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-connection'
        properties: {
          privateLinkServiceId: keyVaultId
          groupIds: [
            'vault'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Private endpoint connection for Key Vault'
          }
        }
      }
    ]
    customNetworkInterfaceName: '${privateEndpointName}-nic'
  }
}

// =====================================================================
// Private DNS Zone Group for automatic DNS integration
// =====================================================================

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'vault-azure-net'
        properties: {
          privateDnsZoneId: privateDnsZoneId
        }
      }
    ]
  }
}

// =====================================================================
// Outputs
// =====================================================================

@description('Resource ID of the private endpoint')
output privateEndpointId string = privateEndpoint.id

@description('Name of the private endpoint')
output privateEndpointName string = privateEndpoint.name

@description('Private IP address of the Key Vault private endpoint')
output privateIpAddress string = privateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]

@description('Network interface ID of the private endpoint')
output networkInterfaceId string = privateEndpoint.properties.networkInterfaces[0].id
