#!/usr/bin/env bash
# Variables compartidas por todos los scripts de EntoData - Proyecto Final Redes, Fase 1.
# Se carga con: source "$(dirname "$0")/00-variables.sh"
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# --- Proyecto y ubicación (desde .env, que no se versiona) ----------------
if [[ -f "$ROOT_DIR/.env" ]]; then
  set -a; source "$ROOT_DIR/.env"; set +a
fi
: "${PROJECT_ID:?Falta PROJECT_ID: copie .env.example a .env y complételo}"
REGION="${REGION:-us-central1}"   # región elegible para la capa gratuita de e2-micro
ZONE="${ZONE:-us-central1-a}"

# --- Red (bloque base 10.10.0.0/24, VLSM ajustado a GCP) -------------------
VPC="entodata-vpc"

SUBNET_VISITAS="subnet-visitas";       RANGO_VISITAS="10.10.0.0/26"    # 50 visitantes
SUBNET_VENTAS="subnet-ventas";         RANGO_VENTAS="10.10.0.64/27"    # 25 personas
SUBNET_TI="subnet-ti";                 RANGO_TI="10.10.0.96/27"        # 15 personas
SUBNET_DC="subnet-datacenter";         RANGO_DC="10.10.0.128/28"       # 5 servidores

IAP_RANGE="35.235.240.0/20"   # rango de Google Identity-Aware Proxy (SSH sin IP pública)

# --- Instancias de prueba -------------------------------------------------
MACHINE_TYPE="e2-micro"
IMAGE_FAMILY="debian-12"
IMAGE_PROJECT="debian-cloud"

VM_VENTAS_1="vm-ventas-1";     IP_VENTAS_1="10.10.0.66"
VM_VENTAS_2="vm-ventas-2";     IP_VENTAS_2="10.10.0.67"
VM_VISITAS_1="vm-visitas-1";   IP_VISITAS_1="10.10.0.2"

# --- Rutas locales --------------------------------------------------------
EVIDENCIAS_DIR="$ROOT_DIR/evidencias"
CONFIG_DIR="$ROOT_DIR/config"

# --- Utilidades -----------------------------------------------------------
# gcloud siempre contra el proyecto de EntoData y sin prompts interactivos.
gc() { gcloud --project="$PROJECT_ID" --quiet "$@"; }

paso() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }
