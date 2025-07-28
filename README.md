# High-Availability Todo Application

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)](#)
[![License](https://img.shields.io/badge/license-MIT-blue)](#)

## Project Summary

A production-ready, high-availability **Todo** application deployed on **Docker Swarm** with zero-downtime CI/CD.  
The stack uses **HAProxy** for load balancing and fail-over, **Jenkins** + **Kaniko** for secure image builds, and **Harbor** as a private registry.  
Automated **PostgreSQL** backups and **Cloudflare** for DNS & access control keep the platform reliable and secure.

### Highlights

- **Docker Swarm Cluster** – 3 nodes (1 manager, 2 workers) for orchestration and replication  
- **HAProxy Layer** – 2 nodes providing load-balanced traffic and seamless fail-over  
- **Cloudflare Zero Trust** – DNS + restricted `/admin` access (only `kkaptanoglu@vmind.com.tr`)  
- **CI/CD Pipeline** – Jenkins (non-root) triggers Kaniko builds, pushes to Harbor, then rolls out updates  
- **Automated Backups** – Nightly PostgreSQL dumps with 7-day retention  
- **Horizontal Scaling** – `docker service scale` + rolling updates keep services online  

## Architecture Diagram



| Component              | Purpose                                                     |
| ---------------------- | ----------------------------------------------------------- |
| **Cloudflare**         | DNS, WAF, Zero-Trust access                                 |
| **VMind Net Balancer** | Single entry-point for inbound traffic                      |
| **HAProxy (×2)**       | Internal load balancers with health-checks & fail-over      |
| **Docker Swarm**       | Orchestrates app & DB containers                            |
| **PostgreSQL**         | Internal database (no public exposure)                      |
| **Jenkins**            | CI/CD orchestration                                         |
| **Kaniko**             | Rootless container image builds                             |
| **Harbor**             | Private container registry                                  |
| **Backup Volume**      | Stores nightly database dumps                               |

---


## Prerequisites

> **Minimum lab**: 5 Ubuntu 22.04 LTS VMs on an isolated network (`10.10.8.0/24`).  
> All ingress passes through **Cloudflare → VMind Net Balancer**. No public IPs are required.

### Hardware

| Role                | vCPU | RAM | Disk | Example Hostname |
| ------------------- | ---- | --- | ---- | ---------------- |
| Swarm Manager       | 2    | 4 GB | 20 GB | `node1-swarm`    |
| Swarm Worker (DB)   | 2    | 4 GB | 20 GB | `node2-db`       |
| Swarm Worker (App)  | 2    | 4 GB | 20 GB | `node3-app`      |
| HAProxy #1          | 1    | 2 GB | 10 GB | `node4-haproxy`  |
| HAProxy #2          | 1    | 2 GB | 10 GB | `node5-haproxy`  |

### Software

- **Docker Engine 24.x** + docker compose plugin (all nodes)  
- **HAProxy 2.9** (runs as a container on `node4` & `node5`)  
- **Jenkins LTS 2.x** (non-root, installed on `node1`)  
- **Kaniko executor v1.x** (`gcr.io/kaniko-project/executor:latest`)  
- **Harbor ≥ 2.10** (deployed as separate stack or external service)  
- **PostgreSQL 15** (containerized)  
- **Git CLI** on Jenkins node  
- **Cloudflare** account with API token & a registered domain  

### Networking & Security

| Port  | Source → Destination               | Purpose                    |
| ----- | ---------------------------------- | -------------------------- |
| 80/443 | Cloudflare → VMind Net Balancer    | HTTP/S ingress             |
| 80/443 | Net Balancer → HAProxy nodes       | Internal LB traffic        |
| 2377  | Swarm nodes                        | Swarm control plane        |
| 7946  | Swarm nodes                        | Gossip & node discovery    |
| 4789  | Swarm nodes                        | VXLAN overlay network      |
| 5432  | App tasks → PostgreSQL             | Database connection        |
| 8080  | Admin PC → Jenkins                 | CI/CD dashboard (internal) |

### Cloudflare Setup

1. Add your domain in Cloudflare and update registrar nameservers.  
2. Generate a scoped **API Token** (`Zone → DNS Edit` + `Zone → Access:Apps & Policies`).  
3. Create an **Access Application** for `https://<domain>/admin/*` and allow only `kkaptanoglu@vmind.com.tr`.  

### Credentials & Secrets

| Secret                   | Location               | Example                          |
| ------------------------ | ---------------------- | -------------------------------- |
| `POSTGRES_PASSWORD`      | Swarm secret `pg_pass` | `supersecret123`                 |
| Harbor robot-account     | Jenkins credentials    | `harbor-ci:***`                  |
| Cloudflare API Token     | Jenkins + HAProxy      | `CLOUDFLARE_API_TOKEN=***`       |
| SSH key for HAProxy sync | `~/.ssh/haproxy_sync`  | `id_rsa` & `id_rsa.pub`          |

### Environment Variables (sample)

```env
POSTGRES_DB=todos
POSTGRES_USER=admin
POSTGRES_PASSWORD=${PG_PASS}
APP_ENV=production
APP_PORT=8000
```

## Infrastructure Setup

> All commands assume **Ubuntu 22.04** hosts and a user with password-less `sudo`.

### 1 – Install Docker on Every Node

```bash
curl -fsSL https://get.docker.com | sudo bash
sudo usermod -aG docker $USER    # log out & back in
# Compose plugin
sudo apt-get install docker-compose-plugin -y
```
## Infrastructure Setup

> All examples assume **Ubuntu 22.04** VMs on the `10.10.8.0/24` network and a user with password-less `sudo`.

### Docker & Swarm

1. **Install Docker Engine** on every node (manager + workers) with the official convenience script, then enable the Compose plugin.
2. **Initialize Swarm** on the manager (`node1-swarm`) and join each worker with the `docker swarm join …` command that Swarm prints.
3. **Create an overlay network** (e.g. `app_net`) so services can discover each other across nodes.

### Harbor (Private Registry)

- Expose Harbor only on the internal network; Swarm nodes will push/pull images over that private address.

### HAProxy Layer

| Goal | Approach |
|------|----------|
| Load-balance app traffic | Run **two HAProxy containers** (one per HAProxy node) as a Swarm service with `--publish mode=host,target=80` so each listens on the node’s local port 80. |
| Config consistency | Store `haproxy.cfg` as a Swarm **config object**.<br>Use a **cron-triggered `rsync` script** from node 4 ➜ node 5 to keep manual edits in sync and restart the container on change. |
| Fail-over | Cloudflare → VMind Net Balancer always sends traffic to *both* HAProxy IPs; if one node dies, the other keeps serving. |

### Secrets & Credentials

| Secret                  | How to store                |
|-------------------------|-----------------------------|
| PostgreSQL password     | `docker secret create pg_pass …` |
| Harbor robot account    | Jenkins credential (username / robot token) |
| Cloudflare API token    | Jenkins + Swarm secret (if HAProxy automates DNS) |
| SSH key for HAProxy sync| `~/.ssh/haproxy_sync` on node 4 (public key on node 5) |

### PostgreSQL Service

- Deploy a single-replica `postgres:15` container pinned to `node2-db`.
- Mount a named volume (`pgdata`) for durability.
- Reference the `pg_pass` secret via `POSTGRES_PASSWORD_FILE`.

### Todo Application Service

- Build the image in Jenkins with **Kaniko** and push to Harbor.
- Deploy a Swarm service (`app_stack_web`) with **2+ replicas** on the overlay network.
- Enable rolling updates (`update_config`) so new images go live with zero downtime.

### Jenkins (non-root)

1. Add a dedicated `jenkins` user, bind-mount `/opt/jenkins_home`, and run the official `jenkins/jenkins:lts` Docker image on port 8080.
2. Install plugins: **Docker**, **Pipeline**, **Credentials Binding**.
3. Simply use `container('kaniko')` in the pipeline to build images without Docker-in-Docker.

### CI/CD Flow (high-level)

1. **Checkout** code from Git.  
2. **Build & Push** image with Kaniko to Harbor (`todo/web:<BUILD_NUMBER>`).  
3. **Deploy** via `docker service update --image harbor… todo_stack_web`.  
4. Swarm performs **rolling update**; HAProxy continues routing traffic; users see no downtime.

### Database Backup Strategy

- Host-level cron job on `node2-db` runs nightly:  
  `pg_dump | gzip → /home/ubuntu/db_backups/backup_YYYY-MM-DD.sql.gz`
- A second cron cleans backups older than 7 days with `find … -mtime +7 -delete`.

---

*At this point the cluster runs end-to-end with zero-downtime updates, automated backups, and internal-only exposure. Next steps: document Cloudflare DNS records & Access policies, plus advanced scaling or monitoring if required.*
