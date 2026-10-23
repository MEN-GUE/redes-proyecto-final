#!/usr/bin/env bash
# Crea las VMs de prueba con IP interna fija y SIN IP pública (acceso por IAP).
#   vm-ventas-1 / vm-ventas-2 : prueba de ping dentro de la subred de Ventas
#   vm-visitas-1              : prueba de aislamiento (no debe alcanzar Ventas)
source "$(dirname "$0")/00-variables.sh"

crear_vm() {
  local nombre=$1 subred=$2 ip=$3 etiqueta=$4
  paso "Creando $nombre en $subred ($ip)"
  if ! gc compute instances describe "$nombre" --zone="$ZONE" >/dev/null 2>&1; then
    gc compute instances create "$nombre" \
      --zone="$ZONE" \
      --machine-type="$MACHINE_TYPE" \
      --subnet="$subred" \
      --private-network-ip="$ip" \
      --no-address \
      --image-family="$IMAGE_FAMILY" \
      --image-project="$IMAGE_PROJECT" \
      --boot-disk-size=10GB \
      --boot-disk-type=pd-standard \
      --no-service-account --no-scopes \
      --shielded-secure-boot \
      --tags="$etiqueta" \
      --labels=proyecto=entodata,fase=1
  fi
}

crear_vm "$VM_VENTAS_1"  "$SUBNET_VENTAS"  "$IP_VENTAS_1"  ventas
crear_vm "$VM_VENTAS_2"  "$SUBNET_VENTAS"  "$IP_VENTAS_2"  ventas
crear_vm "$VM_VISITAS_1" "$SUBNET_VISITAS" "$IP_VISITAS_1" visitas

paso "Instancias de EntoData"
gc compute instances list --filter="labels.proyecto=entodata" \
  --format="table(name, zone.basename(), machineType.basename(), networkInterfaces[0].subnetwork.basename(), networkInterfaces[0].networkIP, status)"
