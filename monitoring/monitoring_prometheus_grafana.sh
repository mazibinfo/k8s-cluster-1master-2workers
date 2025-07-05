#!/bin/bash

#Add the Prometheus community Helm repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

#Install kube-prometheus-stack (includes Prometheus, Grafana, Alertmanager)
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace

# Add this to your /etc/hosts:
# k get svc -n ingress-nginx
# <LOAD_BALANCER_EXTERNAL-IP> prometheus.local