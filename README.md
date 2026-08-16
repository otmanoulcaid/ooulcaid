# Inception-of-Things (IoT)

42 system-administration project: a minimal introduction to Kubernetes with
**K3s**, **K3d**, **Vagrant** and **Argo CD**.

| Folder | Subject | Status |
|---|---|---|
| `p1/` | K3s and Vagrant — 1 server + 1 agent VM | todo |
| `p2/` | K3s and three simple applications (Ingress by HOST) | todo |
| `p3/` | **K3d and Argo CD — GitOps continuous deployment** | done |
| `bonus/` | Local GitLab wired into the p3 cluster | todo |

## Part 3 — quick start

```bash
cd p3/scripts
./install.sh          # docker, kubectl, k3d, argocd CLI
./create_cluster.sh   # k3d cluster + argocd/dev namespaces + Argo CD + the app
curl http://localhost:8888/
```

Argo CD watches `p3/confs/app/` **in this repository** and deploys it into the
`dev` namespace. Changing the image tag there and pushing is enough to update
the running application — see [`p3/README.md`](p3/README.md).
