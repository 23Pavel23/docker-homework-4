# docker-homework-4

Frontend (nginx) + backend (python). Вариант 4, порт 8004.

Нужен только Docker (делал на Docker Desktop под Windows, скрипты запускал через bash из Git). Docker Compose не используется.

## Запуск

```
bash scripts/start.sh
```

Скрипт создаёт сеть и volume, если их нет, собирает оба образа, кладёт в volume fact.txt (если его там ещё нет) и запускает контейнеры. В конце ждёт healthy. Повторный запуск ничего не ломает.

Открыть: http://localhost:8004/

## Проверка

```
curl http://localhost:8004/
curl http://localhost:8004/api
docker ps
docker network inspect docker-homework-4
docker stats --no-stream
```

Или всё сразу, вывод пишется в checks.txt:

```
bash scripts/collect.sh
```

## Пересоздать только backend

```
bash scripts/start.sh backend
```

## Поломка по варианту (volume не по тому пути)

```
DATA_MOUNT=/app/data bash scripts/start.sh backend
```

Починить: `bash scripts/start.sh backend`

## Остановка

```
bash scripts/stop.sh           # контейнеры удаляются, volume остаётся
bash scripts/stop.sh --purge   # ещё сеть и volume
```