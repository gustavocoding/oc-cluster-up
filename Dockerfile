# Console stage

FROM quay.io/coreos/tectonic-console-builder:v16 as console

RUN mkdir -p /go/src/github.com/openshift/ && cd /go/src/github.com/openshift/ && git clone https://github.com/openshift/console && cd console && ./build.sh 
RUN mkdir /console
RUN cp -r /go/src/github.com/openshift/console/frontend/public/dist/ /console/ 
RUN cp -r /go/src/github.com/openshift/console/contrib /console/contrib
RUN cp -r /go/src/github.com/openshift/console/examples /console/examples
RUN cp /go/src/github.com/openshift/console/bin/bridge /console/bridge

# Base Os stage

FROM fedora:29 as base-os 

RUN dnf -y install docker findutils golang jq && dnf clean all

# Builder stage 

FROM base-os as builder

RUN dnf -y install git which sudo krb5-devel jq rsync && dnf clean all

ENV HOME=/root/
ENV GOPATH=$HOME/go
ENV PATH="$PATH:$GOPATH/bin"

RUN echo $'export GOPATH=$HOME/go \n\
export PATH=$PATH:$GOPATH/bin     \n\
export OS_OUTPUT_GOPATH=1         \n\
export ORIGIN_BIN=$GOPATH/src/github.com/openshift/origin/_output/local/bin/linux/amd64/ \n\
PATH=$ORIGIN_BIN:$PATH' >> /root/.bash_profile

COPY patches/ /patches/

RUN git clone https://github.com/operator-framework/operator-lifecycle-manager /operator-lifecycle-manager

RUN mkdir -p $GOPATH/src/github.com/openshift && cd $GOPATH/src/github.com/openshift && git clone https://github.com/openshift/cluster-image-registry-operator.git && cp -r $GOPATH/src/github.com/openshift/cluster-image-registry-operator/deploy /docker-operator/ && rm -Rf $GOPATH/src/github.com/openshift/cluster-image-registry-operator 

WORKDIR $GOPATH/src/github.com/openshift
RUN git clone https://github.com/openshift/origin 
WORKDIR $GOPATH/src/github.com/openshift/origin
RUN /patches/apply.sh
RUN make all 
RUN rsync -r --exclude '.git' --exclude '_output/local/bin/linux/amd64/openshift-tests' --exclude 'pkg/' --exclude 'vendor/' --exclude 'api/' --exclude 'docs/' --exclude 'examples/' /root/go/src/github.com/openshift/origin/ /origin 

# Main stage

FROM base-os 

MAINTAINER gustavonalle@gmail.com

COPY --from=console /console /console

COPY --from=builder /docker-operator /docker-operator

COPY --from=builder /operator-lifecycle-manager  /operator-lifecycle-manager

COPY --from=builder /origin /origin

COPY registry/ docker-operator/

COPY run.sh /origin 

COPY registry.crt /

EXPOSE 9000

WORKDIR /origin/

ENTRYPOINT /origin/run.sh 
