#!/usr/bin/env bash
# Habilita las APIs necesarias: Compute Engine (VPC, subredes, VMs) e IAP (SSH sin IP pública).
source "$(dirname "$0")/00-variables.sh"

paso "Habilitando APIs en $PROJECT_ID"
gc services enable compute.googleapis.com iap.googleapis.com

gc services list --enabled --filter="config.name:(compute.googleapis.com iap.googleapis.com)" \
  --format="table(config.name, config.title)"
