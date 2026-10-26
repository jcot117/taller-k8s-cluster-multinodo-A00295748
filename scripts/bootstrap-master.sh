#!/usr/bin/env bash
set -e

# ==============================================================================
# Script de Despliegue del Control Plane (PC 1) - Docker-Native / Sin Sudo
# ==============================================================================
TOKEN=${1:-"icesi-k8s-cluster-grupo01"}
K8S_DATA_DIR="$HOME/k8s-cluster/k8s-data"
IP_MASTER=$(hostname -I | awk "{print $1}")

echo "=== [PC 1: Control Plane] Inicializando K3s Master en Docker ==="
echo "-> IP Local Detectada : $IP_MASTER"
echo "-> Token de Unión     : $TOKEN"
echo "-> Directorio de Datos: $K8S_DATA_DIR"

mkdir -p "$K8S_DATA_DIR"

# Levantar el contenedor oficial de K3s Server
docker run -d \
  --name k8s-master \
  --restart unless-stopped \
  --privileged \
  --net=host \
  -e K3S_TOKEN="$TOKEN" \
  -e K3S_KUBECONFIG_OUTPUT=/output/kubeconfig.yaml \
  -e K3S_KUBECONFIG_MODE=666 \
  -v "$K8S_DATA_DIR:/output" \
  rancher/k3s:v1.31.1-k3s1 server \
  --bind-address "$IP_MASTER" \
  --node-ip "$IP_MASTER" \
  --kubelet-arg="fail-swap-on=false"

echo "Esperando que el API Server genere el archivo kubeconfig..."
until [ -f "$K8S_DATA_DIR/kubeconfig.yaml" ]; do
  sleep 2
done

# Reemplazar 127.0.0.1 por la IP real accesible en la red local
sed -i "s/127.0.0.1/$IP_MASTER/g" "$K8S_DATA_DIR/kubeconfig.yaml"

echo ""
echo "=============================================================================="
echo "✅ Control Plane K3s iniciado exitosamente en PC 1"
echo "=============================================================================="
echo "Para operar con kubectl ejecuta:"
echo "  export KUBECONFIG=$K8S_DATA_DIR/kubeconfig.yaml"
echo "  kubectl get nodes -o wide"
echo ""
echo "Comparte con tu equipo:"
echo "1. IP del Master: $IP_MASTER"
echo "2. Token de Unión: $TOKEN"
echo "3. Archivo Kubeconfig: $K8S_DATA_DIR/kubeconfig.yaml (para PC 7 Bastion)"
echo "=============================================================================="
