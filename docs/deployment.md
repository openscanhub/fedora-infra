// This is still a draft

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
