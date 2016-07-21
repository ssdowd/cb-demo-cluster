#!/bin/bash

# Initialize a couchbase cluster.  The comma-separated list of hosts can be
# set in $COUCHBASE_HOSTS in the docker-compose.yml file.

echo hosts ${COUCHBASE_HOSTS}

: ${COUCHBASE_HOSTS:=couchbase1}
: ${COUCHBASE_PORT:=8091}
: ${COUCHBASE_BUCKET:=default}
: ${USER:=couchbase}
: ${PASSWORD:=couchbase}
: ${CLUSTER_RAMSIZE:=512}
: ${BUCKET_RAMSIZE:=100}
: ${BUCKET_REPLICAS:=1}
: ${BUCKET_TYPE:=couchbase}

IFS=', ' read -r -a array <<< "${COUCHBASE_HOSTS}"
first_node=${array[0]}

s=1
i=0
while ! nc -w 1 $first_node $COUCHBASE_PORT 2>/dev/null
do
  i=$((i+1))
  if [ $i -gt 5 ]; then
    exit 1
  fi
  echo "Couchbase is not yet available at ${first_node}:${COUCHBASE_PORT}, sleeping $s seconds..."
  sleep $s
  s=$((s*2))
done

echo "Initializing Couchbase first node ${first_node}..."
/opt/couchbase/bin/couchbase-cli bucket-create \
  -c ${first_node}:${COUCHBASE_PORT} \
  -u ${USER} -p ${PASSWORD} \
  --bucket=${COUCHBASE_BUCKET} \
  --bucket-type=${BUCKET_TYPE} \
  --bucket-ramsize=${BUCKET_RAMSIZE} \
  --bucket-replica=${BUCKET_REPLICAS}
/opt/couchbase/bin/couchbase-cli cluster-init \
  -c ${first_node}:${COUCHBASE_PORT} \
  --cluster-init-username=${USER} --cluster-init-password=${PASSWORD} \
  --cluster-init-port=${COUCHBASE_PORT} \
  --cluster-init-ramsize=${CLUSTER_RAMSIZE}
/opt/couchbase/bin/couchbase-cli cluster-init \
  -c ${first_node}:${COUCHBASE_PORT} \
  -u ${USER} -p ${PASSWORD} \
  --cluster-init-port=${COUCHBASE_PORT} \
  --cluster-init-ramsize=${CLUSTER_RAMSIZE}

echo "Initializing couchbase cluster"
for h in "${array[@]:1}"
do
    echo "Adding $h to cluster..."
    IP=$(getent hosts ${h} | awk '{print $1}')
    s=1
    i=0
    while ! nc -w 1 $h $COUCHBASE_PORT 2>/dev/null
    do
      i=$((i+1))
      if [ $i -gt 5 ]; then
        exit 2
      fi
      echo "Couchbase is not yet available at ${h}:${COUCHBASE_PORT}, sleeping $s seconds..."
      sleep $s
      s=$((s*2))
    done
    /opt/couchbase/bin/couchbase-cli server-add \
          --cluster=${first_node}:${COUCHBASE_PORT} \
          -u ${USER} -p ${PASSWORD} \
          --server-add=${IP}:${COUCHBASE_PORT} \
          --server-add-username=${USER} \
          --server-add-password=${PASSWORD}
done

echo "Reblancing cluster"
/opt/couchbase/bin/couchbase-cli rebalance -c ${first_node}:${COUCHBASE_PORT} -u ${USER} -p ${PASSWORD}

# Disable runnability so we only run once...
chmod a-x /cbinit-entrypoint.sh

echo "Cluster ready"