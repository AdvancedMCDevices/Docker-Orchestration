#!/bin/bash
set -e

echo "Copying secrets..."

sed -i "s/\${VELOCITY_SECRET}/$VELOCITY_SECRET/g" /FabricProxy-Lite.toml

echo "Checking for missing server files..."

# Use 'cp -n' to copy ONLY if the file doesn't exist in the volume
# Or use 'cp -u' to copy only if the source is newer than the destination
cp -a /usr/src/init_data/mods /data
cp -a /usr/src/init_data/config /data
cp -a /usr/src/init_data/server.properties /data/server.properties

echo "Initialization complete. Starting server..."

# This executes the CMD from your Dockerfile
exec "/image/scripts/start"