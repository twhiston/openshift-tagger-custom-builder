FROM openshift/origin

MAINTAINER Yann Moisan <yamo93@gmail.com>

LABEL io.k8s.description="Custom Image Builder" \
      io.k8s.display-name="Custom Builder" \
      io.openshift.tags="builder,custom"


RUN yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo && \
    yum install -y --enablerepo=centosplus epel-release gettext automake make docker-ce && \
    yum install -y jq && \
    yum clean all -y

ENV HOME /root \
    PUSH_IMAGE="true"

ADD ./build.sh /tmp/build.sh

ENTRYPOINT [ "/bin/sh", "-c" ]

CMD [ "/tmp/build.sh" ]
