# Procfile optimizado para Railway deployment
# Genera claves secretas antes de iniciar Rails

web: if [ -z "$SECRET_KEY_BASE" ]; then export SECRET_KEY_BASE=$(openssl rand -hex 64); fi && if [ -z "$DEVISE_JWT_SECRET_KEY" ]; then export DEVISE_JWT_SECRET_KEY=$(openssl rand -hex 64); fi && bundle exec rails server -p $PORT -e $RAILS_ENV
worker: bundle exec sidekiq -C config/sidekiq.yml
