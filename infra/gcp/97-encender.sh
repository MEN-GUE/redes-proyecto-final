#!/usr/bin/env bash
# Enciende las VMs de prueba para la demostración (la red y el firewall siempre están activos).
source "$(dirname "$0")/00-variables.sh"

paso "Encendiendo VMs de EntoData"
gc compute instances start "$VM_VENTAS_1" "$VM_VENTAS_2" "$VM_VISITAS_1" --zone="$ZONE"
gc compute instances list --filter="labels.proyecto=entodata" \
  --format="table(name, networkInterfaces[0].subnetwork.basename(), networkInterfaces[0].networkIP, status)"
echo "Espere ~1 minuto a que arranque el sistema operativo antes de conectarse por SSH."
