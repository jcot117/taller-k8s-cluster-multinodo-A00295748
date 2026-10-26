#!/usr/bin/env bash
# ==============================================================================
# Script de Generación de Carga HTTP (PC 7 Bastion / SRE)
# ==============================================================================
IP_INGRESS="$1"
DURATION="${2:-45s}"
QPS="${3:-30}"

if [ -z "$IP_INGRESS" ]; then
  echo "Uso: ./test-traffic.sh <IP_PC6_INGRESS> [DURACION] [QPS]"
  echo "Ejemplo: ./test-traffic.sh 10.147.20.69 60s 25"
  exit 1
fi

echo "=== [PC 7: SRE / Chaos] Generando ráfaga de tráfico HTTP contra Ingress ==="
echo "-> Destino : http://$IP_INGRESS/api"
echo "-> Host L7 : ingesoft5.lab.icesi"
echo "-> Duración: $DURATION"
echo "-> QPS     : $QPS req/s"
echo ""

docker run --rm -it williamyeh/hey \
  -z "$DURATION" \
  -q "$QPS" \
  -c 10 \
  -H "Host: ingesoft5.lab.icesi" \
  "http://$IP_INGRESS/api"
