#!/bin/bash
set -e

echo "Copying secrets..."

sed -i "s/\${VELOCITY_SECRET}/$VELOCITY_SECRET/g" /data/Config.toml

echo "Initialization complete. Starting server..."

# This executes the CMD from your Dockerfile
exec "/mchprs"