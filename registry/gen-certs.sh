DEST=/docker-operator

MASTER=$(oc describe nodes/openshift-master-node  | grep InternalIP | awk '{print $2}')

openssl req -newkey rsa:2048 -nodes -subj "/C=UK/ST=UK/L=London/O=RedHat/CN=*.router.${MASTER}.nip.io" -keyout $DEST/registry.key -x509 -days 365 -out $DEST/registry.crt
openssl x509 -in $DEST/registry.crt -out $DEST/registry.pem -outform PEM
openssl rsa -in  $DEST/registry.key -out $DEST/registry.key.pem -outform PEM

KEY=$(sed 's/^/      /'  $DEST/registry.key.pem)
CER=$(sed 's/^/      /'  $DEST/registry.pem)

cat <<- EOF > $DEST/route.yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: registry
  namespace: openshift-image-registry
spec:
  host: registry.router.${MASTER}.nip.io
  to:
    kind: Service
    name: image-registry
  port:
    targetPort: 5000-tcp
  tls:
    termination: reencrypt
    certificate: |-
${CER}
    key: |-
${KEY}
    insecureEdgeTerminationPolicy: Redirect
  wildcardPolicy: None
EOF
