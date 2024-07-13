#!/bin/sh

# Set environment variables
ETCD_DATA_DIR="${ETCD_DATA_DIR:-/etcd-data}"
ETCDCTL_API=3
ETCDCTL="${ETCDCTL:-/usr/local/bin/etcdctl}"
ETCD_INITIAL_CLUSTER_STATE="${ETCD_INITIAL_CLUSTER_STATE:-existing}"
ETCD_NAME="${ETCD_NAME:?ETCD_NAME env is not set}"
ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER:?ETCD_INITIAL_CLUSTER env is not set}"
ETCD_LISTEN_CLIENT_URLS="${ETCD_LISTEN_CLIENT_URLS:-http://0.0.0.0:2379}"
ETCD_LISTEN_PEER_URLS="${ETCD_LISTEN_PEER_URLS:-http://0.0.0.0:2380}"
ETCD_ADVERTISE_CLIENT_URLS="${ETCD_ADVERTISE_CLIENT_URLS:-http://$ETCD_NAME:2379}"
ETCD_INITIAL_ADVERTISE_PEER_URLS="${ETCD_INITIAL_ADVERTISE_PEER_URLS:-http://$ETCD_NAME:2380}"
ETCD_INITIAL_CLUSTER_TOKEN="${ETCD_INITIAL_CLUSTER_TOKEN:-etcd-cluster}"

# Function to remove node from the cluster
remove_node() {
  MEMBER_ID="$($ETCDCTL member list | grep "$ETCD_NAME" | cut -d',' -f1)"
  if [ -n "$MEMBER_ID" ]; then
    "$ETCDCTL" member remove "$MEMBER_ID"
  fi
}

# Check if data directory exists and is not empty
if [ "$(ls -A "$ETCD_DATA_DIR" 2>/dev/null)" ]; then
  # Try to start etcd with existing data
  etcd --data-dir "$ETCD_DATA_DIR" &
  etcd_pid=$!
  sleep 5

  # Check if etcd started successfully
  if ! ps -p $etcd_pid > /dev/null; then
    # etcd failed to start, wipe the data and remove from cluster
    remove_node
    rm -rf "$ETCD_DATA_DIR"/*
    ETCD_INITIAL_CLUSTER_STATE=existing
  else
    # etcd started successfully, kill the process
    kill $etcd_pid
  fi
else
  ETCD_INITIAL_CLUSTER_STATE=new
fi

# Start etcd with the appropriate settings
exec etcd 