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

# Create required directories
echo "=== Creando directorios necesarios ==="
mkdir -p tmp/pids

# Now Rails commands can run safely
echo "=== Ejecutando migraciones ==="
bundle exec rails db:migrate

# Setup IP lookup (optional, can fail gracefully)
echo "=== Configurando GeoIP ==="
bundle exec rails ip_lookup:setup || echo "GeoIP setup failed, continuing..."

# Create admin account if not exists
echo "=== Creando cuenta admin ==="
bundle exec rails runner "
if User.where(email: 'admin@chatwoot.com').empty?
  account = Account.create!(name: 'Admin Account')
  user = User.create!(
    email: 'admin@chatwoot.com',
    password: 'password123',
    password_confirmation: 'password123',
    name: 'Admin User',
    confirmed_at: Time.current
  )
  AccountUser.create!(account: account, user: user, role: 'administrator')
  puts 'Admin account created: admin@chatwoot.com / password123'
else
  puts 'Admin account already exists'
end
"

echo "=== Iniciando servidor Puma ==="
exec bundle exec puma -C config/puma.rb