#!/usr/bin/env bash
# Elimina TODO lo creado por estos scripts (VMs, firewall, subredes, VPC). Irreversible.
source "$(dirname "$0")/00-variables.sh"

if [[ "${1:-}" != "--si" ]]; then
  read -r -p "Esto elimina la red de EntoData en $PROJECT_ID. Escriba 'eliminar' para continuar: " r
  [[ "$r" == "eliminar" ]] || { echo "Cancelado."; exit 1; }
fi

paso "Eliminando VMs"
gc compute instances delete "$VM_VENTAS_1" "$VM_VENTAS_2" "$VM_VISITAS_1" --zone="$ZONE" || true

paso "Eliminando reglas de firewall"
for regla in $(gc compute firewall-rules list --filter="network~/$VPC\$" --format="value(name)"); do
  gc compute firewall-rules delete "$regla"
done

paso "Eliminando subredes"
gc compute networks subnets delete "$SUBNET_VISITAS" "$SUBNET_VENTAS" "$SUBNET_TI" "$SUBNET_DC" \
  --region="$REGION" || true

paso "Eliminando VPC"
gc compute networks delete "$VPC" || true
