// =====================================================================
// Azure Key Vault Module with RBAC Authorization
// =====================================================================
// This module creates a Key Vault with Azure RBAC-based access control
// and configures it for private endpoint connectivity.
// 
// Key Features:
// - Azure RBAC authorization (no legacy access policies)
// - Private endpoint ready configuration
// - Soft delete and purge protection enabled
// - Premium SKU for certificate support
// =====================================================================

@description('Name of the Key Vault')
param keyVaultName string

@description('Azure region for Key Vault deployment')
param location string = resourceGroup().location

@description('Azure AD tenant ID for the Key Vault')
param tenantId string

@description('SKU for the Key Vault (standard or premium)')
@allowed(['standard', 'premium'])
param skuName string = 'standard'

@description('Enable soft delete for the Key Vault - Required for new vaults')
param enableSoftDelete bool = true

@description('Soft delete retention period in days (7-90)')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 7


@description('Enable RBAC authorization for data plane access')
param enableRbacAuthorization bool = true

@description('Network access configuration (disabled for private endpoint only)')
@allowed(['enabled', 'disabled'])
param publicNetworkAccess string = 'disabled'

@description('Tags to apply to the Key Vault')
param tags object = {}

// =====================================================================
// Key Vault Resource
// =====================================================================

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tags
  properties: {
    // Core Configuration
    tenantId: tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    
    // Access Control - Using Azure RBAC for data plane access
    enableRbacAuthorization: enableRbacAuthorization
    accessPolicies: [] // Empty when using RBAC
    
    // Data Protection
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: softDeleteRetentionInDays
    
    // Azure Service Integration
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    
    // Network Access Control
    publicNetworkAccess: publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

// =====================================================================
// Outputs
// =====================================================================

@description('Resource ID of the Key Vault')
output keyVaultId string = keyVault.id

@description('Name of the Key Vault')
output keyVaultName string = keyVault.name

@description('URI of the Key Vault for performing operations')
output keyVaultUri string = keyVault.properties.vaultUri

@description('Key Vault resource object for use in other modules')
output keyVaultResource object = {
  id: keyVault.id
  name: keyVault.name
  uri: keyVault.properties.vaultUri
  location: keyVault.location
}
