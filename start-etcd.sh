#!/bin/sh

# Environment variables
ETCD_DATA_DIR=${ETCD_DATA_DIR:-/etcd-data}
ETCD_INITIAL_CLUSTER_STATE=${ETCD_INITIAL_CLUSTER_STATE:-new}
ETCDCTL_API=3

# Set environment variables for etcdctl
export ETCDCTL_ENDPOINTS=${ETCD_ADVERTISE_CLIENT_URLS}

# Function to check if the node has existing data
has_data() {
    [ "$(ls -A $ETCD_DATA_DIR)" ]
}

# Function to check if the node can start with the existing data
is_node_healthy() {
    # Preserve original values
    OLD_ETCD_DATA_DIR=$ETCD_DATA_DIR
    OLD_ETCD_NAME=$ETCD_NAME
    OLD_ETCD_LISTEN_CLIENT_URLS=$ETCD_LISTEN_CLIENT_URLS
    OLD_ETCD_ADVERTISE_CLIENT_URLS=$ETCD_ADVERTISE_CLIENT_URLS

    # Set environment variables for the etcd process
    export ETCD_DATA_DIR=$ETCD_DATA_DIR
    export ETCD_NAME=$ETCD_NAME
    export ETCD_LISTEN_CLIENT_URLS=$ETCD_LISTEN_CLIENT_URLS
    export ETCD_ADVERTISE_CLIENT_URLS=$ETCD_ADVERTISE_CLIENT_URLS

    # Start etcd without additional options
    etcd &
    ETCD_PID=$!
    sleep 5
    HEALTHY=$(etcdctl endpoint health)
    kill $ETCD_PID
    
    # Reset environment variables to their original values
    export ETCD_DATA_DIR=$OLD_ETCD_DATA_DIR
    export ETCD_NAME=$OLD_ETCD_NAME
    export ETCD_LISTEN_CLIENT_URLS=$OLD_ETCD_LISTEN_CLIENT_URLS
    export ETCD_ADVERTISE_CLIENT_URLS=$OLD_ETCD_ADVERTISE_CLIENT_URLS

    if echo $HEALTHY | grep -q "is healthy"; then
        return 0
    else
        return 1
    fi
}

# Function to reset the node's membership
reset_membership() {
    # Ask the cluster for the list of members
    MEMBERS=$(etcdctl member list)
    
    # Check if the starting node is registered as a member
    if echo "$MEMBERS" | grep -q "$ETCD_NAME"; then
        # Remove itself from cluster membership
        MEMBER_ID=$(echo "$MEMBERS" | grep "$ETCD_NAME" | cut -d',' -f1)
        etcdctl member remove $MEMBER_ID
    fi
    
    # Add itself to cluster membership as a new node
    etcdctl member add $ETCD_NAME --peer-urls=${ETCD_INITIAL_ADVERTISE_PEER_URLS}
    
    # Wipe the data folder
    rm -rf $ETCD_DATA_DIR/*
    
    # Remove the values related to the starting node from ETCD_INITIAL_ADVERTISE_PEER_URLS
    ETCD_INITIAL_CLUSTER=$(echo $ETCD_INITIAL_CLUSTER | sed -e "s|etcd-${ETCD_NAME}=http://etcd-${ETCD_NAME}:2380,||" -e "s|,etcd-${ETCD_NAME}=http://etcd-${ETCD_NAME}:2380||" -e "s|etcd-${ETCD_NAME}=http://etcd-${ETCD_NAME}:2380||")
    
    # Export the modified initial cluster
    export ETCD_INITIAL_CLUSTER=$ETCD_INITIAL_CLUSTER
    
    # Start the etcd process
    exec /usr/local/bin/etcd
}

# Main logic
if [ "$ETCD_INITIAL_CLUSTER_STATE" = "new" ]; then
    # If the cluster state is new, just run the default startup command
    exec /usr/local/bin/etcd
else
    if has_data && is_node_healthy; then
        # Start etcd with existing data if the node is healthy
        exec /usr/local/bin/etcd
    else
        # Reset membership and start etcd
        reset_membership
    fi
fi
