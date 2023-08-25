#! /bin/bash

CLUSTER_NAME=$(
    kubectl config get-contexts |
    grep $(terraform output -raw kubernetes_cluster_name) |
    awk '{ print $2 }'
  )

kubectl config unset contexts.$CLUSTER_NAME
kubectl config unset clusters.$CLUSTER_NAME
kubectl config unset users.$CLUSTER_NAME
