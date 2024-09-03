# TODO: Check if we can use ubi.
# resalloc dependencies require a subscription.
# FROM registry.access.redhat.com/ubi9/ubi
FROM quay.io/centos/centos:stream9
USER 0

RUN dnf install -y dnf-plugins-core
RUN dnf config-manager --set-enabled crb extras-common

RUN dnf install -y epel-release

# RUN dnf copr enable -y praiskup/resalloc
# RUN dnf copr enable -y @copr/copr
RUN dnf config-manager --add-repo https://pagure.io/fedora-infra/ansible/raw/main/f/files/common/epel9.repo

# Deployment instructions are described here
# https://github.com/praiskup/resalloc/blob/master/docs/start-resalloc-server.txt

RUN dnf install -y ansible \
                   findutils \
                   openssh-clients \
                   postgresql \
                   procps-ng \
                   python3-psycopg2 \
                   resalloc \
                   resalloc-aws \
                   resalloc-server \
                   util-linux \
                   vim

# copy filesystem setup
# COPY files/ /

# `/etc/resallocserver/` belongs to `resalloc` group and is not readable by `root`.
RUN chgrp -R root /etc/resallocserver/ /var/log/resallocserver /var/lib/resallocserver
RUN chmod -R g+rwx /etc/resallocserver/ /var/log/resallocserver /var/lib/resallocserver

# Set up aws configurations. Ssh key would be mounted from OpenShift.
RUN mkdir /var/lib/resallocserver/.aws /var/lib/resallocserver/.ssh
COPY configs/aws-config /var/lib/resallocserver/.aws/config

# `server.yaml` and `pools.yaml` are mount through OpenShift configurations.
RUN rm -f /etc/resallocserver/server.yaml /etc/resallocserver/pools.yaml

# RUN git clone --branch openscanhub-fedora-infra https://pagure.io/forks/svashisht/rhcopr/vm-provisioning.git /etc/resallocserver/vm-provisioning
COPY vm-provisioning /etc/resallocserver/vm-provisioning
# RUN git clone --branch main https://github.com/siteshwar/openscanhub-deployment-configs.git /etc/resallocserver/openscanhub-deployment-configs
# COPY openscanhub-deployment-configs /etc/resallocserver/openscanhub-deployment-configs

ENV HOME=/var/lib/resallocserver
ENV CONFIG_DIR=/etc/resallocserver

# `ControlPath` should be writable by `root` group.
RUN chmod -R g+rwx $HOME/.ssh
COPY configs/ssh_config $HOME/.ssh/config

USER 1001

# bash should be pid 1 in this container
# so zombie processes may not be created
# they would be collected by bash
# https://github.com/openscanhub/fedora-infra/issues/61
CMD bash -c "/usr/bin/resalloc-server || exit 1"
# CMD sleep inf
