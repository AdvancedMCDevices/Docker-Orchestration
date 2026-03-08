#!/bin/bash
set -e

echo "Copying filebrowser config..."

cp -a /usr/src/init_data/settings.json /config/settings.json

echo "Initialization complete. Starting filebrowser..."

exec "/init"