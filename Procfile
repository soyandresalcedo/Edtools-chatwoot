# Procfile optimizado para Railway deployment
# Simplificado para evitar problemas de timeout y compatibilidad

web: bundle exec rails server -p $PORT -e $RAILS_ENV
worker: bundle exec sidekiq -C config/sidekiq.yml
