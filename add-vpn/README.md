# Optional Point-to-Site VPN Add-on (Entra ID + Azure VPN Client)

This folder adds a **minimal** Point-to-Site (P2S) VPN layer to the `infra-no-vm` deployment.

## What this deploys

- Azure VPN Gateway in the **existing hub VNet** (`GatewaySubnet`)
- Public IP for the gateway
- P2S OpenVPN profile with **Microsoft Entra ID** auth
- Advertised P2S custom routes for hub/spoke VNet CIDRs so clients route private traffic through the tunnel
- Updates **existing** hub/spoke peerings so spokes use the hub gateway (`useRemoteGateways: true`)

## Prerequisites

- `infra-no-vm/main.bicep` is already deployed
- Azure CLI installed and logged in (`az login`)
- Permission to deploy network resources in the target resource group

## Deploy (optional step after infra-no-vm)

From repo root:

```bash
chmod +x ./add-vpn/deploy-p2s-vpn.sh
./add-vpn/deploy-p2s-vpn.sh <resource-group-name> [location] [infra-no-vm-parameters-file] [hub-dns-server-ip]
```

Example:

```bash
./add-vpn/deploy-p2s-vpn.sh rg-demo-network-landing eastus2
```

To also set hub VNet custom DNS (for example, Private DNS Resolver inbound endpoint IP):

```bash
./add-vpn/deploy-p2s-vpn.sh rg-demo-network-landing eastus2 ./infra-no-vm/suggested.parameters.json <inbound-ip>
```

The script auto-discovers the actual VNet names (including the suffix token) based on `infra-no-vm/suggested.parameters.json`.
The script also auto-discovers hub/spoke VNet CIDRs and passes them as advertised P2S custom routes.
If `hub-dns-server-ip` is provided, the script performs a non-destructive patch update equivalent to:

```bash
az network vnet update -g <rg> -n <hub-vnet> --dns-servers <inbound-ip>
```

If `hub-dns-server-ip` is omitted, the script attempts to re-use the existing hub VNet DNS server setting.

## Manual deployment alternative

```bash
az deployment group create \
  --resource-group <resource-group-name> \
  --template-file ./add-vpn/main.bicep \
  --parameters ./add-vpn/suggested.parameters.json
```

---

## Client setup (Azure VPN Client + Entra ID)

### 1) Generate VPN client profile package

Run:

```bash
az network vnet-gateway vpn-client generate \
  --resource-group <resource-group-name> \
  --name <vpn-gateway-name> \
  --processor-architecture Amd64
```

This returns a URL to a ZIP package. Download and extract it.

### 2) Install Azure VPN Client

- Windows: install **Azure VPN Client** from Microsoft Store.
- macOS: install the Azure VPN Client version supported for your OS.

### 3) Import profile

- Open Azure VPN Client
- Select **+** (Import)
- Import `azurevpnconfig.xml` from the extracted package (OpenVPN folder)
- Save profile

### 4) Connect with Entra ID

- Select the imported profile and click **Connect**
- Sign in with your Microsoft Entra account
- Complete MFA / Conditional Access if prompted

### 5) Validate connectivity

- Confirm a client IP from the P2S pool (default `172.20.0.0/24`)
- Test DNS and private endpoints from your hub/spoke resources

If private endpoint name resolution fails, verify the hub DNS server can resolve your `privatelink.*` zones.

## Notes

- Default SKU is `VpnGw1` for simplicity and Entra ID + OpenVPN support.
- By default, this P2S setup does not apply source IP/geography allowlists, so authenticated users can connect from any public IP.
- If you need country/IP restrictions, enforce them with Microsoft Entra Conditional Access named locations and policies.
- Ensure P2S client address pool does **not** overlap hub/spoke/on-prem ranges.
- Gateway provisioning can take 30–45 minutes.
