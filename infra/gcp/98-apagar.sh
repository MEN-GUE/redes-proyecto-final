#!/usr/bin/env bash
# Detiene las VMs para no consumir créditos (la red y el firewall no tienen costo).
source "$(dirname "$0")/00-variables.sh"

paso "Deteniendo VMs de EntoData"
gc compute instances stop "$VM_VENTAS_1" "$VM_VENTAS_2" "$VM_VISITAS_1" --zone="$ZONE"
gc compute instances list --filter="labels.proyecto=entodata" --format="table(name, status)"
