# Couchbase Cluster via docker-compose

This is a sample Couchbase cluster created using docker-compose.  It initializes the cluster and creates a bucket, bypassing the UI setup steps.

See the docker-compose.yml for the cluster settings via the environment.  Available settings (withy default value) are:

* COUCHBASE_HOSTS (couchbase1) - you should list as a comma-separated list of the container names
* COUCHBASE_PORT (8091)
* COUCHBASE_BUCKET (default)
* USER (couchbase)
* PASSWORD (couchbase)
* CLUSTER_RAMSIZE (512)
* BUCKET_RAMSIZE (100)
* BUCKET_REPLICAS (1)
* BUCKET_TYPE (couchbase)
