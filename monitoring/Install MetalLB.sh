#!/bin/bash

#Install MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.15.0/config/manifests/metallb-native.yaml


#Wait until pods are running:
kubectl get pods -n metallb-system
