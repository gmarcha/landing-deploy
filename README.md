# landing-deploy

An infrastructure deployment with Terraform, Ansible and self-deployed Kubernetes on Google Cloud Platform following GitOps practices.

[![Google Cloud](https://img.shields.io/badge/GCP-%234285F4.svg?style=for-the-badge&logo=google-cloud&logoColor=white)](https://cloud.google.com/docs?hl=fr)
[![Terraform](https://img.shields.io/badge/terraform-%235835CC.svg?style=for-the-badge&logo=terraform&logoColor=white)](https://developer.hashicorp.com/terraform)
[![Ansible](https://img.shields.io/badge/ansible-%23cc0607.svg?style=for-the-badge&logo=ansible&logoColor=white)](https://docs.ansible.com/)
[![Kubernetes](https://img.shields.io/badge/kubernetes-%23326ce5.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://kubernetes.io/docs/home/)
[![K3s](https://img.shields.io/badge/k3s-%23323330.svg?style=for-the-badge&logo=k3s&logoColor=%23ffc71c)](https://docs.k3s.io/)
[![FluxCD](https://img.shields.io/badge/FluxCD-%23316ce4.svg?style=for-the-badge&logo=kubernetes&logoColor=white)](https://fluxcd.io/flux/)

## Requirements

- Install CLI:
  - `terraform`[^1],
  - `ansible`[^2],
  - `gcloud`[^3],
  - `kubectl`[^4] (optional).

## Usage

- Configure `/provision/terraform.tfvars.sample` and rename file to `/provision/terraform.tfvars`.
  - Create a service account key with `roles/compute.admin`[^5] permission in GCP,
  - Download key in json format and store it in `/provision/credentials/credentials.json`[^6].
  - Set project ID (from json credentials), project name and repository credentials.

- Configure `/config.yaml.sample` and rename file to `/config.yaml` (default values work for public repositories).

- Run `terraform`:
  - `cd provision/`,
  - `terraform init` to initialize current directory with Terraform,
  - `terraform plan` to check resource creation in a non-destructive way (dry-run),
  - `terraform apply` to create cloud resources (require validation).

## Repository

Repository is structured into three parts: a `/provision` directory for cloud-infrastructure provisioning with Terraform, a `/config` directory for configuration management with Ansible and `/deploy` directory for application configuration with Kubernetes.

- Terraform, creating cloud resources with infrastrucre as code. Describe infrastrcture and other possible infrastructres.
- Ansible, configure provisioned resources, installing k3s distribution. Describe both push/pull modes, each use case.
- Kubernetes, GitOps application management with auto-reconciliation and self-healing with FluxCD.

Cloud infrastructure is provisioned with Terraform on Google Cloud Platform. This infrastructure is made up of a network and a subnetwork, some firewall rules, a static ipv4 address and a virtual machine. Virtual machine is based on a boot disk contaning a Rocky Linux 9 image (optimized for GCP) and a network interface linked to static ipv4 address. Firewall rules are applied as tags to the virtual machine to allow external access. This virtual machine is a server node used as a bootstrap node, so configuration is using a `google_compute_instance` rather than a `google_compute_region_instance_group_manager`. Subsequent server and agent nodes could use a regional managed instance groups (MIG) to benefit from autoscaling and self-healing abilities. However MIG are more complex to setup because they require a cloud load balancer to work properly. GCP load balancers are based on `google_compute_backend_service`, `google_compute_url_map`, `google_compute_target_<protocol>_proxy` and `google_compute_global_forwarding_rule` resources.

Provisioned virtual machine is then configured with ansible in pull mode. While ansible default push mode is very straightforward for self-managed on-premise resources, this is very inefficient to configure virtual machine replicas managed by a cloud provider auto-scaler. Thus ansible can be used in pull mode with `ansible-pull` command. Virtual machines run a script provided through metadata to install ansible dependencies, run ansible-pull command to pull a remote repository (actually this repository) which contains a playbook and then execute it locally. This playbook executes roles to install fluxcd cli binary, k3s binary, configure and start k3s service, run flux bootstrap routine and provision kubernetes secrets. K3s configuration is based on node mode, i.e. primary, server or agent node.

Flux kustomize and helm controllers are in charge to reconcile flux kustomize and helm kubernetes custom resources. Flux bootstrap reconciled a kustomization in `/deploy/clusters/production` which itself reconciles `/deploy/infrastructure/controllers`, `/deploy/infrastructure/configs` and `/deploy/apps/production`. This configuration embraces GitOps practices, permitting to use continuous deployment and to apply rolling upgrade automatically. Infrastructure configuration is common among clusters and it lives on this repository. Application configurations on the other hand come from other public or private git repositories or helm charts. This repository pattern is flexible to follow operational requirements and ensure separation of concerns. Flux also makes available an image update automation controller which watches container registry to automatically update image tag in kubernetes deployment or custom resources (like an openshift deployment config). A receiver could be setup to push notification from a git repository to trigger reconciliation rather than pulling repository at regular interval.

Kubernetes resources are plain manifest for standard deployment, service, ingress resources or they are custom resource definitions for GitRepository, Kustomize, HelmRepository, HelmRelease. Custom resource definitions create new resources to interact with Kubernetes API. 

## Misc

### Scale k3s from single-node cluster to multi-node cluster

In production, 

### Manage secrets on Kubernetes

In production again, 

## Toolchain

### Infrastructure-as-Code: Terraform

Terraform is an Infrastructure-as-Code (IaC) tool. It allows to manage cloud resources in a declarative and stateful fashion. For this purpose, it provides a strongly typed configuration language named HCL (for HashiCorp Configuration Language). Terraform exposes providers to interact with cloud API. It currently supports most of the entreprise-grade cloud providers. Terraform handles a "state" to describe resource status thus providing reconciliation capabilities when operators perform configuration modification. This state should be stored in a terraform backend for production workloads.

- Documentation: [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- Documentation: [Terraform Backend](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)
- Provider registry: [Terraform Providers](https://registry.terraform.io/browse/providers)
- Provider registry: [Google Cloud Platform Provider](https://registry.terraform.io/providers/hashicorp/google/latest/docs)

### Configuration Management: Ansible

Ansible is a push configuration management tool suite written in Python. Its goal is to simplify upgrade and deploy process by providing way to write idempotent scripts. It is widely used to manage configuration either on physical machines or virtual machines. Configuration is based on playbooks which contain task units. A playbook runs each of its task sequentially and provides rich output for task status (changed, ok, failed, skipped, etc..). Tasks can be grouped in a reusable unit called a role. Ansible is a server-less configuration management tool. It only requires a ssh server on remote machines to perform configuration. Ansible also works in pull mode with a GitOps approach, fetching configuration from a remote repository and executing it locally.

## Roadmap

- Add managed instance group (MIG) for server nodes and agent nodes.
- Interactive UI to configure repository (Terraform and Ansible configuration files).

## Author

[@gmarcha](https://github.com/gmarcha)

## License

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

[^1]: [install terraform](https://developer.hashicorp.com/terraform/downloads) cli.
[^2]: [install ansible](https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html) suite.
[^3]: [install gcloud](https://cloud.google.com/sdk/docs/install) cli.
[^4]: [install kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/) cli.
[^5]: see Compute Engine [documentation](https://cloud.google.com/compute/docs/access/iam) for roles (follow least privilege principle in production environment).
[^6]: see Terraform [documentation](https://developer.hashicorp.com/terraform/tutorials/gcp-get-started/google-cloud-platform-build#set-up-gcp) and GCP [documentation](https://cloud.google.com/iam/docs/keys-create-delete).
