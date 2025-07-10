#!/bin/bash
set -e

# Construir DATABASE_URL manualmente desde variables individuales
export DATABASE_URL="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"

# Construir REDIS_URL manualmente desde variables individuales
export REDIS_URL="redis://:${REDISPASSWORD}@${REDISHOST}:${REDISPORT}"

echo "=== Iniciando Sidekiq Worker ==="
exec bundle exec sidekiq -C config/sidekiq.yml