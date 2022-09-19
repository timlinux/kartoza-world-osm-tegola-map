#!/bin/bash
# Get the database started
#docker-compose up -d db
TEGOLA_SQL_DEBUG=EXECUTE_SQL ./tegola --config config-postgis.toml  serve
