// This is still a draft

## Steps to deploy

These are the steps to follow to deploy on the staging environment.

- Commands are executed from the batcave server, so you need to ssh into it:
```
ssh <FAS_USERNAME>@batcave01.iad2.fedoraproject.org
```

- In the ssh session execute the `openscanhub` playbook to deploy the project:
```
sudo rbac-playbook -l staging openshift-apps/openscanhub.yml
```

- To delete the entire project and test in a clean environment:
```
sudo rbac-playbook -l staging -t delete openshift-apps/openscanhub.yml
```

Use `-l production` to deploy on the production environment. Skipping `-l` would deploy on both the
environments.


## AWS availability zones

While changing availability zones use these commands to create key pair, security groups and
subnets:

From the `resalloc-server` container:

```
aws ec2 import-key-pair --key-name "openscanhub" --public-key-material fileb://~/.ssh/id_rsa.pub
TODO: Add command to create a security group.
TODO: Add command to create a subnet.
```

## Workflow
- Commit to the `main` branch in GitHub should trigger GitHub Actions CI. 
- Spin up containers for hub, worker, client and db from the latest commit to main branch.
- Run all the required tests for the GitHub Actions CI.
- If the CI passes, do a build on quay.io and tag the images on quay.io as “staging”.
- The containers are deployed in the staging environment on the Fedora staging infrastructure. This may take a while if the django migrations take too long to apply. All the existing worker virtual machines are deleted and new ones are spun up with “staging” version of worker RPMs.
- Simulate most common scenarios from users through `osh-cli` for testing on staging. Later we should have tests for web user interface too.
- Once the staging environment passes the tests. Tag the images for `hub` and `client` as “production ready”. 
- Latest changes are deployed on the production environment by a human:
- Deploy the container images with “production ready” tag on the Openshift production cluster.
- Set `max_load` to 0 of all existing workers and delete all the workers that have 0 tasks assigned.
- Resalloc is responsible for spinning up new workers that use “production ready” RPMs.
- At this point we can say production deployment was successful, but it would only fully affect new tasks.
- Release new version of osh client if there is a breaking change with old production deployment. Possibly follow up on a heads up on fedora-devel mailing list.
