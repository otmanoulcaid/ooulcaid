# Part 3 — K3d and Argo CD

Continuous deployment lab: a **K3d** cluster running **Argo CD**, which
automatically deploys an application from a **public GitHub repository**.

## K3s vs K3d — the difference

| | K3s | K3d |
|---|---|---|
| What it is | A lightweight, fully-conformant Kubernetes distribution (single ~60 MB binary) | A wrapper that runs **K3s inside Docker containers** |
| Where nodes live | Real machines / VMs (p1 and p2 used Vagrant VMs) | Docker containers on one host |
| Node = | A host with the k3s systemd service | A `rancher/k3s` container |
| Multi-node | One VM per node | One container per node, on a Docker network |
| Use case | Edge, IoT, small production clusters | Local development, CI, throw-away clusters |

In short: **K3d is not another Kubernetes** — it is K3s packaged for Docker.
That is why p3 needs no Vagrant: Docker replaces the VMs.

k3d also runs a `serverlb` container (an nginx load balancer) in front of the
nodes, which is what lets us publish a NodePort on the host.

## Layout

```
p3/
├── confs/
│   ├── namespaces.yaml          # argocd + dev namespaces
│   ├── argocd-application.yaml  # Argo CD Application -> watches GitHub
│   └── app/                     # <- the manifests Argo CD syncs (GitOps source)
│       ├── deployment.yaml      #    wil42/playground, tag v1 or v2
│       └── service.yaml         #    NodePort 30888
└── scripts/
    ├── install.sh               # docker + kubectl + k3d (Debian/Ubuntu)
    ├── uninstall.sh             # removes what install.sh installed
    ├── create_cluster.sh        # cluster + namespaces + Argo CD + Application
    ├── argocd_ui.sh             # password + opens the Argo CD web interface
    ├── switch_version.sh        # demo: bump v1 <-> v2 through Git
    └── destroy.sh               # delete the cluster
```

## Usage

```bash
cd p3/scripts
./install.sh          # once per machine (log out/in afterwards for the docker group)
./create_cluster.sh   # builds everything, ~3-5 min on a cold image cache
```

Then:

```bash
curl http://localhost:8888/
# {"status":"ok", "message": "v1"}
```

Argo CD UI:

```bash
./argocd_ui.sh        # prints admin/<password>, forwards https://localhost:8080
```

## The GitOps loop (what to show at the defense)

The cluster is **never** modified by hand. Git is the single source of truth:

```bash
# 1. current state
curl http://localhost:8888/                     # -> "v1"
kubectl get pods -n dev

# 2. change the version IN GIT (edit p3/confs/app/deployment.yaml, push)
./switch_version.sh v2

# 3. Argo CD detects the new commit and rolls it out by itself
kubectl get application playground -n argocd -w  # Synced / Healthy
kubectl rollout status deployment/ooulcaid-playground -n dev

# 4. new state
curl http://localhost:8888/                     # -> "v2"
```

Argo CD polls the repository every **3 minutes** by default. To avoid waiting
during the demo, force a refresh:

```bash
kubectl patch application playground -n argocd --type merge \
  -p '{"metadata":{"annotations":{"argocd.argoproj.io/refresh":"hard"}}}'
```

`selfHeal: true` is enabled, so deleting the pod or editing the deployment by
hand is reverted back to what Git says — that is the point of GitOps.

## Networking

```
host :8888  ->  k3d serverlb  ->  NodePort 30888  ->  Service :8888  ->  Pod :8888
```

The mapping is created at cluster creation time
(`--port "8888:30888@loadbalancer"`), so `localhost:8888` keeps working without
any `kubectl port-forward` running in the background.

Traefik is disabled (`--disable=traefik`): p3 needs no Ingress, and dropping it
saves memory in the VM.
