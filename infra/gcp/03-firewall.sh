#!/usr/bin/env bash
# Reglas de firewall de la VPC. GCP ya incluye las reglas implícitas
# "deny all ingress" y "allow all egress" (prioridad 65535), así que solo se
# abre lo necesario y se bloquea explícitamente la red de visitas.
source "$(dirname "$0")/00-variables.sh"

crear_regla() {
  local nombre=$1; shift
  paso "Regla $nombre"
  if ! gc compute firewall-rules describe "$nombre" >/dev/null 2>&1; then
    gc compute firewall-rules create "$nombre" --network="$VPC" --direction=INGRESS "$@"
  fi
}

crear_regla entodata-deny-visitas-internas \
  --action=DENY --rules=all --priority=900 \
  --source-ranges="$RANGO_VISITAS" \
  --destination-ranges="$RANGO_VENTAS,$RANGO_TI,$RANGO_DC" \
  --description="Visitas no puede alcanzar Ventas, TI ni Data Center"

crear_regla entodata-allow-icmp-ventas \
  --action=ALLOW --rules=icmp --priority=1000 \
  --source-ranges="$RANGO_VENTAS" \
  --destination-ranges="$RANGO_VENTAS" \
  --description="Ping entre equipos de Ventas"

crear_regla entodata-allow-ti-admin \
  --action=ALLOW --rules=icmp,tcp:22 --priority=1000 \
  --source-ranges="$RANGO_TI" \
  --description="TI administra toda la red (ping y SSH)"

crear_regla entodata-allow-ventas-dc-https \
  --action=ALLOW --rules=tcp:443 --priority=1000 \
  --source-ranges="$RANGO_VENTAS" \
  --destination-ranges="$RANGO_DC" \
  --description="Ventas consume la API/IA del Data Center por HTTPS"

crear_regla entodata-allow-iap-ssh \
  --action=ALLOW --rules=tcp:22 --priority=1000 \
  --source-ranges="$IAP_RANGE" \
  --description="SSH administrativo solo a traves de Google IAP"

paso "Reglas de firewall de $VPC"
gc compute firewall-rules list --filter="network~/$VPC\$" --sort-by=priority \
  --format="table(name, direction, priority, sourceRanges.list(), destinationRanges.list(), allowed[].map().firewall_rule().list(), denied[].map().firewall_rule().list())"
