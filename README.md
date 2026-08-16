# Inception-of-Things (IoT)

42 system-administration project: a minimal introduction to Kubernetes with
**K3s**, **K3d**, **Vagrant** and **Argo CD**.

| Folder | Subject | Needs |
|---|---|---|
| `p1/` | K3s and Vagrant — 1 server + 1 agent VM | Vagrant + VirtualBox |
| `p2/` | K3s and three applications (Ingress by HOST) | Vagrant + VirtualBox |
| `p3/` | K3d and Argo CD — GitOps continuous deployment | Docker |
| `bonus/` | Local GitLab, Argo CD deploys from it | Docker + Helm |

Each folder has its own `README.md` with the details.

## Quick start

**p1** — two VMs, `192.168.56.110` (server) and `.111` (worker):

```bash
cd p1 && vagrant up
vagrant ssh ooulcaidS -c "kubectl get nodes"
```

**p2** — one VM, three apps chosen by the HOST header:

```bash
cd p2 && vagrant up
curl -H "Host: app1.com" http://192.168.56.110
```

**p3** — no VM, everything in Docker:

```bash
cd p3/scripts
./install.sh          # docker, kubectl, k3d
./create_cluster.sh   # cluster + argocd/dev namespaces + Argo CD + the app
curl http://localhost:8888/
```

Argo CD watches `p3/confs/app/` **in this repository** and deploys it into the
`dev` namespace. Changing the image tag there and pushing is enough to update
the running application.

**bonus** — same idea, but the repository is a GitLab running in the cluster:

```bash
cd bonus/scripts
./install.sh          # adds Helm
./create_cluster.sh   # cluster + GitLab + Argo CD
```
