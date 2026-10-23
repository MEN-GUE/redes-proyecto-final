#!/usr/bin/env bash
# Pruebas de conectividad por SSH vía IAP. Cada salida se guarda en evidencias/.
#   - ventas-1 <-> ventas-2 : debe responder (0% de pérdida)
#   - visitas-1 -> ventas-1 : debe fallar (100% de pérdida, segmentación)
source "$(dirname "$0")/00-variables.sh"
mkdir -p "$EVIDENCIAS_DIR"

prueba() {
  local archivo=$1 vm=$2 comando=$3 log
  log=$(mktemp)
  paso "$vm \$ $comando"
  # Solo la salida de la VM va a pantalla y a la evidencia; los avisos de gcloud
  # (stderr) se muestran únicamente si la conexión falla.
  if ! {
    echo "# EntoData - Fase 1 | $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
    echo "# VM: $vm  (zona $ZONE, proyecto $PROJECT_ID)"
    echo "\$ $comando"
    gc compute ssh "$vm" --zone="$ZONE" --tunnel-through-iap --command="$comando" 2>"$log"
  } | tee "$EVIDENCIAS_DIR/$archivo"; then
    cat "$log" >&2; rm -f "$log"; exit 1
  fi
  rm -f "$log"
}

prueba 01-vm-ventas-1-interfaz.txt  "$VM_VENTAS_1"  "hostname; ip -4 addr show ens4; ip route"
prueba 02-vm-ventas-2-interfaz.txt  "$VM_VENTAS_2"  "hostname; ip -4 addr show ens4; ip route"
prueba 03-ping-ventas1-a-ventas2.txt "$VM_VENTAS_1" "ping -c 4 $IP_VENTAS_2"
prueba 04-ping-ventas2-a-ventas1.txt "$VM_VENTAS_2" "ping -c 4 $IP_VENTAS_1"
prueba 05-vm-visitas-1-interfaz.txt "$VM_VISITAS_1" "hostname; ip -4 addr show ens4; ip route"
prueba 06-ping-visitas-a-ventas.txt "$VM_VISITAS_1" "ping -c 4 -W 2 $IP_VENTAS_1 || echo 'RESULTADO: sin respuesta (bloqueado por firewall)'"
