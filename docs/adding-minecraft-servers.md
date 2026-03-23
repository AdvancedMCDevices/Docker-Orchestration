# Adding Minecraft Servers

This guide walks through the process of adding a new Minecraft server to the Docker Compose stack.

## Overview

Every Minecraft server in this project follows a common structure:

```
src/<server-name>/
├── Dockerfile        # Builds the server image
├── entrypoint.sh     # Injects secrets and seeds the data volume at startup
└── server/           # Initial server files (mods, configs, server.properties)
    ├── mods/
    ├── config/
    └── server.properties
```

The `compose.yml` file contains one service entry per server that:
- Builds the image from the server's directory.
- Mounts a subdirectory of the shared `managed-files` volume to `/data`.
- Passes `VELOCITY_SECRET` and `JAVA_OPTS` from the environment.
- Waits for `velocity`, `postgres`, and `volume_init` to be healthy/completed before starting.

## Step-by-Step Guide

### 1. Create the server directory

```bash
mkdir -p src/<server-name>/server/mods
mkdir -p src/<server-name>/server/config
```

Replace `<server-name>` with your chosen server identifier (e.g., `minigames`, `creative`).

### 2. Add initial server files

Place your initial server files in `src/<server-name>/server/`:

- `server.properties` — Minecraft server properties
- `mods/` — Fabric (or other loader) mod `.jar` files
- `config/` — Any mod configuration files

For a Fabric-based server that uses Velocity forwarding, you also need:
- `server/config/FabricProxy-Lite.toml` — Velocity forwarding configuration (the secret is injected at runtime)

Example minimal `server.properties`:

```properties
online-mode=false
server-port=25565
```

### 3. Create the Dockerfile

Use the existing server Dockerfiles as a template. For a standard Fabric server:

```dockerfile
FROM alpine:latest AS builder

COPY --chmod=644 ./server/config/FabricProxy-Lite.toml /FabricProxy-Lite.toml

FROM itzg/minecraft-server:latest

ENV TYPE=FABRIC
ENV EULA=TRUE
ENV ONLINE_MODE=FALSE
ENV VERSION=1.21.8

WORKDIR /usr/src/init_data
COPY ./server .
COPY --from=builder --chmod=644 ./FabricProxy-Lite.toml /config/FabricProxy-Lite.toml
RUN chown -R minecraft:minecraft . && \
    find . -type d -exec chmod 755 {} + && \
    find . -type f -exec chmod 644 {} +

WORKDIR /

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 25565

CMD ["/entrypoint.sh"]
```

Adjust `VERSION` and `TYPE` as needed. See the [itzg/minecraft-server documentation](https://docker-minecraft-server.readthedocs.io) for all supported environment variables.

### 4. Create entrypoint.sh

The entrypoint script injects the `VELOCITY_SECRET` into the proxy config and seeds the data volume with initial files:

```bash
#!/bin/bash
set -e

echo "Copying secrets..."

sed -i "s/\${VELOCITY_SECRET}/$VELOCITY_SECRET/g" /FabricProxy-Lite.toml

echo "Checking for missing server files..."

cp -a /usr/src/init_data/mods /data
cp -a /usr/src/init_data/config /data
cp -a /usr/src/init_data/server.properties /data/server.properties

echo "Initialization complete. Starting server..."

exec "/image/scripts/start"
```

Make the script executable in the repository:

```bash
chmod +x src/<server-name>/entrypoint.sh
```

> **Note for MCHPRS servers:** MCHPRS uses a different base image (`stackdoubleflow/mchprs`) and a different config file (`Config.toml`). Look at `src/mchprs/` as your template if you are adding an MCHPRS instance.

### 5. Add the subdirectory to volume_init

Open `compose.yml` and find the `volume_init` service command. Add your server's subdirectory name to the list:

```yaml
volume_init:
  command: >
    sh -c "mkdir -p /mnt/data/velocity /mnt/data/lobby /mnt/data/survival
           /mnt/data/onboarding /mnt/data/mchprs /mnt/data/project-0
           /mnt/data/<server-name> &&
        chmod -R 777 /mnt/data"
```

### 6. Add the service to compose.yml

Add a new service entry below the `# ! ALL MINECRAFT SERVERS SHOULD BE ADDED BELOW THIS LINE` comment. Use an existing server as your template:

```yaml
<server-name>:
  build:
    context: ./src/<server-name>
  container_name: <server-name>-server
  volumes:
    - type: volume
      source: managed-files
      target: /data
      volume:
        subpath: <server-name>
  environment:
    - JAVA_OPTS=${JAVA_OPTS:--Xmx2G -Xms1G}
    - VELOCITY_SECRET=${VELOCITY_SECRET:-velocitysecret}
  labels:
    - docker-volume-backup.stop-during-backup=true
  networks:
    - irc-network
  stdin_open: true
  tty: true
  restart: unless-stopped
  depends_on:
    velocity:
      condition: service_healthy
    postgres:
      condition: service_healthy
    volume_init:
      condition: service_completed_successfully
```

> **Project servers vs. standard servers:**  
> Servers intended as persistent multiplayer worlds (e.g., `survival`, `lobby`) are placed above the `# ! ALL PROJECT SERVERS SHOULD BE ADDED BELOW THIS LINE` comment. Servers that host time-limited or experimental content (e.g., `project-0`) go below it. This is a naming/organizational convention only — there is no functional difference.

### 7. Register the server in Velocity

Edit `src/velocity/server/velocity.toml` to add your server to the `[servers]` table and (optionally) to the `try` list:

```toml
[servers]
lobby = "lobby-server:25565"
survival = "survival-server:25565"
<server-name> = "<server-name>-server:25565"

[forced-hosts]

[advanced]

try = ["lobby"]
```

The hostname used here is the Docker Compose **container name** (set by `container_name:` in the service definition), not the service name.

After editing `velocity.toml`, rebuild and restart Velocity:

```bash
docker compose build velocity
docker compose restart velocity
```

### 8. Build and start the new server

```bash
docker compose build <server-name>
docker compose up -d <server-name>
```

Verify the server started successfully:

```bash
docker compose logs -f <server-name>
```

## Tips

- **Memory**: Set `JAVA_OPTS` per-server in `compose.yml` if the server needs more or less RAM than the global default.
- **Mods**: Add new mods to `src/<server-name>/server/mods/` and rebuild the image. The entrypoint will copy them into the data volume on the next startup.
- **World data**: Once the server has started for the first time, its world and configuration live in the `managed-files` volume under the `<server-name>/` subdirectory. Use the File Browser (default: http://localhost:8080) to inspect or download files.
- **Logs**: Minecraft server logs are written to the data volume at `<server-name>/logs/latest.log` and are accessible through the File Browser.
