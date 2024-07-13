- import files into play-with-docker after creating them:
    mkdir etcd-stack
    cd etcd-stack
    touch start-etcd.sh
    touch example.env
    touch docker-compose.yml
- create network:
    docker network create --scope=swarm --driver=overlay --attachable etcd_area_lan
- add labels to nodes:
    docker node update --label-add etcd=true manager2
    docker node update --label-add etcd=true manager3
    docker node update --label-add etcd=true manager4
- fix .sh EOL issues with command:
    sed 's/\x0D$//' start-etcd.sh
- use docker stack deploy with command:
    export $(grep -v '^#' example.env | xargs) && docker stack deploy -c docker-compose-dev.yml etcd-cluster
