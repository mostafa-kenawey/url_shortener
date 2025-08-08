#!/bin/bash
# This script is the entrypoint for the Docker container.
# It ensures the database is ready and migrated before starting the app.
set -e

# Run the Elixir release task to migrate the database.
# DNS resolution is now handled in config/runtime.exs
echo "Running database migrations..."
/app/bin/url_shortener eval "UrlShortener.Release.migrate"

# Now that the DB is migrated, start the Phoenix server.
echo "Starting Phoenix server..."
exec "$@"
