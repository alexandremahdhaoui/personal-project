# personal-project

This repository is intended to be a monorepo for personal projects discussions and implementations before these are
mature enough to become projects on their own.

The goal of `personal-project` is providing a centralized source of information regarding projects and their progress
and status.

## Cloud

- [ ] [Bare metal provisioning](bare-metal-provisionning/README.md)
- [ ] [Networking](./cloud/networking.md): figuring out isolation (VPC), and multi-AZ, -datacenter, -nodes setup...
- [ ] [Managed Kubernetes](./cloud/managed-kubernetes.md): (using cluster-api, kubeadm)
  - [ ] control plane
  - [ ] managed nodes
- [ ] [Storage](./cloud/storage.md):
  - [ ] Object (S3)
  - [ ] Block storage
- [ ] [Managed Observability, Tracking, Monitoring, Logging & Tracing](./cloud/managed-tracking.md):
  - [ ] Tagging paradigms & frameworks
  - [ ] Observability/Monitoring (Prometheus, Grafana)
  - [ ] Logging (Grafana's stack, or Elastic?)
  - [ ] Tracing (OTLP...)
- [ ] [Managed Secrets](./cloud/managed-secret.md)

## EatBetter
- [ ] Define MVP
- [ ] Abstract functional requirements (& domains?)

## DB as a Service
- [ ] Infinitely scalable database meta-engine
- [ ] Managed Postgres:
  - https://github.com/pgbouncer/pgbouncer
  - https://github.com/postgresml/pgcat
  - https://github.com/pg-sharding/spqr

## Programming Platform

- [ ] Subject/Object functional Model
- [ ] Tenancy framework
  - "meta-tenant", abstract the capability of the whole product/company as if any new company could lunch it at any 
time.  
- [ ] Authz Model
- [ ] User management
- [ ] Authx Model for programmatic users & infrastructures
