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
if User.where(email: 'andres@edtools.co').empty?
  account = Account.create!(name: 'Edtools Account')
  user = User.create!(
    email: 'andres@edtools.co',
    password: 'Password123!',
    password_confirmation: 'Password123!',
    name: 'Andres Alcedo',
    confirmed_at: Time.current
  )
  AccountUser.create!(account: account, user: user, role: 'administrator')
  puts 'Admin account created: andres@edtools.co / Password123!'
else
  puts 'Admin account already exists'
end
"

echo "=== Iniciando servidor Puma ==="
exec bundle exec puma -C config/puma.rb