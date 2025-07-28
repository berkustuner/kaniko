High-Available Todo Application

1. Project Summary

This repository contains a production-ready setup for a high-availability Todo application using Docker Swarm, HAProxy, Jenkins, Kaniko, and Harbor. The solution ensures zero-downtime deployments, automated database backups, and secure access controls via Cloudflare.

Key features:

3-node Docker Swarm cluster (1 manager + 2 workers)

2-node HAProxy layer for load balancing and failover

Secure domain management through Cloudflare

Automated PostgreSQL backups with retention policy

CI/CD pipeline using Jenkins (non-root), Kaniko, and Harbor registry

Horizontal scaling and rolling updates via Docker Swarm

Access control for admin panel (/admin) restricted to kkaptanoglu@vmind.com.tr

2. Architecture Diagram



Components:

Cloudflare: DNS management, external access control (Zero Trust)

VMind Net Balancer: Single entry point for all inbound traffic

HAProxy nodes (node4 & node5): Internal load balancers with failover

Docker Swarm cluster:

node1 (manager)

node2 (worker, database)

node3 (worker, application)

PostgreSQL: Internal-only, replicated via Docker Swarm

Jenkins: CI/CD orchestrator (builds with Kaniko)

Kaniko: Container image builder without root

Harbor: Private container registry

Backups: Stored in host volume (/home/ubuntu/db_backups) with cron retention
