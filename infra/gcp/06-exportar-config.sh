#!/usr/bin/env bash
# Exporta la configuración real desplegada en GCP a config/ (entregable del reporte).
source "$(dirname "$0")/00-variables.sh"
mkdir -p "$CONFIG_DIR"

FILTRO_VPC="network~/$VPC\$"

paso "Exportando configuración a $CONFIG_DIR"
gc compute networks describe "$VPC" --format=yaml                         > "$CONFIG_DIR/vpc.yaml"
gc compute networks subnets list --network="$VPC" --format=yaml            > "$CONFIG_DIR/subredes.yaml"
gc compute firewall-rules list --filter="$FILTRO_VPC" --format=yaml        > "$CONFIG_DIR/firewall.yaml"
gc compute routes list --filter="$FILTRO_VPC" --format=yaml                > "$CONFIG_DIR/rutas.yaml"
gc compute instances list --filter="labels.proyecto=entodata" --format=yaml > "$CONFIG_DIR/instancias.yaml"

{
  echo "== VPC =="
  gc compute networks list --filter="name=$VPC" \
    --format="table(name, x_gcloud_subnet_mode, x_gcloud_bgp_routing_mode, autoCreateSubnetworks)"
  echo; echo "== Subredes =="
  gc compute networks subnets list --network="$VPC" \
    --format="table(name, region.basename(), ipCidrRange, gatewayAddress, privateIpGoogleAccess)"
  echo; echo "== Firewall =="
  gc compute firewall-rules list --filter="$FILTRO_VPC" --sort-by=priority \
    --format="table(name, direction, priority, sourceRanges.list(), destinationRanges.list(), allowed[].map().firewall_rule().list(), denied[].map().firewall_rule().list())"
  echo; echo "== Rutas =="
  gc compute routes list --filter="$FILTRO_VPC" \
    --format="table(name, destRange, nextHopGateway.basename(), nextHopNetwork.basename(), priority)"
  echo; echo "== Instancias =="
  gc compute instances list --filter="labels.proyecto=entodata" \
    --format="table(name, zone.basename(), machineType.basename(), networkInterfaces[0].subnetwork.basename(), networkInterfaces[0].networkIP, status)"
} | tee "$CONFIG_DIR/resumen.txt"
