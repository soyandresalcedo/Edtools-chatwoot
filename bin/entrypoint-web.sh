#!/bin/sh
set -e

echo "=== Chatwoot Railway Entrypoint ==="

# CRITICAL: Generate secrets FIRST, before any Rails commands
if [ -z "$SECRET_KEY_BASE" ]; then
  echo "=== Generando SECRET_KEY_BASE ==="
  export SECRET_KEY_BASE=$(openssl rand -hex 64)
fi

if [ -z "$DEVISE_JWT_SECRET_KEY" ]; then
  echo "=== Generando DEVISE_JWT_SECRET_KEY ==="
  export DEVISE_JWT_SECRET_KEY=$(openssl rand -hex 64)
fi

# Now Rails commands can run safely
echo "=== Ejecutando migraciones ==="
bundle exec rails db:migrate

# Setup IP lookup (optional, can fail gracefully)
echo "=== Configurando GeoIP ==="
bundle exec rails ip_lookup:setup || echo "GeoIP setup failed, continuing..."

echo "=== Iniciando servidor Rails ==="
exec bundle exec rails server -p "${PORT}" -e "${RAILS_ENV}"