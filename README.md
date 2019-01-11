# oc-cluster-up
OKD 4.0.0 from ```master``` branch with the admin console and operatore-lifecycle-manager

```
docker run -it -p 9000:9000 -v /tmp/:/tmp/ -v /var/run/docker.sock:/var/run/docker.sock gustavonalle/oc-cluster-up
```

Disclaimer: the container is based on alpha software and should be used for development and test purposes only. 
