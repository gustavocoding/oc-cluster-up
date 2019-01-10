## MacOS instructions 

### Requirements

Running on MacOS requires docker-machine, a docker backend that runs in a virtual machine. Follow the instructions:

1) Install Docker machine following https://docs.docker.com/machine/install-machine/

2) Create a machine called 'default' with a decent amount of memory:

```
docker-machine create --driver virtualbox --virtualbox-memory "4096" --virtualbox-cpu-count "2"  --virtualbox-boot2docker-url https://github.com/boot2docker/boot2docker/releases/download/v17.07.0-ce/boot2docker.iso default
```


### Running

1) Make sure the machine is started, if not run ```docker-machine start```

2) Env into the machine with ```eval "$(docker-machine env default)"```


From now on, you can use ```docker``` as if it were native for Mac. Create the cluster normally:

```
docker run -it -p 9000:9000 -v /tmp/:/tmp/ -v /var/run/docker.sock:/var/run/docker.sock gustavonalle/oc-cluster-up
```

### Console

Create a route to be able to acess containers by IP, and a tunnel to access the console as localhost:

```
sudo route -n add -net 172.17.0.0/16 $(docker-machine ip)
docker-machine ssh default -L 9000:localhost:9000 
```

Console will be on http://localhost:9000/

### Sample app

The hello world app can be used to test pods, services and routes:

```
alias okd="docker exec -it openshift-master oc"
okd new-app openshift/hello-openshift --name app
okd expose svc/app
```

Access http://app-default.router.172.17.0.3.nip.io/ for a message from Openshift.
