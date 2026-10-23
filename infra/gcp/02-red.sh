#!/usr/bin/env bash
# Crea la VPC en modo personalizado y las 4 subredes calculadas con VLSM.
source "$(dirname "$0")/00-variables.sh"

paso "Creando VPC $VPC (modo custom: sin rangos automáticos)"
if ! gc compute networks describe "$VPC" >/dev/null 2>&1; then
  gc compute networks create "$VPC" \
    --subnet-mode=custom \
    --bgp-routing-mode=regional \
    --description="VPC de EntoData - Proyecto Final Redes Fase 1"
fi

crear_subred() {
  local nombre=$1 rango=$2 descripcion=$3; shift 3
  paso "Creando $nombre ($rango)"
  if ! gc compute networks subnets describe "$nombre" --region="$REGION" >/dev/null 2>&1; then
    gc compute networks subnets create "$nombre" \
      --network="$VPC" \
      --region="$REGION" \
      --range="$rango" \
      --description="$descripcion" \
      "$@"
  fi
}

# Orden VLSM: de la red más grande a la más pequeña.
crear_subred "$SUBNET_VISITAS" "$RANGO_VISITAS" "Red de visitas - 50 hosts - aislada de la red interna"
crear_subred "$SUBNET_VENTAS"  "$RANGO_VENTAS"  "Equipo de Campo (Ventas) - 25 personas"
crear_subred "$SUBNET_TI"      "$RANGO_TI"      "Tecnologia e Innovacion (TI) - 15 personas"
crear_subred "$SUBNET_DC"      "$RANGO_DC"      "Data Center - 5 servidores (IA, BD, API)" \
  --enable-private-ip-google-access

paso "Subredes de $VPC"
gc compute networks subnets list --network="$VPC" \
  --format="table(name, region.basename(), ipCidrRange, gatewayAddress, privateIpGoogleAccess)"
