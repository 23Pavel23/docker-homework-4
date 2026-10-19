#!/bin/bash
cd $(dirname $0)/..
source project.env
docker rm -f $FRONTEND_CONTAINER $BACKEND_CONTAINER
# volume is kept, use --purge to delete network and volume
if [ "$1" = "--purge" ]; then
    docker network rm $NETWORK
    docker volume rm $VOLUME
fi
