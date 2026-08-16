# Part 1 — K3s and Vagrant

Two VirtualBox machines built by Vagrant, running K3s as a small cluster.

| Machine | IP | Role |
|---|---|---|
| `ooulcaidS` | 192.168.56.110 | K3s **server** (controller) |
| `ooulcaidSW` | 192.168.56.111 | K3s **agent** (worker) |

Each VM gets 1 CPU and 1024 MB of RAM, as asked by the subject.

## Layout

```
p1/
├── Vagrantfile
└── scripts/
    ├── server.sh    # K3s in controller mode
    └── worker.sh    # K3s in agent mode, joins the server
```

## Usage

```bash
cd p1
vagrant up            # builds both machines, ~5-10 min
vagrant ssh ooulcaidS
kubectl get nodes
```

Expected result: both nodes `Ready`, the second one with the role `<none>`.

```
NAME         STATUS   ROLES                  AGE   VERSION
ooulcaids    Ready    control-plane,master   3m    v1.xx.x+k3s1
ooulcaidsw   Ready    <none>                 2m    v1.xx.x+k3s1
```

SSH needs no password: Vagrant installs its key when the machine is created,
so `vagrant ssh <name>` just works.

## How the worker joins

A K3s agent needs the server's token. The server writes it into the folder
Vagrant shares between the host and both machines:

```
server.sh   ->  /var/lib/rancher/k3s/server/node-token  copied to  /vagrant/node-token
worker.sh   ->  waits for that file, then uses it to join
```

`node-token` is a secret, it is in `.gitignore` and never committed.

## About the network interface

The VMs have two network cards: the one Vagrant uses to talk to the machine,
and the one holding our `192.168.56.x` address. K3s must use the second one,
otherwise the nodes cannot see each other. Modern Ubuntu names it `enp0s8`
rather than `eth1`, so the scripts look the name up instead of hard-coding it:

```bash
IFACE=$(ip -o -4 addr show | grep "$IP" | awk '{print $2}')
```

## Useful commands

```bash
vagrant status              # state of both machines
vagrant ssh ooulcaidSW      # open a shell on the worker
vagrant halt                # stop them
vagrant destroy -f          # delete them
```
