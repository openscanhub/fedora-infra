#!/bin/sh -ex
#

if [[ -e /src ]]; then
    # Inside podman-compose
    pushd /src
    cp settings_local.ci.py /usr/lib/python3.9/site-packages/osh/hub/settings_local.py
    cp osh-hub-httpd.conf /etc/httpd/conf.d/osh-hub-httpd.conf
    # rm -f /etc/httpd/conf.d/ssl.conf

    for _ in $(seq 100); do
        pg_isready -h fedora-osh-db && break
        sleep 0.5
    done

    popd
else
    # We are in the OpenShift deployment. Copy configuration files from persistent storage.
    # Probably set the up through ansible
    # curl -o /mnt/osh-configs/osh-hub-httpd.conf https://raw.githubusercontent.com/siteshwar/openscanhub-deployment-configs/main/fedora-infra/osh-hub-httpd.conf 
    # curl -o /mnt/osh-configs/settings_local.ci.py https://raw.githubusercontent.com/siteshwar/openscanhub-deployment-configs/main/fedora-infra/settings_local.ci.py
    # cp /mnt/osh-configs/settings_local.ci.py /usr/lib/python3.9/site-packages/osh/hub/settings_local.py
    # cp /mnt/osh-configs/osh-hub-httpd.conf /etc/httpd/conf.d/osh-hub-httpd.conf
    echo "We are in OpenShift. Container should be already configured through Ansible."
    # cp /etc/keytabs/service.keytab
fi


# Migrations
# If the database is empty or if it has records about already
# applied migrations, this command should work without any troubles.
/usr/lib/python3.9/site-packages/osh/hub/manage.py migrate

# If the table of mock configs is empty, we most likely have an empty database.
# In this case, we load the initial data into the database to make the OSH
# hub work.
if [ "$(/usr/lib/python3.9/site-packages/osh/hub/manage.py dumpdata scan.MockConfig)" = "[]" ]; then
    /usr/lib/python3.9/site-packages/osh/hub/manage.py loaddata \
        /usr/lib/python3.9/site-packages/osh/hub/scan/fixtures/initial_data.json
fi

if [[ -e /src ]]; then
    echo "Woker should be started by podman-compose"
else
    # We are in the OpenShift deployment.

    # TODO: https://github.com/openscanhub/fedora-infra/issues/12
    # Run a dummy SMTP server in background
    python3 -m smtpd -n -c DebuggingServer localhost:8025 &> /tmp/emails.log &

    echo "Running resalloc-agent-spawner in the background. Logs would appear in /var/log/resalloc-agent-spawner/agent-spawner.log"
    # This process is watched over by OpenShift (kubernetes) liveness probe.
    /usr/bin/resalloc-agent-spawner &
fi
/usr/bin/run-httpd
# Leave it here for debugging in the future.
# sleep inf
