#!/bin/bash

set -x

cd $GOPATH/src/github.com/openshift/origin/

make all WHAT="cmd/oc" 
make all WHAT="cmd/sdn-cni-plugin" 
make all WHAT="vendor/github.com/containernetworking/plugins/plugins/ipam/host-local" 
make all WHAT="vendor/github.com/containernetworking/plugins/plugins/main/loopback" 
make all WHAT="cmd/hypershift cmd/template-service-broker" 
make all WHAT="cmd/openshift-node-config" 
make all WHAT="cmd/openshift-sdn" 
make all WHAT="cmd/openshift" 
make all WHAT="vendor/k8s.io/kubernetes/cmd/hyperkube" 
