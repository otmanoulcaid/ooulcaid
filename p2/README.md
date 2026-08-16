# Part 2 — K3s and three applications

One machine, `ooulcaidS` at **192.168.56.110**, running K3s in server mode with
three web applications behind a single Ingress.

The application is chosen from the **HOST** of the request:

| Host | Application | Replicas |
|---|---|---|
| `app1.com` | app1 | 1 |
| `app2.com` | app2 | **3** |
| anything else | app3 | 1 |

## Layout

```
p2/
├── Vagrantfile
├── scripts/
│   └── server.sh      # K3s + deploys everything in confs/
└── confs/
    ├── app1.yaml      # ConfigMap + Deployment + Service
    ├── app2.yaml      # same, with 3 replicas
    ├── app3.yaml      # same, the default one
    └── ingress.yaml   # the HOST routing
```

Each app is an `nginx:alpine` serving one `index.html` that comes from a
ConfigMap. Nothing to build, nothing to push.

## Usage

```bash
cd p2
vagrant up
```

Then test from your own machine:

```bash
curl -H "Host: app1.com" http://192.168.56.110    # <h1>app1</h1>
curl -H "Host: app2.com" http://192.168.56.110    # <h1>app2</h1>
curl -H "Host: whatever" http://192.168.56.110    # <h1>app3</h1>
curl http://192.168.56.110                        # <h1>app3</h1>
```

To use a real browser instead, add this to your hosts file
(`/etc/hosts`, or `C:\Windows\System32\drivers\etc\hosts`):

```
192.168.56.110  app1.com app2.com
```

## Checking the 3 replicas

```bash
vagrant ssh
kubectl get pods -l app=app2      # 3 pods
kubectl get deployment app2       # READY 3/3
```

## How the default application works

The Ingress has three rules. The first two match a precise host. The third one
has **no host at all**, so it matches every other name — that is how app3
becomes the default:

```yaml
    - http:                 # no "host:" here
        paths:
          - path: /
            backend:
              service:
                name: app3
```

## Note on Traefik

K3s installs Traefik by default and it is what serves this Ingress, so it is
kept here. (In p3 it is disabled, because that part uses a NodePort instead.)
Show the Ingress during the defense with:

```bash
kubectl get ingress
kubectl describe ingress apps
```
