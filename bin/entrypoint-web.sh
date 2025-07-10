#!/bin/sh
set -e

# Debug variables
echo "PGUSER: $PGUSER"
echo "PGHOST: $PGHOST"
echo "PGPORT: $PGPORT"
echo "PGDATABASE: $PGDATABASE"

# Construir DATABASE_URL manualmente desde variables individuales
export DATABASE_URL="postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}"

# Construir REDIS_URL manualmente desde variables individuales  
export REDIS_URL="redis://:${REDISPASSWORD}@${REDISHOST}:${REDISPORT}"

echo "DATABASE_URL construida: $DATABASE_URL"

echo "=== Ejecutando migraciones ==="
bundle exec rails db:migrate

echo "=== Configurando GeoIP ==="
bundle exec rails ip_lookup:setup

echo "=== Iniciando servidor Puma ==="
exec bundle exec puma -C config/puma.rb -b 0.0.0.0 -p "${PORT}"