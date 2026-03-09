#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INFRA_PARAMS_DEFAULT="$ROOT_DIR/infra-no-vm/suggested.parameters.json"

RESOURCE_GROUP_NAME="${1:-}"
LOCATION_OVERRIDE="${2:-}"
INFRA_PARAMS_FILE="${3:-$INFRA_PARAMS_DEFAULT}"
HUB_DNS_SERVER_IP="${4:-}"

if [[ -z "$RESOURCE_GROUP_NAME" ]]; then
  echo "Usage: $0 <resource-group-name> [location] [infra-no-vm-parameters-file] [hub-dns-server-ip]"
  echo "Example: $0 rg-demo-network-landing eastus2"
  exit 1
fi

if [[ ! -f "$INFRA_PARAMS_FILE" ]]; then
  echo "Parameters file not found: $INFRA_PARAMS_FILE"
  exit 1
fi

if ! command -v az >/dev/null 2>&1; then
  echo "Azure CLI (az) is required."
  exit 1
fi

az account show >/dev/null

extract_param_value() {
  local key="$1"
  python3 - <<PY "$INFRA_PARAMS_FILE" "$key"
import json
import sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data['parameters'][sys.argv[2]]['value'])
PY
}

HUB_BASE_NAME="$(extract_param_value hubVnetName)"
PERM_BASE_NAME="$(extract_param_value permServVnetName)"
APP_BASE_NAME="$(extract_param_value appVnetName)"

LOCATION="$LOCATION_OVERRIDE"
if [[ -z "$LOCATION" ]]; then
  LOCATION="$(az group show --name "$RESOURCE_GROUP_NAME" --query location -o tsv)"
fi

discover_vnet_name() {
  local base_name="$1"
  local discovered
  discovered="$(az network vnet list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[?starts_with(name, '${base_name}-')].name | [0]" \
    -o tsv)"

  if [[ -n "$discovered" ]]; then
    echo "$discovered"
    return 0
  fi

  discovered="$(az network vnet list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --query "[?name=='${base_name}'].name | [0]" \
    -o tsv)"

  if [[ -n "$discovered" ]]; then
    echo "$discovered"
    return 0
  fi

  echo ""
}

HUB_VNET_NAME="$(discover_vnet_name "$HUB_BASE_NAME")"
PERM_VNET_NAME="$(discover_vnet_name "$PERM_BASE_NAME")"
APP_VNET_NAME="$(discover_vnet_name "$APP_BASE_NAME")"

if [[ -z "$HUB_VNET_NAME" ]]; then
  echo "Unable to find hub VNet in resource group '$RESOURCE_GROUP_NAME' for base name '$HUB_BASE_NAME'."
  exit 1
fi

if [[ -z "$PERM_VNET_NAME" || -z "$APP_VNET_NAME" ]]; then
  echo "Unable to discover all spoke VNets in resource group '$RESOURCE_GROUP_NAME'."
  echo "Detected: hub=$HUB_VNET_NAME permServ=$PERM_VNET_NAME app=$APP_VNET_NAME"
  exit 1
fi

TENANT_ID="$(az account show --query tenantId -o tsv)"
AAD_ISSUER="https://sts.windows.net/${TENANT_ID}/"

get_vnet_address_prefixes_json() {
  local vnet_name="$1"
  az network vnet show \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$vnet_name" \
    --query "addressSpace.addressPrefixes" \
    -o json
}

HUB_PREFIXES_JSON="$(get_vnet_address_prefixes_json "$HUB_VNET_NAME")"
PERM_PREFIXES_JSON="$(get_vnet_address_prefixes_json "$PERM_VNET_NAME")"
APP_PREFIXES_JSON="$(get_vnet_address_prefixes_json "$APP_VNET_NAME")"

VPN_CUSTOM_ROUTE_PREFIXES_JSON="$(python3 - <<'PY' "$HUB_PREFIXES_JSON" "$PERM_PREFIXES_JSON" "$APP_PREFIXES_JSON"
import json
import sys

prefixes = []
seen = set()
for arg in sys.argv[1:]:
    values = json.loads(arg)
    for prefix in values:
        if prefix not in seen:
            seen.add(prefix)
            prefixes.append(prefix)

print(json.dumps(prefixes))
PY
)"

if [[ -z "$HUB_DNS_SERVER_IP" ]]; then
  HUB_DNS_SERVER_IP="$(az network vnet show --resource-group "$RESOURCE_GROUP_NAME" --name "$HUB_VNET_NAME" --query "dhcpOptions.dnsServers[0]" -o tsv)"
  if [[ -n "$HUB_DNS_SERVER_IP" ]]; then
    echo "Using existing hub VNet DNS server IP: $HUB_DNS_SERVER_IP"
  else
    echo "Warning: No hub DNS server IP supplied or found on the hub VNet. Private endpoint DNS resolution may fail for VPN clients."
  fi
fi

find_peering_name() {
  local source_vnet="$1"
  local remote_vnet_id="$2"
  az network vnet peering list \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --vnet-name "$source_vnet" \
    --query "[?remoteVirtualNetwork.id=='${remote_vnet_id}'].name | [0]" \
    -o tsv
}

