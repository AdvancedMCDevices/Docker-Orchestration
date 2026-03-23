#!/bin/bash
set -e

echo "Injecting secrets..."

sed -i "s/\${VELOCITY_SECRET}/$VELOCITY_SECRET/g" /usr/src/init_data/forwarding.secret

echo "Checking for missing server files..."

# Use 'cp -n' to copy ONLY if the file doesn't exist in the volume
# Or use 'cp -u' to copy only if the source is newer than the destination
cp -a /usr/src/init_data/plugins /server/plugins
cp -a /usr/src/init_data/velocity.toml /server/velocity.toml
cp -a /usr/src/init_data/forwarding.secret /server/forwarding.secret
cp -a /usr/src/init_data/server-icon.png /server/server-icon.png

echo "Copying complete. Starting Velocity..."

# This executes the CMD from your Dockerfile
exec "/usr/bin/run-bungeecord.sh"