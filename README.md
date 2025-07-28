Project Summary

A production-ready, high-availability Todo application deployed on Docker Swarm with zero-downtime CI/CD. This setup leverages HAProxy for load balancing and failover, Jenkins with Kaniko for secure image builds, and Harbor as a private registry. Automated PostgreSQL backups and Cloudflare for DNS and access control ensure reliability and security.

Highlights:

Docker Swarm Cluster: 3 nodes (1 manager, 2 workers) for container orchestration and service replication.

HAProxy Layer: 2 nodes providing load balancing and seamless failover.

Cloudflare Integration: DNS management and Zero Trust Access control restricted to kkaptanoglu@vmind.com.tr.

CI/CD Pipeline: Jenkins (non-root) triggers Kaniko builds and pushes images to Harbor, followed by rolling updates.

Automated Backups: Nightly PostgreSQL dumps with retention policy.

Scaling & HA: Service scaling via docker service scale and rolling updates to maintain uptime.

Architecture Diagram



Components:

Component

Purpose

Cloudflare

DNS, external traffic protection, Access

VMind Net Balancer

Single entry point for inbound traffic

HAProxy (2 nodes)

Internal load balancer with failover

Docker Swarm Cluster

Orchestrates app & DB services

PostgreSQL

Internal DB, accessible only within Swarm

Jenkins

CI/CD orchestration (build & deploy)

Kaniko

Non-root Docker image builds

Harbor

Private Docker registry

Backup Volume

Stores nightly DB dumps
