# GitOps Pipeline on Kubernetes

A multi-node K3s cluster on AWS (provisioned with Terraform), continuously synced from this Git repo by ArgoCD. Includes Prometheus + Grafana + Alertmanager for observability and a Horizontal Pod Autoscaler validated under load tests.

## Stack

| Layer            | Tool                        |
|------------------|-----------------------------|
| IaC              | Terraform (S3 + DynamoDB state backend) |
| Cluster          | K3s on AWS EC2 (1 server + 1 agent) |
| GitOps           | ArgoCD (App-of-Apps pattern) |
| Observability    | kube-prometheus-stack (Prometheus, Grafana, Alertmanager) |
| Autoscaling      | HorizontalPodAutoscaler + load tests with `hey` |

Status: in progress (Phase 1 — Terraform foundation).
