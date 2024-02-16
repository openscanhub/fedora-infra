# Builds should be available on https://quay.io/organization/openscanhub-fedora-infra/ocp
FROM registry.access.redhat.com/ubi9/httpd-24
USER 0

RUN dnf install -y dnf-plugins-core https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# enable installation of gettext message objects
RUN rm /etc/rpm/macros.image-language-conf

#TODO: How to enable installation of a specifiec commit?
RUN dnf copr enable -y @openscanhub/devel

# TODO: This would install osh-hub configurations from the `hub-conf-devel` package. How to install
# non-devel configurations for fedora infrastrucutre?
# TODO: There may be a race condition here, as it installs latest `osh-hub` package, that may have
# been built after a specific commit.
RUN dnf install -y osh-hub osh-hub-conf-devel openssl krb5-workstation

# TODO: Shall `/var/log/osh/` be a persistennt path? Shall this log be redirected to another logging
# service like splunk?
RUN touch /var/log/osh/hub/hub.log && chown :root /var/log/osh/hub/hub.log
# TODO: Shall this should be copied through ansible?
RUN touch /usr/lib/python3.9/site-packages/osh/hub/settings_local.py && chown :root /usr/lib/python3.9/site-packages/osh/hub/settings_local.py
# TODO: Shall this should be copied through ansible?
RUN touch /etc/httpd/conf.d/osh-hub-httpd.conf && chown :root /etc/httpd/conf.d/osh-hub-httpd.conf
# TODO: Set correct permissions on below files.
RUN chown :root /usr/lib/python3.9/site-packages/osh/hub/settings_local.py /etc/httpd/conf.d/osh-hub-httpd.conf
RUN chown -R :root /var/log/osh/hub /var/lib/osh/ /opt/app-root/ /var/run/
# TODO: Shall /var/lib/osh be a persistent path? Remove chmod command for it?
RUN chmod -R g+rw /var/log/osh/hub  /opt/app-root/ /var/run/ /usr/lib/python3.9/site-packages/osh/hub/settings_local.py /etc/httpd/conf.d/osh-hub-httpd.conf

# TODO: Disable `mod_security` in apache httpd.
# This is a temporary workaround to allow large report uploads from worker to the hub.
# This change should be revisited before moving to production.
RUN rm -f /etc/httpd/conf.d/mod_security.conf

# Run a dummy SMTP server in background
RUN python3 -m smtpd -n -c DebuggingServer localhost:8025 >> /tmp/emails.log &

EXPOSE 8080
EXPOSE 8443

# Custom `redhat.css` changes color of the header to blue.
# This should be removed when https://issues.redhat.com/browse/OSH-198 is resolved.
COPY configs/redhat.css /usr/lib/python3.9/site-packages/osh/hub/static-assets/css/redhat.css
COPY configs/redhat.css /usr/lib/python3.9/site-packages/osh/hub/static/css/redhat.css
# TODO: These files should be copied at container runtime and not build time.
# COPY configs/settings_local.ocp.py /usr/lib/python3.9/site-packages/osh/hub/settings_local.py
# COPY configs/osh-hub-httpd.conf /etc/httpd/conf.d/osh-hub-httpd.conf

COPY scripts/run_hub.sh /run_hub.sh
RUN chmod a+x /run_hub.sh
# This is for backward compatibility. Remove this?
USER 1001
CMD /run_hub.sh
