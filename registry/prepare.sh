DIR=/etc/docker/certs.d/image-registry.openshift-image-registry.svc:5000/

NODES=${NODES:=1}

function prepare() {
 docker exec -it $1 mkdir -p $DIR
 docker cp service-ca.crt $1:$DIR
}

oc extract -n default $(oc get secrets -n default -o name | grep router-token | head -1) --keys service-ca.crt --confirm

prepare openshift-master

for (( i = 1; i <= $NODES; i++ ))
do
  prepare openshift-node-$i
done
