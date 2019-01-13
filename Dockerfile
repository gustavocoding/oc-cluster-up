FROM quay.io/coreos/tectonic-console-builder:v16 as console

RUN mkdir -p /go/src/github.com/openshift/ && cd /go/src/github.com/openshift/ && git clone https://github.com/openshift/console && cd console && ./build.sh 
RUN mkdir /console
RUN cp -r /go/src/github.com/openshift/console/frontend/public/dist/ /console/ 
RUN cp -r /go/src/github.com/openshift/console/contrib /console/contrib
RUN cp -r /go/src/github.com/openshift/console/examples /console/examples
RUN cp /go/src/github.com/openshift/console/bin/bridge /console/bridge

FROM fedora:29

MAINTAINER gustavonalle@gmail.com

RUN dnf -y install golang git findutils which sudo krb5-devel jq docker && dnf clean all

ENV HOME=/root/
ENV GOPATH=$HOME/go
ENV PATH="$PATH:$GOPATH/bin"

RUN echo $'export GOPATH=$HOME/go \n\
export PATH=$PATH:$GOPATH/bin     \n\
export OS_OUTPUT_GOPATH=1         \n\
export ORIGIN_BIN=$GOPATH/src/github.com/openshift/origin/_output/local/bin/linux/amd64/ \n\
PATH=$ORIGIN_BIN:$PATH' >> /root/.bash_profile

COPY patches/ /patches/

COPY compile.sh /root/

RUN mkdir -p $GOPATH/src/github.com/openshift && cd $GOPATH/src/github.com/openshift && git clone https://github.com/openshift/origin && cd origin && \
    /patches/apply.sh && \
    /root/compile.sh && \
    rm -Rf pkg/ vendor/ _output/local/bin/linux/amd64/openshift-tests /api/ docs/ examples/ && \
    git config pack.windowMemory 512m && git gc --prune=now --aggressive

COPY --from=console /console /console

RUN git clone https://github.com/operator-framework/operator-lifecycle-manager ~/operator-lifecycle-manager

COPY run.sh $GOPATH/src/github.com/openshift/origin 

EXPOSE 9000

WORKDIR $GOPATH/src/github.com/openshift/origin/

ENTRYPOINT $GOPATH/src/github.com/openshift/origin/run.sh 
