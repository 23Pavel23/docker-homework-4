#!/bin/bash
export MSYS_NO_PATHCONV=1
cd $(dirname $0)/..
source project.env
MOUNT=${DATA_MOUNT:-/data}

# network and volume
docker network inspect $NETWORK >/dev/null 2>&1 || docker network create $NETWORK
docker volume inspect $VOLUME >/dev/null 2>&1 || docker volume create $VOLUME

# images
docker build -f backend/Dockerfile -t $BACKEND_IMAGE .
docker build -f frontend/Dockerfile -t $FRONTEND_IMAGE .

# create file in volume if it does not exist
docker run --rm -u 0 -v $VOLUME:/data $BACKEND_IMAGE sh -c '[ -f /data/fact.txt ] || echo "Light from the Sun reaches Earth in about 8 minutes" > /data/fact.txt'

# backend
docker rm -f $BACKEND_CONTAINER 2>/dev/null
docker run -d --name $BACKEND_CONTAINER --hostname $BACKEND_CONTAINER --network $NETWORK --network-alias $BACKEND_ALIAS -v $VOLUME:$MOUNT -e STUDENT_NAME="$STUDENT_NAME" -e VARIANT=$N -e PERSONAL_ID=$PERSONAL_ID --cpus 0.5 --memory 128m --restart unless-stopped $BACKEND_IMAGE

# frontend
docker rm -f $FRONTEND_CONTAINER 2>/dev/null
docker run -d --name $FRONTEND_CONTAINER --network $NETWORK -p $HOST_PORT:80 --cpus 0.25 --memory 64m --restart unless-stopped $FRONTEND_IMAGE

echo "open http://localhost:$HOST_PORT/"
