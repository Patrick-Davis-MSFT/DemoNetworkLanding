# Demo Network Landing Zone

A comprehensive Azure networking landing zone implemented using Bicep Infrastructure as Code (IaC) that deploys a hub-and-spoke network topology with private DNS resolution for Azure PaaS services.

## Architecture Overview

This template deploys a complete enterprise-ready network infrastructure including:

- **Hub-and-Spoke Network Topology**: Three virtual networks with full mesh connectivity
- **Azure Bastion Host**: Secure RDP/SSH access to virtual machines without public IPs
- **Windows Virtual Machine**: Test VM deployed in the hub VNet for administration and testing
- **Azure Key Vault**: Secure storage of VM credentials with private endpoint connectivity
- **Network Security Groups**: Traffic control and segmentation
- **VNet Peering**: Bidirectional connectivity between all networks
- **Private DNS Zones**: DNS resolution for Azure PaaS services across all networks

### Network Components

#### Virtual Networks
- **Hub VNet** (`10.0.0.0/21`): Central hub with gateway capabilities including:
  - GatewaySubnet for VPN/ExpressRoute
  - Multiple subnets for infrastructure services
  - Azure Bastion subnet for secure management access
  - Windows VM in snet-02 for testing and administration

- **Permanent Services VNet** (`10.0.8.0/21`): AI and permanent services spoke including:
  - Subnets for AI/ML workloads
  - App Service delegation subnet for private integration

- **Application VNet** (`10.0.16.0/20`): Application workloads spoke including:
  - Default application subnet
  - Private endpoint subnet
  - App Service delegation subnet

#### Private DNS Zones
Automatically configured for the following Azure services:
- Azure Key Vault (`privatelink.vaultcore.azure.net`)
- Azure Storage (Blob, File, Queue, Table)
- Azure Cognitive Services
- Azure Cosmos DB (including MongoDB)
- Azure Cache for Redis
- Azure AI Services

## Prerequisites

Before deploying this template, ensure you have:

1. **Azure CLI** installed and authenticated
2. **Azure subscription** with appropriate permissions
3. **Resource group creation** permissions at subscription level
4. **Contributor or Owner** role on the target subscription

## Deployment Steps

### 1. Authentication and Subscription Setup

```bash
# Login to Azure
az login

# Set your subscription (replace with your subscription ID)
az account set --subscription "your-subscription-id"

# Verify your current subscription
az account show
```

### 2. Clone and Navigate to Repository

```bash
# Navigate to the infra directory
cd ./infra
```

### 3. Validate the Bicep Template

```bash
# Validate the main template
az deployment sub validate --location eastus2 --template-file main.bicep --parameters suggested.parameters.json
```

### 4. Preview the Deployment (What-If)

```bash
# Preview what resources will be created
az deployment sub what-if --location eastus2 --template-file main.bicep --parameters suggested.parameters.json
```

### 5. Deploy the Infrastructure

```bash
# Deploy the template
az deployment sub create --location eastus2 --template-file main.bicep --parameters suggested.parameters.json --name "demo-network-landing-$(date +%Y%m%d-%H%M%S)"
```

### 6. Monitor Deployment Progress

```bash
# Check deployment status
az deployment sub show --name "demo-network-landing-YYYYMMDD-HHMMSS" --query "properties.provisioningState"

# List all deployments
az deployment sub list --query "[].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" --output table
```

## Configuration Parameters

The `suggested.parameters.json` file contains the following key configurations:

| Parameter | Value | Description |
|-----------|-------|-------------|
| `location` | `eastus2` | Azure region for deployment |
| `resourceGroupName` | Auto-generated | Resource group name with unique suffix |
| `hubVnetAddress` | `10.0.0.0/21` | Hub VNet address space |
| `permServVnetAddress` | `10.0.8.0/21` | Permanent services VNet address space |
| `appVnetAddress` | `10.0.16.0/20` | Application VNet address space |
| `vmAdminUsername` | `openseasmeuser` | Windows VM administrator username |
| `vmAdminPassword` | `Ch@nG3M3R!gh7@w@yN0w!` | Windows VM administrator password |
| `vmSize` | `Standard_B2s` | Virtual machine size |
| `windowsOSVersion` | `2022-datacenter-g2` | Windows Server version |

