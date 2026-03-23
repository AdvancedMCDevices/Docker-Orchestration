# Docker-Orchestration

Docker Compose deployment for Illini Redstone Computing services, including web apps, PostgreSQL, Velocity, Minecraft servers, and automated volume backups.

## What This Repository Deploys

This stack is defined in [compose.yml](compose.yml) and currently includes:

- `volume_init`: Initializes shared volume subdirectories and permissions
- `backup`: Daily volume backup container (offen/docker-volume-backup)
- `postgres`: PostgreSQL database
- `backend`: NestJS API
- `admin-panel`: SvelteKit admin web app
- `filebrowser`: Web file manager for shared volume data
- `velocity`: Minecraft proxy
- Minecraft servers: `lobby`, `survival`, `onboarding`, `mchprs`, `project-0`

## Prerequisites

- Docker Engine 24+
- Docker Compose plugin v2+
- 8 GB+ RAM recommended (Minecraft + proxy + web services)
- Open host ports as needed:
  - `25565` (Velocity / Minecraft entrypoint)
  - `5000` (Admin panel, default)
  - `8080` (Filebrowser, default)
  - `3000` (Backend API, default)

## Deployment

### 1. Clone and fetch submodules

```bash
git clone https://github.com/IlliniRedstoneComputing/Docker-Orchestration.git
git submodule update --init --recursive
cd Docker-Orchestration
```

### 2. Create configuration files

Create `.env` in the repository root:

```env
# Required
VELOCITY_SECRET=replace-with-a-long-random-string

# Strongly recommended overrides
POSTGRES_USER=postgres
POSTGRES_PASSWORD=replace-with-a-strong-password
POSTGRES_DB=postgres
API_SECRET=replace-with-a-long-random-string

# Optional port overrides
BACKEND_PORT=3000
ADMIN_PANEL_PORT=5000
FILE_BROWSER_PORT=8080
VELOCITY_PORT=25565

# Optional JVM tuning for Java-based services
JAVA_OPTS=-Xmx2G -Xms1G
```

Configure backups by copying [backup.config.example](backup.config.example) to `backup.config` and filling your S3-compatible settings:

```bash
cp backup.config.example backup.config
```

PowerShell equivalent:

```powershell
Copy-Item backup.config.example backup.config
```

Minimum values to set in `backup.config` for remote backups:

- `AWS_S3_BUCKET_NAME`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_ENDPOINT` (if not AWS S3)
- `BACKUP_RETENTION_DAYS`

### 3. Build and start

```bash
docker compose pull
docker compose build
docker compose up -d
```

### 4. Verify deployment

```bash
docker compose ps
docker compose logs -f --tail=100
```

## Usage

### Access points (default ports)

- Admin panel: `http://localhost:5000`
- Filebrowser: `http://localhost:8080`
- Backend API: `http://localhost:3000`
- Minecraft entrypoint (Velocity): `<host>:25565`

### Day-to-day operations

Start all services:

```bash
docker compose up -d
```

Stop services (keep data volumes):

```bash
docker compose down
```

Restart one service:

```bash
docker compose restart backend
```

View logs for one service:

```bash
docker compose logs -f backend
```

Open a shell in a container:

```bash
docker compose exec backend sh
docker compose exec postgres sh
```

Database shell:

```bash
docker compose exec postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
```

## Backups

The `backup` service is configured by [backup.config](backup.config) and uses offen/docker-volume-backup.

Behavior in this stack:

- Backs up selected `managed-files` subpaths (`survival`, `project-0`)
- Can upload to S3-compatible storage
- Stops labeled containers during backup for consistency

Useful commands:

```bash
# Check backup container logs
docker compose logs -f backup

# Run backup service manually (if needed)
docker compose run --rm backup
```

## Persistence

Persistent volumes:

- `managed-files`: Minecraft/Velocity/file data
- `postgres-data`: PostgreSQL data
- `filebrowser-db`: Filebrowser metadata

Full reset (destructive):

```bash
docker compose down -v
```

## Extending The Stack

### Add a new Minecraft server

1. Create `src/<server-name>/` with a Dockerfile and entrypoint.
2. Add service in [compose.yml](compose.yml) under the Minecraft block.
3. Mount `managed-files` with `volume.subpath` for that server.
4. Add `VELOCITY_SECRET` and `JAVA_OPTS` environment variables.
5. Add dependency on `volume_init` and (usually) `velocity`.

### Update PostgreSQL initialization

- Put SQL files in [src/postgres/docker-entrypoint-initdb.d/init.sql](src/postgres/docker-entrypoint-initdb.d/init.sql) or add new `.sql` files in that directory.
- Recreate database volume if you need init scripts to run again.

## Troubleshooting

Service failed to start:

```bash
docker compose logs <service-name>
```

Health/dependency issues:

```bash
docker compose ps
```

Rebuild from scratch:

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

Network check from backend to postgres:

```bash
docker compose exec backend sh -lc "ping -c 2 postgres"
```

## Security Notes

- Do not commit real secrets in `.env` or `backup.config`.
- Rotate `VELOCITY_SECRET`, `API_SECRET`, and database credentials before production.
- Restrict access to host ports via firewall/security group rules.
- Treat `managed-files` and backup artifacts as sensitive data.

## Repository Layout

Key paths:

- [compose.yml](compose.yml): main orchestration file
- [backup.config.example](backup.config.example): backup configuration template
- [src/admin-panel](src/admin-panel): SvelteKit app
- [src/backend](src/backend): NestJS API
- [src/filebrowser](src/filebrowser): filebrowser image setup
- [src/postgres](src/postgres): PostgreSQL image + init scripts
- [src/velocity](src/velocity): Velocity proxy image + config
- [src/lobby](src/lobby), [src/survival](src/survival), [src/onboarding](src/onboarding), [src/mchprs](src/mchprs), [src/project-0](src/project-0): Minecraft server containers

## Contributing

1. Create a branch from `main`.
2. Make and test changes locally with `docker compose up -d --build`.
3. Open a pull request describing purpose, risk, and rollback plan.

## License

MIT. See [LICENSE](LICENSE).
