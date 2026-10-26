# ☸️ Taller Formativo Guiado: Clúster Kubernetes Multi-Nodo en Red Local

**Curso:** Ingeniería de Software V (`09776 - TIC`) — Período 2026-2  
**Institución:** Universidad Icesi — Facultad de Ingeniería, Diseño y Ciencias Aplicadas  
**Departamento:** Computación y Sistemas Inteligentes (DCSI)  
**Modalidad:** Equipos de 7 estudiantes (1 computador dedicado por estudiante)  
**Enfoque de Seguridad:** Docker-Native / Sin permisos de `sudo` (Usuario estándar `docker`)

---

## 🎯 Propósito del Taller
Desplegar, configurar y operar un **Clúster Kubernetes Multi-Nodo real distribuido en 7 computadores físicos** del laboratorio (conectados en la subred LAN o VPN ZeroTier). La práctica implementa una arquitectura desacoplada de 3 capas con alta disponibilidad, reglas de anti-afinidad de Pods, enrutamiento L7 perimetral con Ingress Controller, y auditoría de resiliencia mediante Chaos Engineering.

---

## 🔒 Arquitectura Docker-Native (Operación Segura Sin Sudo)
Para proteger la integridad de las estaciones de trabajo de la universidad y evitar alterar archivos del sistema operativo (`/etc/fstab`, parámetros de red del kernel o dependencias root):
* Los estudiantes operan **exclusivamente con el usuario `docker`**.
* Kubernetes se ejecuta mediante la imagen oficial certificada CNCF **`rancher/k3s:v1.31.1-k3s1`** en contenedores Docker con los flags `--privileged --net=host`.
* **Desacople de Swap:** Gracias a la bandera `--kubelet-arg="fail-swap-on=false"`, **NO se requiere desactivar swap en el host (`swapoff -a`)**.
* **Red Transparente:** Con `--net=host`, los puertos de K8s (`6443`, `10250`, Flannel `8472 UDP`, Ingress `80/443`) quedan expuestos directamente en la interfaz de red física de cada máquina.
* **Restauración Rápida:** Al finalizar la clase, un simple script de limpieza deja el computador 100% limpio en 5 segundos.

---

## 🖥️ Topología del Clúster y Asignación de Roles (7 Computadores)

| Máquina | Hostname Oficial | Rol K8s | Cargas y Responsabilidad Asignada |
| :---: | :--- | :--- | :--- |
| **PC 1** | `k8s-control-plane` | **Control Plane (Master)** | `kube-apiserver`, `etcd`, `scheduler`, token de unión y RBAC. |
| **PC 2** | `k8s-worker-backend-1` | **Worker Node 1** | Réplicas A del Backend API (`tier=backend`, `zone=primary`). |
| **PC 3** | `k8s-worker-backend-2` | **Worker Node 2** | Réplicas B del Backend API (`tier=backend`, `zone=secondary`). |
| **PC 4** | `k8s-worker-frontend` | **Worker Node 3** | Single Page Application / Nginx Web (`tier=frontend`). |
| **PC 5** | `k8s-worker-data` | **Worker Node 4** | Base de datos PostgreSQL y Secrets (`tier=database`). |
| **PC 6** | `k8s-worker-ingress` | **Worker Node 5 (Edge)** | Ingress Controller, balanceo L7 y terminación HTTP (`role=ingress-gateway`). |
| **PC 7** | `k8s-bastion-ops` | **Nodo Bastion / SRE** | Generador de tráfico HTTP (`hey`), inyector de fallos y auditoría. |

---

## 📂 Estructura del Repositorio

```text
taller-k8s-cluster-multinodo/
├── README.md                           # Esta guía técnica paso a paso
├── guia/
│   ├── Taller_Formativo_Kubernetes_Cluster_MultiNodo.pdf  # Taller oficial Icesi
│   └── Requerimientos_Cluster_Kubernetes_7_Nodos.pdf     # Especificaciones técnicas
├── scripts/
│   ├── bootstrap-master.sh             # Inicializa Control Plane en PC 1
│   ├── join-worker.sh                  # Une workers (PC 2 a PC 6) al master
│   ├── teardown.sh                     # Limpia contenedores y datos en cualquier PC
│   └── test-traffic.sh                 # Generador de tráfico hey para PC 7
└── manifests/
    ├── 00-namespace.yaml               # Namespace produccion
    ├── 01-config-secrets.yaml          # ConfigMap y Secrets de base de datos
    ├── 02-database.yaml                # PostgreSQL Deployment (nodeSelector: tier=database) + Service
    ├── 03-backend.yaml                 # Backend API (4 réplicas con podAntiAffinity) + Service
    ├── 04-frontend.yaml                # Frontend Web (nodeSelector: tier=frontend) + Service
    └── 05-ingress.yaml                 # Reglas de enrutamiento Ingress L7 por Host/Path
```

---

## 🚀 Guía de Ejecución Paso a Paso