## Template Structure

```
infra/
├── main.bicep                 # Main orchestration template
├── suggested.parameters.json  # Parameter values
└── modules/
    ├── nsgModule.bicep        # Network Security Groups
    ├── vnet.bicep            # Virtual Network with subnets
    ├── vnetPeerings.bicep    # VNet peering connections
    ├── privateDNS.bicep      # Private DNS zones and VNet links
    └── bastion.bicep         # Azure Bastion, Windows VM, and Key Vault
```

## Deployment Sequence

The template deploys resources in the following order:

1. **Resource Group**: Creates the container for all resources
2. **Network Security Groups**: Creates NSGs for each VNet
3. **Virtual Networks**: Creates three VNets with associated subnets
4. **VNet Peerings**: Establishes bidirectional connectivity
5. **Private DNS Zones**: Creates DNS zones and links to all VNets
6. **Azure Bastion**: Deploys Bastion host with public IP for secure VM access
7. **Key Vault**: Creates vault with private endpoint and stores VM credentials
8. **Windows Virtual Machine**: Deploys VM in hub VNet snet-02 subnet

## Post-Deployment Verification

### Connect to Windows VM via Azure Bastion

After deployment, you can securely connect to the Windows VM through Azure Bastion:

1. **Navigate to the Virtual Machine** in the Azure Portal
2. **Click "Connect"** and select **"Bastion"**
3. **Enter credentials**:
   - Username: `openseasmeuser`
   - Password: `Ch@nG3M3R!gh7@w@yN0w!`
4. **Click "Connect"** to open an RDP session in your browser

> **Note**: The VM credentials are automatically stored in Azure Key Vault as secrets for security. The Key Vault is accessible via private endpoint within the VNet.

### Verify VNet Peering Status
```bash
# Check peering status for hub VNet
az network vnet peering list --resource-group <resource-group-name> --vnet-name <hub-vnet-name> --output table
```

### Verify Private DNS Zones
```bash
# List all private DNS zones
az network private-dns zone list \
  --resource-group <resource-group-name> \
  --output table
```

### Verify Azure Bastion and VM Deployment
```bash
# Check Azure Bastion status
az network bastion list \
  --resource-group <resource-group-name> \
  --output table

# Check VM status
az vm list \
  --resource-group <resource-group-name> \
  --output table \
  --show-details

# Check Key Vault and secrets
az keyvault list \
  --resource-group <resource-group-name> \
  --output table

# List secrets in Key Vault (requires appropriate permissions)
az keyvault secret list \
  --vault-name <key-vault-name> \
  --output table
```

### Test Network Connectivity
```bash
# List VNet details
az network vnet list \
  --resource-group <resource-group-name> \
  --output table
```

## Cleanup

To remove all deployed resources:

```bash
# Delete the entire resource group
az group delete \
  --name <resource-group-name> \
  --yes \
  --no-wait
```

## Troubleshooting

### Common Issues

1. **Insufficient Permissions**: Ensure you have Contributor or Owner role
2. **Address Space Conflicts**: Verify VNet address spaces don't overlap with existing networks
3. **Resource Name Conflicts**: The template uses unique suffixes to avoid naming conflicts
4. **Quota Limits**: Check Azure quotas for VNets, NSGs, and DNS zones in your subscription

### Useful Commands

```bash
# Check Azure resource quotas
az vm list-usage --location eastus2 --output table

# View deployment operation details
az deployment sub operation list \
  --name "deployment-name" \
  --query "[].{Resource:properties.targetResource.resourceName, Status:properties.provisioningState, Type:properties.targetResource.resourceType}"
```

## Contributing

This template follows Azure best practices and can be extended with additional networking components such as:
- Azure Firewall
- Application Gateway
- Load Balancers
- VPN Gateway
- ExpressRoute Gateway
- Additional Virtual Machines
- Azure Monitor and diagnostic settings

## License

This project is licensed under the MIT License - see the LICENSE file for details.
