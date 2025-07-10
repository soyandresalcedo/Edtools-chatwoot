#!/bin/bash
set -e

# Ejecuta las migraciones de la base de datos
bundle exec rails db:migrate

# Ejecuta la configuración de la base de datos de GeoIP
bundle exec rails ip_lookup:setup

# Finalmente, ejecuta el proceso del servidor web.
# El 'exec' es crucial. Reemplaza el proceso del script con el proceso de Puma,
# permitiendo que Puma reciba las señales del sistema correctamente.
exec bundle exec puma -C config/puma.rb -b 0.0.0.0 -p "${PORT}"