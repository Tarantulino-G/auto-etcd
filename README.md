# auto-etcd
a (poor) attempt at making a self-operating etcd cluster in docker swarm

# ATTRIBUTION
https://github.com/YouMightNotNeedKubernetes/etcd
Most code is taken from this repo, I'm just trying to bend etcd into not having to actively manage it.
The organization has been recently archived and it's being migrate to https://github.com/swarmlibs .

# WARNING(s)
- still under initial development, started the repo to have an easier time testing it on play-with-docker
- not fit for production unless you know what you're doing
- it's completely ignoring what happens when the etcd cluster grows in size of data, it's meant to be kept small for the specific use case

# Goals of the project
- single command startup
- no commands to run against the etcd API to manage membership
- should be a 1-to-1 mirror of which nodes are labeled to run the etcd cluster
- resilient to node failure
- shouldn't care on which nodes it is actually running
- error cases when joining cluster should be handled automatically
