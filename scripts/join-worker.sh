#!/usr/bin/env bash
set -e

# ==============================================================================
# Script de Unión de Nodo Worker (PC 2 a PC 6) - Docker-Native / Sin Sudo
# ==============================================================================
IP_MASTER="$1"
TOKEN="${2:-icesi-k8s-cluster-grupo01}"

if [ -z "$IP_MASTER" ]; then
  echo "Error: Debes especificar la dirección IP del Control Plane (PC 1)."
  echo "Uso: ./join-worker.sh <IP_MASTER> [TOKEN]"
  echo "Ejemplo: ./join-worker.sh 10.147.20.62 icesi-k8s-cluster-grupo01"
  exit 1
fi

IP_THIS_NODE=$(hostname -I | awk "{print $1}")

echo "=== [Worker Node] Uniendo estación al clúster K8s ==="
echo "-> IP Local Worker : $IP_THIS_NODE"
echo "-> IP Master (PC 1): $IP_MASTER"
echo "-> Token de Unión  : $TOKEN"

docker run -d \
  --name k8s-worker \
  --restart unless-stopped \
  --privileged \
  --net=host \
  -e K3S_URL="https://$IP_MASTER:6443" \
  -e K3S_TOKEN="$TOKEN" \
  rancher/k3s:v1.31.1-k3s1 agent \
  --node-ip "$IP_THIS_NODE" \
  --kubelet-arg="fail-swap-on=false"

echo ""
echo "=============================================================================="
echo "✅ Agente K3s Worker iniciado en contenedor Docker."
echo "Pide al estudiante de PC 1 o PC 7 verificar con: kubectl get nodes -o wide"
echo "=============================================================================="
