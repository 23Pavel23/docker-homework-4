#!/bin/bash
set -e
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
source project.env
MOUNT=${DATA_MOUNT:-/data}

run_backend() {
    docker rm -f "$BACKEND_CONTAINER" >/dev/null 2>&1 || true
    docker run -d --name "$BACKEND_CONTAINER" --hostname "$BACKEND_CONTAINER" \
        --network "$NETWORK" --network-alias "$BACKEND_ALIAS" \
        -v "$VOLUME:$MOUNT" \
        -e STUDENT_NAME="$STUDENT_NAME" -e VARIANT="$N" -e PERSONAL_ID="$PERSONAL_ID" \
        --cpus 0.5 --memory 128m --restart unless-stopped \
        "$BACKEND_IMAGE"
}

run_frontend() {
    docker rm -f "$FRONTEND_CONTAINER" >/dev/null 2>&1 || true
    docker run -d --name "$FRONTEND_CONTAINER" \
        --network "$NETWORK" -p "$HOST_PORT:80" \
        --cpus 0.25 --memory 64m --restart unless-stopped \
        "$FRONTEND_IMAGE"
}

wait_health() {
    echo -n "waiting for $1 healthcheck"
    for i in $(seq 1 45); do
        status=$(docker inspect -f '{{.State.Health.Status}}' "$1")
        if [ "$status" = "healthy" ] || [ "$status" = "unhealthy" ]; then
            break
        fi
        echo -n "."
        sleep 1
    done
    echo " $status"
}

if [ "$1" = "backend" ]; then
    run_backend
    wait_health "$BACKEND_CONTAINER"
    exit 0
fi

# network and volume
docker network inspect "$NETWORK" >/dev/null 2>&1 || docker network create "$NETWORK"
docker volume inspect "$VOLUME" >/dev/null 2>&1 || docker volume create "$VOLUME"

# images
docker build -f backend/Dockerfile -t "$BACKEND_IMAGE" .
docker build -f frontend/Dockerfile -t "$FRONTEND_IMAGE" .

# create file in volume if it does not exist
docker run --rm -u 0 -v "$VOLUME:/data" "$BACKEND_IMAGE" \
    sh -c '[ -f /data/fact.txt ] || echo "Light from the Sun reaches Earth in about 8 minutes" > /data/fact.txt'

run_backend
run_frontend
wait_health "$BACKEND_CONTAINER"
wait_health "$FRONTEND_CONTAINER"

echo "open http://localhost:$HOST_PORT/"