# Builds should be available on https://quay.io/organization/openscanhub-fedora-infra/fedora-osh-hub
# TODO: Check if we can use ubi.
# resalloc dependencies require a subscription.
# FROM registry.access.redhat.com/ubi9/httpd-24
FROM quay.io/sclorg/httpd-24-c9s

USER 0

RUN dnf install -y epel-release

RUN dnf config-manager --set-enabled crb extras-common

# enable installation of gettext message objects
RUN rm /etc/rpm/macros.image-language-conf

#TODO: How to enable installation of a specifiec commit?
# RUN dnf copr enable -y @openscanhub/devel
# TODO: REMOVE `packit/openscanhub-openscanhub-234` WHEN UPSTREAM PR IS MERGED:
# https://github.com/openscanhub/openscanhub/pull/234
RUN dnf copr enable -y packit/openscanhub-openscanhub-234

# Keep these here as a reference for debugging in the future.
# RUN dnf copr enable -y praiskup/resalloc
# RUN dnf copr enable -y @copr/copr
RUN dnf config-manager --add-repo https://pagure.io/fedora-infra/ansible/raw/main/f/files/common/epel9.repo

# TODO: This would install osh-hub configurations from the `hub-conf-devel` package. How to install
# non-devel configurations for fedora infrastrucutre?
# TODO: There may be a race condition here, as it installs latest `osh-hub` package, that may have
# been built after a specific commit.
# tzdata is a dependency for django
RUN dnf install -y osh-hub osh-hub-conf-devel openssl krb5-workstation tzdata fedora-messaging

RUN dnf install -y resalloc-agent-spawner osh-worker-manager

# TODO: Shall `/var/log/osh/` be a persistennt path? Shall this log be redirected to another logging
# service like splunk?
RUN touch /var/log/osh/hub/hub.log && chown :root /var/log/osh/hub/hub.log
# TODO: Set correct permissions on below files.
RUN chown -R :root /var/log/osh/hub /opt/app-root/ /var/run/
RUN chmod -R g+rw /var/log/osh/hub  /opt/app-root/ /var/run/

# TODO: may be enable `mod_security` in apache httpd.
# This is a temporary workaround to allow large report uploads from worker to the hub.
# This change should be revisited before moving to production.
RUN rm -f /etc/httpd/conf.d/mod_security.conf

EXPOSE 8080
EXPOSE 8443

# Override default footer to mention the mailing list.
COPY configs/footer.html /etc/osh/hub/templates/footer.html

# Custom `redhat.css` changes color of the header to blue.
# This should be removed when https://issues.redhat.com/browse/OSH-198 is resolved.
COPY configs/redhat.css /usr/lib/python3.9/site-packages/osh/hub/static-assets/css/redhat.css
COPY configs/redhat.css /usr/lib/python3.9/site-packages/osh/hub/static/css/redhat.css

COPY configs/resalloc-agent-spawner-config.yaml /etc/resalloc-agent-spawner/config.yaml
RUN mkdir /var/log/resalloc-agent-spawner
RUN chmod g+rwx /var/log/resalloc-agent-spawner

COPY scripts/run_hub.sh /run_hub.sh

# Keep these here as a reference for debugging in the future.
# RUN dnf install -y python3-ipdb
# COPY worker.py /usr/lib/python3.9/site-packages/resalloc_agent_spawner/worker.py
# RUN chmod g+rwx /usr/lib/python3.9/site-packages/resalloc_agent_spawner/worker.py
# RUN chown :root /usr/bin/osh-worker-manager
# RUN chmod g+rwx /usr/bin/osh-worker-manager

###########
RUN chmod a+x /run_hub.sh
# This is for backward compatibility. Remove this?
USER 1001

# Commands in this path are used by osh-worker-manager
ENV PATH=/sbin:/bin:/usr/sbin:/usr/bin
CMD /run_hub.sh