### Paso 1: Clonar el Repositorio en las 7 Estaciones
En cada computador del equipo (PC 1 a PC 7), clonar el repositorio:
```bash
git clone https://github.com/ingesoft5/taller-k8s-cluster-multinodo.git ~/taller-k8s
cd ~/taller-k8s
```

---

### Paso 2: Inicializar el Control Plane (Solo en PC 1)
El Estudiante 1 ejecuta el script de inicialización del master:
```bash
./scripts/bootstrap-master.sh "icesi-k8s-grupoXX"
```
Al finalizar, copiar la **IP del Master** (ej. `10.147.20.62`) y el **token** para compartirlo con los compañeros.  
Para habilitar `kubectl` en la sesión actual:
```bash
export KUBECONFIG=~/k8s-cluster/k8s-data/kubeconfig.yaml
kubectl get nodes -o wide
```

---

### Paso 3: Unir los Worker Nodes (En PC 2, PC 3, PC 4, PC 5 y PC 6)
Cada estudiante en su respectivo computador se une al Control Plane:
```bash
./scripts/join-worker.sh <IP_DEL_PC1> "icesi-k8s-grupoXX"
```
*Ejemplo:* `./scripts/join-worker.sh 10.147.20.62 icesi-k8s-grupoXX`

---

### Paso 4: Validar y Etiquetar Nodos (Desde PC 1 o PC 7)
Desde el master, verificar que los 6 nodos estén en estado `Ready`:
```bash
kubectl get nodes -o wide
```
Aplicar las etiquetas semánticas requeridas para la planificación de cargas (reemplaza por los hostnames reales listados en la columna `NAME`):
```bash
kubectl label node <HOSTNAME_PC2> tier=backend zone=primary
kubectl label node <HOSTNAME_PC3> tier=backend zone=secondary
kubectl label node <HOSTNAME_PC4> tier=frontend
kubectl label node <HOSTNAME_PC5> tier=database
kubectl label node <HOSTNAME_PC6> role=ingress-gateway
```

---

### Paso 5: Desplegar la Aplicación Multi-Capa (Desde PC 1 o PC 7)
Aplicar todos los manifiestos declarativos:
```bash
kubectl apply -f manifests/
```

Verificar la distribución física de los Pods:
```bash
kubectl get pods -n produccion -o wide
```
**Criterio de éxito:**
* Los 4 Pods de `backend-deployment` deben quedar repartidos equitativamente (2 en PC 2 y 2 en PC 3) gracias a la regla de `podAntiAffinity`.
* El Pod de `database-deployment` debe correr estrictamente en PC 5 (`tier=database`).
* Los Pods de `frontend-deployment` deben correr estrictamente en PC 4 (`tier=frontend`).

---

### Paso 6: Prueba de Acceso y Tráfico Ingress (Desde PC 7 Bastion)
En PC 7 (o cualquier equipo), agregar el host al archivo `/etc/hosts` o probar directamente enviando el header HTTP `Host`:
```bash
# Probar API Backend
curl -I -H "Host: ingesoft5.lab.icesi" http://<IP_PC6_INGRESS>/api

# Probar Frontend Web
curl -I -H "Host: ingesoft5.lab.icesi" http://<IP_PC6_INGRESS>/
```

Para ejecutar una ráfaga de tráfico continuo de 45 segundos con `hey`:
```bash
./scripts/test-traffic.sh <IP_PC6_INGRESS> 45s 30
```

---

### Paso 7: Experimento de Resiliencia y Chaos Testing
1. Mientras PC 7 ejecuta `./scripts/test-traffic.sh`, el estudiante a cargo de **PC 2** simula la caída del servidor ejecutando:
   ```bash
   docker stop k8s-worker
   ```
2. **Observar en PC 1 / PC 7:**
   * El tráfico HTTP en `test-traffic.sh` continúa respondiendo con éxito ($\ge 99.5\%$) porque las réplicas en PC 3 absorben las peticiones sin interrupción.
   * En `kubectl get nodes`, tras 40 segundos PC 2 pasa a estado `NotReady`.
3. **Restaurar el nodo:**
   En PC 2, volver a encender el contenedor:
   ```bash
   docker start k8s-worker
   ```
   Comprobar en PC 1 que el nodo regresa automáticamente a estado `Ready` en menos de 5 segundos.

---

### Paso 8: Desmantelamiento y Limpieza Post-Laboratorio
Al concluir la sesión práctica, **cada estudiante en su computador** ejecuta el script de limpieza para dejar la máquina en su estado original:
```bash
./scripts/teardown.sh
```

---

## 📖 Documentación Institucional
* Consulta la rúbrica formativa y el cuestionario en `guia/Taller_Formativo_Kubernetes_Cluster_MultiNodo.pdf`.
* Consulta la matriz de puertos y arquitectura en `guia/Requerimientos_Cluster_Kubernetes_7_Nodos.pdf`.

**Universidad Icesi — Facultad de Ingeniería, Diseño y Ciencias Aplicadas — 2026**