update_hub_to_spoke_peering() {
  local spoke_vnet_name="$1"
  local spoke_vnet_id="$2"
  local peering_name
  peering_name="$(find_peering_name "$HUB_VNET_NAME" "$spoke_vnet_id")"

  if [[ -z "$peering_name" ]]; then
    echo "Warning: No peering found from hub '$HUB_VNET_NAME' to spoke '$spoke_vnet_name'. Skipping hub peering update."
    return 0
  fi

  az network vnet peering update \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --vnet-name "$HUB_VNET_NAME" \
    --name "$peering_name" \
    --set allowGatewayTransit=true useRemoteGateways=false allowVirtualNetworkAccess=true allowForwardedTraffic=true \
    >/dev/null

  echo "Updated hub peering '$peering_name' (allowGatewayTransit=true)."
}

update_spoke_to_hub_peering() {
  local spoke_vnet_name="$1"
  local hub_vnet_id="$2"
  local peering_name
  peering_name="$(find_peering_name "$spoke_vnet_name" "$hub_vnet_id")"

  if [[ -z "$peering_name" ]]; then
    echo "Warning: No peering found from spoke '$spoke_vnet_name' to hub '$HUB_VNET_NAME'. Skipping spoke peering update."
    return 0
  fi

  az network vnet peering update \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --vnet-name "$spoke_vnet_name" \
    --name "$peering_name" \
    --set useRemoteGateways=true allowGatewayTransit=false allowVirtualNetworkAccess=true allowForwardedTraffic=true \
    >/dev/null

  echo "Updated spoke peering '$peering_name' (useRemoteGateways=true)."
}

echo "Deploying P2S VPN add-on"
echo "  resource group: $RESOURCE_GROUP_NAME"
echo "  location:       $LOCATION"
echo "  hub vnet:       $HUB_VNET_NAME"
echo "  perm vnet:      $PERM_VNET_NAME"
echo "  app vnet:       $APP_VNET_NAME"
echo "  custom routes:  $VPN_CUSTOM_ROUTE_PREFIXES_JSON"
if [[ -n "$HUB_DNS_SERVER_IP" ]]; then
  echo "  hub dns server: $HUB_DNS_SERVER_IP"
fi

DEPLOYMENT_JSON="$(az deployment group create \
  --resource-group "$RESOURCE_GROUP_NAME" \
  --name "add-p2s-vpn-$(date +%Y%m%d-%H%M%S)" \
  --template-file "$SCRIPT_DIR/main.bicep" \
  --parameters \
    location="$LOCATION" \
    hubVnetName="$HUB_VNET_NAME" \
    hubDnsServerIp="$HUB_DNS_SERVER_IP" \
    vpnClientCustomRoutePrefixes="$VPN_CUSTOM_ROUTE_PREFIXES_JSON" \
    aadTenantId="$TENANT_ID" \
    aadIssuer="$AAD_ISSUER" \
  -o json)"

VPN_GATEWAY_NAME="$(python3 - <<'PY' "$DEPLOYMENT_JSON"
import json
import sys
obj = json.loads(sys.argv[1])
print(obj['properties']['outputs']['vpnGatewayName']['value'])
PY
)"

echo "Updating existing VNet peerings for gateway transit..."

HUB_VNET_ID="$(az network vnet show --resource-group "$RESOURCE_GROUP_NAME" --name "$HUB_VNET_NAME" --query id -o tsv)"
PERM_VNET_ID="$(az network vnet show --resource-group "$RESOURCE_GROUP_NAME" --name "$PERM_VNET_NAME" --query id -o tsv)"
APP_VNET_ID="$(az network vnet show --resource-group "$RESOURCE_GROUP_NAME" --name "$APP_VNET_NAME" --query id -o tsv)"

update_hub_to_spoke_peering "$PERM_VNET_NAME" "$PERM_VNET_ID"
update_spoke_to_hub_peering "$PERM_VNET_NAME" "$HUB_VNET_ID"

update_hub_to_spoke_peering "$APP_VNET_NAME" "$APP_VNET_ID"
update_spoke_to_hub_peering "$APP_VNET_NAME" "$HUB_VNET_ID"

if [[ -n "$HUB_DNS_SERVER_IP" ]]; then
  echo "Updating hub VNet DNS servers (non-destructive patch update)..."
  az network vnet update \
    --resource-group "$RESOURCE_GROUP_NAME" \
    --name "$HUB_VNET_NAME" \
    --dns-servers "$HUB_DNS_SERVER_IP" \
    >/dev/null
  echo "Updated hub VNet DNS servers to '$HUB_DNS_SERVER_IP'."
fi

echo ""
echo "P2S VPN deployment complete."
echo ""
echo "Generate VPN client profile package (URL valid for a short time):"
echo "az network vnet-gateway vpn-client generate --resource-group $RESOURCE_GROUP_NAME --name $VPN_GATEWAY_NAME --processor-architecture Amd64"
echo ""
echo "See $SCRIPT_DIR/README.md for full client setup instructions."
