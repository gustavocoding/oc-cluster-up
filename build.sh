# Create builder image first
docker build -t builder --target builder .

# Build dind images
docker run -v /var/run/docker.sock:/var/run/docker.sock --entrypoint="hack/dind-cluster.sh" builder build-images

# Build main image
docker build -t gustavonalle/oc-cluster-up .
