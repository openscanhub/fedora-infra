#!/bin/sh -ex
#

if [[ -e /src ]]; then
    # Inside podman-compose
    pushd /src
    cp settings_local.ci.py /usr/lib/python3.9/site-packages/osh/hub/settings_local.py
    cp osh-hub-httpd.conf /etc/httpd/conf.d/osh-hub-httpd.conf
    # rm -f /etc/httpd/conf.d/ssl.conf

    for _ in $(seq 100); do
        # TODO: Put hostname of the db01 server here
        pg_isready -h fedora-osh-db && break
        sleep 0.5
    done

    popd
else
    # We are in OpenShift deployment. Copy configuration files from persistent storage.
    # Probably set the up through ansible
    # curl -o /mnt/osh-configs/osh-hub-httpd.conf https://raw.githubusercontent.com/siteshwar/openscanhub-deployment-configs/main/fedora-infra/osh-hub-httpd.conf 
    # curl -o /mnt/osh-configs/settings_local.ci.py https://raw.githubusercontent.com/siteshwar/openscanhub-deployment-configs/main/fedora-infra/settings_local.ci.py
    # cp /mnt/osh-configs/settings_local.ci.py /usr/lib/python3.9/site-packages/osh/hub/settings_local.py
    # cp /mnt/osh-configs/osh-hub-httpd.conf /etc/httpd/conf.d/osh-hub-httpd.conf
    echo "Do nothing here!"
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
        /usr/lib/python3.9/site-packages/osh/hub/{errata,scan}/fixtures/initial_data.json
fi


/usr/bin/run-httpd
# sleep inf
