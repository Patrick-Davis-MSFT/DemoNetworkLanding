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

@description('The resource IDs of all created AKS spoke peering connections')
output peeringIds array = [
  hubToAksSpokePeering.id
  aksSpokeToHubPeering.id
  permServToAksSpokePeering.id
  aksSpokeToPermServPeering.id
  appToAksSpokePeering.id
  aksSpokeToAppPeering.id
]
