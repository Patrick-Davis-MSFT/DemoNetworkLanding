targetScope = 'resourceGroup'

@description('Deployment location. Defaults to resource group location.')
param location string = resourceGroup().location

@description('Hub VNet name created by infra-no-vm deployment.')
param hubVnetName string

@description('Gateway subnet name in the hub VNet.')
param gatewaySubnetName string = 'GatewaySubnet'

@description('Virtual network gateway resource name.')
param vpnGatewayName string = 'vng-p2s'

@description('Gateway public IP resource name.')
param vpnPublicIpName string = 'pip-vng-p2s'

@description('VPN gateway SKU. VpnGw1 is the smallest SKU that supports OpenVPN + Entra ID auth.')
@allowed([
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
  'VpnGw4'
  'VpnGw5'
  'VpnGw1AZ'
  'VpnGw2AZ'
  'VpnGw3AZ'
  'VpnGw4AZ'
  'VpnGw5AZ'
])
param vpnGatewaySku string = 'VpnGw1'

@description('P2S address pool CIDR. Must not overlap with any VNet or on-prem address space.')
param vpnClientAddressPoolPrefix string = '172.20.0.0/24'

@description('Optional route prefixes to advertise to P2S clients (for example hub/spoke VNet CIDRs).')
param vpnClientCustomRoutePrefixes array = []

@description('Microsoft Entra tenant ID used for VPN authentication.')
param aadTenantId string = tenant().tenantId

@description('Azure VPN first-party app ID for Azure public cloud.')
param aadAudience string = '41b23e61-6c1e-4545-b367-cd054e0ed4b4'

@description('AadIssuer URL. For Azure public cloud use: https://sts.windows.net/<tenant-id>/')
param aadIssuer string

@description('Optional inbound DNS IP to set on the existing hub VNet (safe patch update, not VNet recreation). Leave empty to skip.')
param hubDnsServerIp string = ''

@description('Tags to apply to VPN resources.')
param tags object = {
  License: 'MIT'
}

var aadTenantUrl = '${environment().authentication.loginEndpoint}${aadTenantId}'
var gatewayCustomRoutes = empty(vpnClientCustomRoutePrefixes) ? {} : {
  customRoutes: {
    addressPrefixes: vpnClientCustomRoutePrefixes
  }
}

resource hubVnet 'Microsoft.Network/virtualNetworks@2024-07-01' existing = {
  name: hubVnetName
}

resource gatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-07-01' existing = {
  name: gatewaySubnetName
  parent: hubVnet
}

resource vpnPublicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: vpnPublicIpName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-07-01' = {
  name: vpnGatewayName
  location: location
  tags: tags
  properties: {
    activeActive: false
    enableBgp: false
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation1'
    sku: {
      name: vpnGatewaySku
      tier: vpnGatewaySku
    }
    ipConfigurations: [
      {
        name: 'gw-ipconfig-01'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnet.id
          }
          publicIPAddress: {
            id: vpnPublicIp.id
          }
        }
      }
    ]
    ...gatewayCustomRoutes
    vpnClientConfiguration: any({
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPoolPrefix
        ]
      }
      vpnAuthenticationTypes: [
        'AAD'
      ]
      vpnClientProtocols: [
        'OpenVPN'
      ]
      aadTenant: aadTenantUrl
      aadAudience: aadAudience
      aadIssuer: aadIssuer
    })
  }
}

output vpnGatewayId string = vpnGateway.id
output vpnGatewayName string = vpnGateway.name
output vpnGatewayPublicIp string = vpnPublicIp.properties.ipAddress
output aadTenant string = aadTenantUrl
output profileGenerateCommand string = 'az network vnet-gateway vpn-client generate --resource-group ${resourceGroup().name} --name ${vpnGateway.name} --processor-architecture Amd64'
output hubVnetDnsUpdateCommand string = empty(trim(hubDnsServerIp)) ? '' : 'az network vnet update --resource-group ${resourceGroup().name} --name ${hubVnetName} --dns-servers ${hubDnsServerIp}'
