#!/bin/bash

#Add the Helm Repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

#Install the Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace