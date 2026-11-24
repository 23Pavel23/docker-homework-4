#!/bin/bash
export MSYS_NO_PATHCONV=1
cd "$(dirname "$0")/.."
source project.env
URL=http://localhost:$HOST_PORT

step() { echo; echo "===== $*"; }
code() { curl -s -o /dev/null -w "HTTP %{http_code}\n" "$1"; }

{
step "1. curl /"
code $URL/
curl -s $URL/ | grep '<h1>'

step "2. curl /api"
code $URL/api
curl -s $URL/api; echo

step "3. docker ps"
docker ps --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'

step "4. backend не опубликован"
echo "docker port backend: [$(docker port $BACKEND_CONTAINER)]"
curl -s -m 3 http://localhost:5000/ || echo "curl localhost:5000 -> exit code $?"

step "5. сеть"
docker network inspect $NETWORK -f '{{.Name}} driver={{.Driver}}{{range .Containers}}
  {{.Name}} {{.IPv4Address}}{{end}}'
docker inspect $BACKEND_CONTAINER -f "aliases backend: {{json (index .NetworkSettings.Networks \"$NETWORK\").Aliases}}"
echo -n "frontend -> http://backend:5000/health : "
docker exec $FRONTEND_CONTAINER wget -qO- http://backend:5000/health; echo

step "6. лимиты"
for c in $FRONTEND_CONTAINER $BACKEND_CONTAINER; do
    docker inspect $c -f '{{.Name}} NanoCpus={{.HostConfig.NanoCpus}} Memory={{.HostConfig.Memory}}'
done
docker stats --no-stream --format 'table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}'

step "7. healthcheck"
for c in $FRONTEND_CONTAINER $BACKEND_CONTAINER; do
    docker inspect $c -f '{{.Name}} {{.State.Health.Status}} FailingStreak={{.State.Health.FailingStreak}}'
done

step "8. volume: меняю файл"
docker exec -u 0 $BACKEND_CONTAINER sh -c 'echo "Mars has two moons" > /data/fact.txt'
curl -s $URL/api; echo
echo "backend id до: $(docker ps -q -f name=$BACKEND_CONTAINER)"

step "9. volume: удаляю и создаю заново только backend (frontend не трогаю)"
docker rm -f $BACKEND_CONTAINER
bash scripts/start.sh backend
echo "backend id после: $(docker ps -q -f name=$BACKEND_CONTAINER)"
code $URL/api
curl -s $URL/api; echo

step "10. ПОЛОМКА (N % 4 = 0): volume смонтирован в /app/data"
DATA_MOUNT=/app/data bash scripts/start.sh backend

step "11. симптом"
code $URL/api
curl -s $URL/api; echo

step "12. docker ps -a"
docker ps -a --format 'table {{.Names}}\t{{.Status}}'

step "13. docker logs backend"
docker logs --tail 4 $BACKEND_CONTAINER

step "14. гипотеза 1 - сеть / имя backend"
docker network inspect $NETWORK -f '{{range .Containers}}{{.Name}} {{end}}'
docker exec $FRONTEND_CONTAINER wget -qO- http://backend:5000/ 2>&1; echo

step "15. гипотеза 2 - файл пропал из volume"
docker run --rm -v $VOLUME:/data $BACKEND_IMAGE ls -l /data
docker run --rm -v $VOLUME:/data $BACKEND_IMAGE cat /data/fact.txt

step "16. гипотеза 3 - volume не по тому пути"
docker inspect $BACKEND_CONTAINER -f '{{range .Mounts}}{{.Name}} -> {{.Destination}}{{end}}'
echo "ls /data:"; docker exec $BACKEND_CONTAINER ls /data
echo "ls /app/data:"; docker exec $BACKEND_CONTAINER ls /app/data

step "17. docker port frontend"
docker port $FRONTEND_CONTAINER

step "18. curl -v"
curl -sv $URL/api 2>&1 | grep -E '^(> GET|< HTTP)'

step "19. ИСПРАВЛЕНИЕ: backend с правильным путём"
bash scripts/start.sh backend

step "20. повторная проверка"
code $URL/
code $URL/api
curl -s $URL/api; echo
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker inspect $BACKEND_CONTAINER -f '{{range .Mounts}}{{.Name}} -> {{.Destination}}{{end}}'
} 2>&1 | tee checks.txt

echo
echo "готово, всё в checks.txt"