# Bonus — GitLab

Same lab as p3, but the application is deployed from a **GitLab running inside
the cluster** instead of GitHub.

## Layout

```
bonus/
├── confs/
│   ├── namespaces.yaml          # argocd + dev + gitlab
│   ├── gitlab-values.yaml       # trimmed Helm values for GitLab
│   ├── gitlab-service.yaml      # NodePort 30929 -> GitLab
│   ├── argocd-application.yaml  # Argo CD -> local GitLab
│   └── app/                     # the files to push INTO GitLab
│       ├── deployment.yaml
│       └── service.yaml
└── scripts/
    ├── install.sh               # docker + kubectl + k3d + helm
    ├── create_cluster.sh        # cluster + namespaces + GitLab + Argo CD
    └── deploy_app.sh            # Application + opens Argo CD
```

## Ports

| Address | What |
|---|---|
| http://localhost:8888 | the application |
| http://localhost:8929 | GitLab |
| https://localhost:8080 | Argo CD |

## Usage

```bash
cd bonus/scripts
./install.sh          # once per machine (log out/in afterwards)
./create_cluster.sh   # long: GitLab takes 10-20 min to start
```

Then, in the GitLab web interface (the script prints the root password):

1. log in as `root`
2. create a **public** project named `playground`
3. push the application files into it:

```bash
cd bonus/confs/app
git init
git remote add origin http://localhost:8929/root/playground.git
git add . && git commit -m "first version"
git push -u origin master
```

4. finish the setup:

```bash
./deploy_app.sh
curl http://localhost:8888/      # {"status":"ok", "message": "v1"}
```

## The GitOps loop with GitLab

Exactly like p3, but the push goes to GitLab:

```bash
# in your clone of the GitLab project
sed -i 's/playground:v1/playground:v2/' deployment.yaml
git commit -am "v2" && git push

kubectl annotate application playground -n argocd argocd.argoproj.io/refresh=hard --overwrite
curl http://localhost:8888/      # {"status":"ok", "message": "v2"}
```

## Why the repoURL looks like that

Argo CD runs **inside** the cluster, so it cannot use `localhost:8929`. It talks
to GitLab through the Kubernetes service name:

```
http://gitlab-webservice-default.gitlab.svc.cluster.local:8181/root/playground.git
```

`localhost:8929` is only for you, from your machine.

## What gitlab-values.yaml buys us

The default chart deploys about 30 pods. With this values file it renders
**7**, checked with `helm template`:

```
gitlab-webservice-default    gitlab-gitaly       gitlab-postgresql
gitlab-gitlab-shell          gitlab-minio        gitlab-redis-master
gitlab-sidekiq-all-in-1-v2
```

Turned off: cert-manager, the NGINX ingress controller, Prometheus, the
GitLab runner, the container registry, KAS, the metrics exporter, the backup
toolbox and incoming email. The autoscaling groups are pinned to 1 pod each.

## Why chart 9.11.10 and not the newest

`--version 9.11.10` installs GitLab **18.11.9**, and that chart still ships its
own PostgreSQL, Redis and MinIO, so GitLab runs by itself.

Since chart **10.0.0** the bundled Redis was removed and object storage became
mandatory, so the newest chart refuses to install without an external Redis and
an S3-compatible storage configured by hand. That is a lot of extra
infrastructure for a lab, so this bonus pins the last self-contained chart.

## Notes

- The project is created **public** so Argo CD needs no credentials. The repo
  never leaves the cluster, so there is nothing to protect.
- GitLab is still heavy: budget ~4 GB of RAM for these 7 pods. If they stay
  `Pending`, the machine is out of memory — give the VM more.
- Gitaly, PostgreSQL, Redis and MinIO each claim a volume; k3d's local-path
  provisioner handles that with no extra setup.
