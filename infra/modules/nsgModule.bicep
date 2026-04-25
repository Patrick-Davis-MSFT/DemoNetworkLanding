@description('The name of the network security group')
param nsgName string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2024-07-01' existing = {
  name: nsgName
}

resource allowApimClientHttp 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-Client-HTTP'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow client communication to API Management over HTTP (external mode).'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: 'Internet'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 100
    direction: 'Inbound'
  }
}

resource allowApimClientHttps 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-Client-HTTPS'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow client communication to API Management over HTTPS (external mode).'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'Internet'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 101
    direction: 'Inbound'
  }
}

resource allowApimManagement3443 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-Management-3443'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow APIM management endpoint traffic from ApiManagement service tag.'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '3443'
    sourceAddressPrefix: 'ApiManagement'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 102
    direction: 'Inbound'
  }
}

resource allowApimAzureLb6390 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-AzureLB-6390'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow Azure infrastructure load balancer traffic for APIM.'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '6390'
    sourceAddressPrefix: 'AzureLoadBalancer'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 103
    direction: 'Inbound'
  }
}

resource allowApimAtm443 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-ATM-443'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow Azure Traffic Manager routing traffic for APIM external mode.'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'AzureTrafficManager'
    destinationAddressPrefix: 'VirtualNetwork'
    access: 'Allow'
    priority: 104
    direction: 'Inbound'
  }
}

resource allowApimOutInternet80 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-Out-Internet-80'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow APIM outbound HTTP for certificate validation and management.'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '80'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'Internet'
    access: 'Allow'
    priority: 110
    direction: 'Outbound'
  }
}

resource allowApimOutStorage443 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-Out-Storage-443'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow APIM outbound traffic to Azure Storage dependencies.'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'Storage'
    access: 'Allow'
    priority: 111
    direction: 'Outbound'
  }
}

resource allowApimOutSql1433 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-Out-SQL-1433'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow APIM outbound traffic to Azure SQL dependencies.'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '1433'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'SQL'
    access: 'Allow'
    priority: 112
    direction: 'Outbound'
  }
}

resource allowApimOutKeyVault443 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-Out-KeyVault-443'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow APIM outbound traffic to Azure Key Vault dependencies.'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRange: '443'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'AzureKeyVault'
    access: 'Allow'
    priority: 113
    direction: 'Outbound'
  }
}

resource allowApimOutMonitor 'Microsoft.Network/networkSecurityGroups/securityRules@2024-07-01' = {
  name: 'Allow-APIM-Out-Monitor-443-1886'
  parent: networkSecurityGroup
  properties: {
    description: 'Allow APIM outbound diagnostics and metrics to Azure Monitor.'
    protocol: 'Tcp'
    sourcePortRange: '*'
    destinationPortRanges: [
      '1886'
      '443'
    ]
    sourceAddressPrefix: 'VirtualNetwork'
    destinationAddressPrefix: 'AzureMonitor'
    access: 'Allow'
    priority: 114
    direction: 'Outbound'
  }
}

@description('The name of the network security group')
output nsgName string = networkSecurityGroup.name

@description('The resource ID of the network security group')
output nsgId string = networkSecurityGroup.id
