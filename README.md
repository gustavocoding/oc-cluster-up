## oc-cluster-up

Docker container to launch a docker-in-docker OKD cluster.

Code is taken from ```master``` branch of github.com/openshift/origin, plus the console from github.com/openshift/console and the operatore-lifecycle-manager.

To launch:

```
docker run -it -p 9000:9000 -v /tmp/:/tmp/ -v /var/run/docker.sock:/var/run/docker.sock gustavonalle/oc-cluster-up
```

| DISCLAIMER: the container is based on alpha software and should be used for development and test purposes only. 
