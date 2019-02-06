#!/bin/bash

set -e


NODES=${NODES:=1}

# Pull dependend images
docker pull gustavonalle/openshift-dind-node
docker pull gustavonalle/openshift-dind-master

# Start the cluster
hack/dind-cluster.sh start -N $NODES

source /origin/dind-openshift.rc

MASTER=$(oc describe nodes/openshift-master-node  | grep InternalIP | awk '{print $2}')

# Add nip.io self signed certificate for docker
/docker-operator/gen-certs.sh
mkdir -p /certs/registry.router.${MASTER}.nip.io/
cp /docker-operator/registry.crt /certs/registry.router.${MASTER}.nip.io/

# Install router on master node
oc adm manage-node openshift-master-node --schedulable
oc adm policy add-scc-to-user hostnetwork -z router
oc adm router --selector=kubernetes.io/hostname=openshift-master-node

# Install OLM
cd /operator-lifecycle-manager
oc adm policy add-cluster-role-to-user cluster-admin system
for filename in deploy/okd/manifests/latest/*.yaml
do
     echo "Processing $filename"
     oc create -f $filename
done

# Install Registry Operator
/docker-operator/prepare.sh
for filename in /docker-operator/*.yaml
do
   oc create -f $filename
done
oc apply -f /docker-operator/route.yaml

# Configure OAUTH and lauch the console
cd /console
oc login -u system:admin
oc process -f /console/examples/console-oauth-client.yaml | oc apply -f -
oc get oauthclient console-oauth-client -o jsonpath='{.secret}' > examples/console-client-secret
oc get secrets -n default --field-selector type=kubernetes.io/service-account-token -o json | jq '.items[0].data."service-ca.crt"' -r | python -m base64 -d > examples/ca.crt
export OPENSHIFT_API="https://$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' openshift-master):8443"
./bridge \
   --base-address=http://localhost:9000 \
   --ca-file=examples/ca.crt \
   --k8s-auth=openshift \
   --k8s-mode=off-cluster \
   --k8s-mode-off-cluster-endpoint=$OPENSHIFT_API \
   --k8s-mode-off-cluster-skip-verify-tls=true \
   --listen=http://0.0.0.0:9000 \
   --public-dir=/console/dist \
    --user-auth=openshift \
    --user-auth-oidc-client-id=console-oauth-client \
    --user-auth-oidc-client-secret-file=examples/console-client-secret \
    --user-auth-oidc-ca-file=examples/ca.crt

# Alternative Without OAUTH
# oc login -u system:admin
# oc adm policy add-cluster-role-to-user cluster-admin admin
# oc login -u admin -p admin
# source ./contrib/oc-environment.sh
# ./bridge --public-dir=/console/dist

