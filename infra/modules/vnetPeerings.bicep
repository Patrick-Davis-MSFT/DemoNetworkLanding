@description('The resource ID of the hub virtual network')
param hubVnetId string

@description('The name of the hub virtual network')
param hubVnetName string

@description('The resource ID of the permanent services virtual network')
param permServVnetId string

@description('The name of the permanent services virtual network')
param permServVnetName string

@description('The resource ID of the application virtual network')
param appVnetId string

@description('The name of the application virtual network')
param appVnetName string

@description('The resource ID of the AKS spoke virtual network')
param aksSpokeVnetId string

@description('The name of the AKS spoke virtual network')
param aksSpokeVnetName string

// Hub to PermServ peering
resource hubToPermServPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${hubVnetName}/peer-to-${permServVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: permServVnetId
    }
  }
}

// PermServ to Hub peering
resource permServToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${permServVnetName}/peer-to-${hubVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

// Hub to App peering
resource hubToAppPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${hubVnetName}/peer-to-${appVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: appVnetId
    }
  }
}

// App to Hub peering
resource appToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${appVnetName}/peer-to-${hubVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

// PermServ to App peering
resource permServToAppPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${permServVnetName}/peer-to-${appVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: appVnetId
    }
  }
}

// App to PermServ peering
resource appToPermServPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${appVnetName}/peer-to-${permServVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: permServVnetId
    }
  }
}

// Hub to AKS spoke peering
resource hubToAksSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${hubVnetName}/peer-to-${aksSpokeVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: aksSpokeVnetId
    }
  }
}

// AKS spoke to Hub peering
resource aksSpokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${aksSpokeVnetName}/peer-to-${hubVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

// PermServ to AKS spoke peering
resource permServToAksSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${permServVnetName}/peer-to-${aksSpokeVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: aksSpokeVnetId
    }
  }
}

// AKS spoke to PermServ peering
resource aksSpokeToPermServPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${aksSpokeVnetName}/peer-to-${permServVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: permServVnetId
    }
  }
}

// App to AKS spoke peering
resource appToAksSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${appVnetName}/peer-to-${aksSpokeVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: aksSpokeVnetId
    }
  }
}

// AKS spoke to App peering
resource aksSpokeToAppPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2024-07-01' = {
  name: '${aksSpokeVnetName}/peer-to-${appVnetName}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: appVnetId
    }
  }
}

@description('The resource IDs of all created peering connections')
output peeringIds array = [
  hubToPermServPeering.id
  permServToHubPeering.id
  hubToAppPeering.id
  appToHubPeering.id
  permServToAppPeering.id
  appToPermServPeering.id
  hubToAksSpokePeering.id
  aksSpokeToHubPeering.id
  permServToAksSpokePeering.id
  aksSpokeToPermServPeering.id
  appToAksSpokePeering.id
  aksSpokeToAppPeering.id
]
