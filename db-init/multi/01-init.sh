#!/bin/bash
set -e

echo ">>> Aplicando init.sql no banco flags_db..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /init/flags.sql

echo ">>> Criando banco targeting_db..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "CREATE DATABASE targeting_db;"

echo ">>> Aplicando init.sql no banco targeting_db..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "targeting_db" -f /init/targeting.sql

echo ">>> Init multi-banco concluído."
