// =====================================================================
// Azure Bastion and Virtual Machine Module
// =====================================================================
// This module creates Azure Bastion for secure VM access and deploys 
// a Windows Virtual Machine with credentials stored in Key Vault.
// =====================================================================

@description('The name of the virtual network where the bastion subnet will be created')
param vnetName string

@description('The bastion subnet definition')
param bastionSubnet object

@description('The VM subnet ID where the virtual machine will be deployed')
param vmSubnetId string

@description('Azure region for resource deployment')
param location string = resourceGroup().location

@description('Resource token for unique naming')
param resourceToken string

@description('Tags to apply to resources')
param tags object = {}

@description('VM Administrator username')
param vmAdminUsername string = 'openseasmeuser'

@description('VM Administrator password')
@secure()
param vmAdminPassword string

@description('VM size/SKU')
param vmSize string = 'Standard_DS2_v3'

@description('Key Vault resource ID for storing secrets')
param keyVaultId string

@description('Windows OS version for the VM')
@allowed([
  '2019-datacenter-gensecond'
  '2022-datacenter-g2'
  '2022-datacenter-azure-edition'
])
param windowsOSVersion string = '2022-datacenter-g2'

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

// Create public IP for Azure Bastion
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: 'pip-bastion-${resourceToken}'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Create Azure Bastion Host
resource bastionHost 'Microsoft.Network/bastionHosts@2024-07-01' = {
  name: 'bastion-${resourceToken}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnetResource.id
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

// Create Network Interface for VM
resource vmNetworkInterface 'Microsoft.Network/networkInterfaces@2024-07-01' = {
  name: 'nic-vm-${resourceToken}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vmSubnetId
          }
        }
      }
    ]
  }
}

// Create Windows Virtual Machine
resource windowsVM 'Microsoft.Compute/virtualMachines@2024-07-01' = {
  name: 'vm-${resourceToken}'
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: 'vm-${resourceToken}'
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
          automaticByPlatformSettings: {
            rebootSetting: 'IfRequired'
          }
        }
      }
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
      osDisk: {
        name: 'osdisk-vm-${resourceToken}'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNetworkInterface.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Reference existing Key Vault to store VM credentials
resource existingKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: last(split(keyVaultId, '/'))
}

// Store VM admin password in Key Vault
resource vmPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'vm-admin-password'
  parent: existingKeyVault
  properties: {
    value: vmAdminPassword
    attributes: {
      enabled: true
    }
  }
}

// Store VM admin username in Key Vault
resource vmUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  name: 'vm-admin-username'
  parent: existingKeyVault
  properties: {
    value: vmAdminUsername
    attributes: {
      enabled: true
    }
  }
}

// Outputs
@description('The resource ID of the created bastion subnet')
output bastionSubnetId string = bastionSubnetResource.id

@description('The name of the created bastion subnet')
output bastionSubnetName string = bastionSubnetResource.name

@description('The resource ID of the Azure Bastion Host')
output bastionHostId string = bastionHost.id

@description('The name of the Azure Bastion Host')
output bastionHostName string = bastionHost.name

@description('The resource ID of the Virtual Machine')
output vmId string = windowsVM.id

@description('The name of the Virtual Machine')
output vmName string = windowsVM.name

@description('The computer name of the Virtual Machine')
output vmComputerName string = windowsVM.properties.osProfile.computerName
