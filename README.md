# oc-cluster-up


Docker container to launch a multi-node, docker-in-docker [OKD](https://okd.io) cluster. For Linux hosts, it works without virtualization so it's extremelly fast and lightweight. 


:rotating_light::rotating_light: This repo uses alpha software and should only be used for development and test purposes. :rotating_light::rotating_light:

Code is taken from ```master``` branch of [origin](github.com/openshift/origin), plus the [console](github.com/openshift/console) and the [operatore-lifecycle-manager](https://github.com/operator-framework/operator-lifecycle-manager).

To launch in the foreground on Linux, make sure SELinux is disabled and run:

```
docker run -it -p 9000:9000 -v /tmp/:/tmp/ -v /etc/docker/certs.d/:/certs/ -v /var/run/docker.sock:/var/run/docker.sock gustavonalle/oc-cluster-up
```

Open another terminal, and you should see one master, one node, and the main container:

```
$ docker ps
CONTAINER ID        IMAGE                         CREATED             PORTS         
d74781e6a89b        openshift/dind-node           20 minutes ago     openshift-node-2
7bd51a24a055        openshift/dind-node           20 minutes ago     openshift-node-1
8d995fcdbe4f        openshift/dind-master         20 minutes ago     openshift-master
e1c4886f6162        gustavonalle/oc-cluster-up    23 minutes ago     cranky_clarke

```

Alternativelly, type ```Ctrl+p``` then ```Ctrl+q``` to reuse the same terminal.

### Demo

![asciiart](https://github.com/gustavonalle/oc-cluster-up/raw/master/demo.gif)


### MacOS

[MacOS hosts](README-macos.md) need docker-machine to work.

### Cluster size

By default the cluster size is 2 (master + 1 node), but the size can be changed with the environment variable NODES.


E.g., to run a single node cluster (master only):

```
docker run -e "NODES=0" ...
```

### Console

Console will be reachable on https://localhost:9090

### Registry

The registry can be accessed from outside OKD at the master container in the URL https://registry.router.MASTER_IP.nip.io.

Example of usage:

```
MASTER=$(oc describe nodes/openshift-master-node  | grep InternalIP | awk '{print $2}')

# Pull an existing public image
docker pull jboss/infinispan-server

# Tag it to use in the 'myproject' namespace
docker tag jboss/infinispan-server registry.router.$MASTER.nip.io/myproject/infinispan

# Login as developer
oc login -u developer -p developer

# Create project
oc new-project myproject

# Login to the registry
docker login -u $(oc whoami) -p $(oc whoami -t) https://registry.router.$MASTER.nip.io/

# Push the image
docker push registry.router.$MASTER.nip.io/myproject/infinispan

# Create a new app using the internal image
oc new-app myproject/infinispan
```

### Pausing and resuming

It's possible to stop the containers without destroying, thus preserving all downloaded images and configs. Use the command to stop:

```
docker stop openshift-node-1 openshift-node-2 openshift-master
```

and to start:
```
docker start openshift-master openshift-node-1 openshift-node-2
```

### Cleanup

To destroy all containers and files created, while preserving the images, use this script:

```
docker kill $(docker ps -q) && docker system prune -f && sudo rm -Rf /tmp/openshift*
```

### Sample application

In case ```oc``` is not installed locally, it's possible to reuse it from the master:

```
alias okd="docker exec -it openshift-master oc"
```

The commands below will create a new app and expose it outside OKD:

```
okd new-app openshift/hello-openshift --name app
okd expose svc/app
```

Go to http://app-default.router.172.17.0.3.nip.io/ for a welcome message from Openshift!

Note: The master may not be 172.17.0.3 in your installation, to find out, run ```oc describe nodes/openshift-master-node  | grep InternalIP | awk '{print $2}'```


### TODO

* Prometheus
* S2i support


### Common Errors

#### Permission denied

On Docker 1.13.1, the docker image might fail to start up showing permission errors like this (via `docker logs ...`):

```bash
go: creating work dir: mkdir /tmp/go-build717279851: permission denied
go: creating work dir: mkdir /tmp/go-build462782577: permission denied
mkdir: cannot create directory '/tmp/openshift': Permission denied
```

You can get around the problem by adding `--privileged` to the `docker run` call, e.g.

```bash
docker run --privileged --name oc-cluster-up ...
```
