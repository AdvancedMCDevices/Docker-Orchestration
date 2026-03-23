# Deployment Customization

This guide explains how to configure the stack for your environment: environment variables, port bindings, volumes, networking, and backup setup.

## Environment Variables

Copy the template and edit it before starting the stack:

```bash
cp .env.example .env
```

The table below describes every variable and its default value (used when the variable is absent from `.env`).

### Database

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_USER` | `postgres` | PostgreSQL superuser name |
| `POSTGRES_PASSWORD` | `postgres` | PostgreSQL superuser password — **change this in production** |
| `POSTGRES_DB` | `irc_db` | Default database created on first start |

### API / Backend

| Variable | Default | Description |
|---|---|---|
| `API_SECRET` | `apisecret` | Shared secret between the backend and admin panel — **change this in production** |

### Velocity / Minecraft

| Variable | Default | Description |
|---|---|---|
| `VELOCITY_SECRET` | `velocitysecret` | Forwarding secret shared between Velocity and all Minecraft servers — **change this in production** |
| `JAVA_OPTS` | `-Xmx2G -Xms1G` | JVM heap and startup options applied to Velocity and every Minecraft server |

### Port Bindings

| Variable | Default | Maps to |
|---|---|---|
| `BACKEND_PORT` | `3000` | Backend API (container port 3000) |
| `ADMIN_PANEL_PORT` | `5000` | Admin panel (container port 3000) |
| `FILE_BROWSER_PORT` | `8080` | File Browser (container port 80) |
| `VELOCITY_PORT` | `25565` | Velocity Minecraft proxy (container port 25565) |

### Application

| Variable | Default | Description |
|---|---|---|
| `NODE_ENV` | `development` | Node.js environment for the admin panel and backend |

## Service-Level Configuration

### PostgreSQL

- **Initialization scripts**: Place `.sql` or `.sh` files in `src/postgres/docker-entrypoint-initdb.d/`. They run once when the database is first created.
- **Rebuild after changes**: `docker compose build postgres && docker compose up -d postgres`

### Velocity Proxy

- **Server configuration**: `src/velocity/server/velocity.toml` — edit backend server addresses and other Velocity settings here.
- **Plugins**: Add plugin `.jar` files to `src/velocity/server/plugins/`. They are copied into the volume on startup.
- The `VELOCITY_SECRET` is injected at container startup via `entrypoint.sh` using `sed`. Any change to the secret in `.env` takes effect on the next container start.

### Minecraft Servers (general)

Each Minecraft server under `src/` follows the same pattern:

- `Dockerfile` — builds the server image from `itzg/minecraft-server` (or a similar base).
- `entrypoint.sh` — injects the `VELOCITY_SECRET` into the server's proxy config file, then copies initial server files into the data volume.
- `server/` — initial server files (mods, configs, `server.properties`). These are copied into the shared `managed-files` volume on first startup.

#### Memory / JVM Options

Set `JAVA_OPTS` in your `.env` to tune heap size for all servers at once:

```dotenv
JAVA_OPTS=-Xmx4G -Xms2G
```

To configure a server independently, override the variable directly in `compose.yml` for that service:

```yaml
environment:
  - JAVA_OPTS=-Xmx8G -Xms4G
```

### File Browser

- **Settings**: `src/filebrowser/settings.json` — configure address, port, and database path.
- The web UI is accessible at the `FILE_BROWSER_PORT` and provides a browser-based view of the `managed-files` volume.

## Data Persistence (Volumes)

All persistent state is stored in named Docker volumes:

| Volume | Used by | Contents |
|---|---|---|
| `managed-files` | Velocity, all Minecraft servers, File Browser | Server world data, logs, mods, configs |
| `postgres-data` | PostgreSQL | Database files |
| `filebrowser-db` | File Browser | File Browser's own SQLite database |

### Shared `managed-files` Volume Structure

The `volume_init` service creates the following subdirectories on first run:

```
managed-files/
├── velocity/      # Velocity proxy runtime files
├── lobby/         # Lobby server data
├── survival/      # Survival server data
├── onboarding/    # Onboarding server data
├── mchprs/        # MCHPRS server data
└── project-0/     # Project-0 server data
```

When you add a new Minecraft server, add its subdirectory to the `volume_init` command in `compose.yml`. See [Adding Minecraft Servers](adding-minecraft-servers.md).

### Removing All Data

```bash
docker compose down -v
```

> **Warning:** This permanently deletes every named volume.

## Network Configuration

All services share a custom bridge network named `irc-network`. Service names act as DNS hostnames within the network (e.g., `postgres`, `backend`, `velocity`).

To change the network name, update both the `networks` block at the bottom of `compose.yml` and every `networks:` reference inside the service definitions.

## Backup Configuration

The `backup` service uses [docker-volume-backup](https://github.com/offen/docker-volume-backup) to create daily compressed archives of the `managed-files` volume.

1. Copy the template:

   ```bash
   cp backup.config.example backup.config
   ```

2. Edit `backup.config` to configure your target storage. The most commonly used options are:

   | Variable | Description |
   |---|---|
   | `AWS_S3_BUCKET_NAME` | S3 (or S3-compatible) bucket name |
   | `AWS_ACCESS_KEY_ID` | Storage access key |
   | `AWS_SECRET_ACCESS_KEY` | Storage secret key |
   | `AWS_ENDPOINT` | Custom endpoint for S3-compatible storage (e.g., MinIO, Backblaze) |
   | `BACKUP_FILENAME` | Archive filename template (supports `strftime` verbs) |
   | `BACKUP_RETENTION_DAYS` | Number of days to keep backups before pruning |
   | `BACKUP_COMPRESSION` | Compression algorithm: `gz`, `zst`, or `none` |
   | `GPG_PASSPHRASE` | Encrypt backups symmetrically with GPG |
   | `NOTIFICATION_URLS` | [Shoutrrr](https://shoutrrr.nickfedor.com) URLs for backup notifications |

3. Services labeled with `docker-volume-backup.stop-during-backup=true` (Velocity, all Minecraft servers, File Browser) are automatically stopped during the backup window and restarted afterwards to ensure data consistency.

See `backup.config.example` for the full list of options and documentation.
