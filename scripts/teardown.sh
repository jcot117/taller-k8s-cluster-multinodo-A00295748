#!/usr/bin/env bash
# ==============================================================================
# Script de Limpieza y Desmantelamiento (Cualquier PC)
# ==============================================================================
echo "=== Desmantelando contenedores de K8s y restaurando la máquina ==="

docker rm -f k8s-master 2>/dev/null || true
docker rm -f k8s-worker 2>/dev/null || true
rm -rf "$HOME/k8s-cluster"

echo "✅ Estación de trabajo restaurada y completamente limpia."
