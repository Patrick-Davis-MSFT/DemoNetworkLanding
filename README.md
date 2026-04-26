# Demo Network Landing Zone

A comprehensive Azure networking landing zone implemented using Bicep Infrastructure as Code (IaC) that deploys a hub-and-spoke network topology with private DNS resolution for Azure PaaS services.

## Architecture Overview

This repository deploys an enterprise-ready network foundation and then layers management compute on top:

- Hub-and-Spoke Network Topology: Multiple VNets with peering
- Network Security Groups: Traffic control and segmentation
- Private DNS Zones: DNS resolution for Azure PaaS services
- Azure Key Vault: Credential storage and secret management
- Azure Bastion Host: Secure VM access without exposing RDP/SSH publicly
- Windows Virtual Machine: Optional management/test VM

## Deployment Model

This repository now uses a two-step deployment model:

1. Core network and shared services
- Deploy from ./infra-no-vm/main.bicep
- Creates VNets, peerings, NSG rules, private DNS links, and Key Vault

2. Bastion and VM add-on
- Deploy from ./add-vm/main.bicep
- Adds Bastion and a Windows VM to the existing hub VNet
- Stores VM credentials as Key Vault secrets

## Prerequisites

Before deploying, ensure you have:

1. Azure CLI installed and authenticated
2. An Azure subscription with appropriate permissions
3. Contributor or Owner permissions for deployment scope

## Deployment Steps

### 1. Authenticate and select subscription

```bash
az login
az account set --subscription "your-subscription-id"
az account show
```

### 2. Deploy core network and Key Vault

```bash
az deployment sub validate \
  --location eastus2 \
  --template-file infra-no-vm/main.bicep \
  --parameters infra-no-vm/suggested.parameters.json

az deployment sub what-if \
  --location eastus2 \
  --template-file infra-no-vm/main.bicep \
  --parameters infra-no-vm/suggested.parameters.json

az deployment sub create \
  --location eastus2 \
  --template-file infra-no-vm/main.bicep \
  --parameters infra-no-vm/suggested.parameters.json \
  --name "demo-network-core-$(date +%Y%m%d-%H%M%S)"
```

### 3. Deploy Bastion and VM add-on

Note: vmAdminPassword is secure and should be passed at deploy time.

```bash
az deployment sub validate \
  --location eastus2 \
  --template-file add-vm/main.bicep \
  --parameters add-vm/suggested.parameters.json \
  --parameters vmAdminPassword='<strong-password>'

az deployment sub create \
  --location eastus2 \
  --template-file add-vm/main.bicep \
  --parameters add-vm/suggested.parameters.json \
  --parameters vmAdminPassword='<strong-password>' \
  --name "demo-network-add-vm-$(date +%Y%m%d-%H%M%S)"
```

### 4. Optional: Add Point-to-Site VPN

After core deployment (and optionally after add-vm), you can deploy the P2S VPN add-on:

```bash
chmod +x ./add-vpn/deploy-p2s-vpn.sh
./add-vpn/deploy-p2s-vpn.sh <resource-group-name> [location]
```

For client setup details, see add-vpn/README.md.

## Template Structure

```text
infra-no-vm/
├── main.bicep
├── suggested.parameters.json
└── modules/

add-vm/
├── main.bicep
├── suggested.parameters.json
└── modules/
    └── bastion.bicep

add-vpn/
├── deploy-p2s-vpn.sh
├── main.bicep
├── suggested.parameters.json
└── modules/
```

## Post-Deployment Verification

### Verify core network resources

```bash
az network vnet list \
  --resource-group <resource-group-name> \
  --output table

az network private-dns zone list \
  --resource-group <resource-group-name> \
  --output table
```

### Verify Key Vault

```bash
az keyvault list \
  --resource-group <resource-group-name> \
  --output table
```

### Verify Bastion and VM

```bash
az network bastion list \
  --resource-group <resource-group-name> \
  --output table

az vm list \
  --resource-group <resource-group-name> \
  --output table \
  --show-details

az keyvault secret list \
  --vault-name <key-vault-name> \
  --output table
```

## Cleanup

To remove all deployed resources:

```bash
az group delete \
  --name <resource-group-name> \
  --yes \
  --no-wait
```

## Troubleshooting

Common issues:

1. Insufficient permissions
2. Address space overlap with existing networks
3. Azure quota limits in your selected region
4. Naming conflicts with existing resources

Useful commands:

```bash
az vm list-usage --location eastus2 --output table

az deployment sub list \
  --query "[].{Name:name, State:properties.provisioningState, Timestamp:properties.timestamp}" \
  --output table
```

## License

This project is licensed under the MIT License. See LICENSE for details.
