#! /bin/bash

# Retrieve access credentials for the GKE cluster and automatically configure kubectl.

gcloud container clusters get-credentials \
  $(terraform output -raw kubernetes_cluster_name) \
  --region $(terraform output -raw region)
