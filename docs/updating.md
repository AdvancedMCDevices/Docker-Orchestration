# Updating

This guide explains how to update individual services, pull new base images, and upgrade the entire stack safely.

## Updating a Single Service

### 1. Pull the latest base image (if applicable)

If the service uses a public base image (e.g., `itzg/minecraft-server`, `postgres:16-alpine`), pull it first:

```bash
docker compose pull <service-name>
```

### 2. Rebuild the custom image

```bash
docker compose build --no-cache <service-name>
```

### 3. Restart the service

```bash
docker compose up -d <service-name>
```

Docker Compose will stop the running container, replace it with the newly built image, and start it again. Data stored in named volumes is preserved.

## Updating All Services at Once

```bash
# Pull updated base images
docker compose pull

# Rebuild all custom images
docker compose build --no-cache

# Recreate all containers with the new images
docker compose up -d
```

## Updating Server Mods or Configuration Files

Minecraft server files (mods, configs, `server.properties`) live inside the `managed-files` Docker volume and are seeded from the `src/<server>/server/` directory only when the file does not already exist in the volume. To push updated files into a running server:

1. Update the files in `src/<server>/server/`.
2. Rebuild the image:

   ```bash
   docker compose build <service-name>
   ```

3. Stop the server, remove its data subdirectory from the volume (optional — only needed if you want to fully replace existing files), then restart:

   ```bash
   docker compose stop <service-name>
   # Optional: remove existing data to force a clean seed
   docker compose run --rm <service-name> sh -c "rm -rf /data/*"
   docker compose up -d <service-name>
   ```

   > **Note:** Removing `/data` inside a container deletes the server's world and configuration. Only do this if you intend to reset the server completely.

Alternatively, use the **File Browser** web UI (default: http://localhost:8080) to edit individual files directly in the `managed-files` volume without rebuilding.

## Updating the Velocity Proxy

Velocity plugins and configuration live in `src/velocity/server/`. To update them:

1. Place new plugin `.jar` files in `src/velocity/server/plugins/` or update `velocity.toml`.
2. Rebuild the image:

   ```bash
   docker compose build velocity
   ```

3. Restart Velocity (this will briefly disconnect all connected players):

   ```bash
   docker compose restart velocity
   ```

## Updating the PostgreSQL Database

### Schema changes

Place new SQL migration scripts in `src/postgres/docker-entrypoint-initdb.d/`. These scripts are only executed on a fresh database (i.e., when `postgres-data` volume is empty). For an existing database, connect directly and run the migration:

```bash
docker compose exec postgres psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-irc_db} -f /path/to/migration.sql
```

### Upgrading the PostgreSQL major version

PostgreSQL major version upgrades (e.g., 15 → 16) require a data migration using `pg_upgrade`. **Back up your data first.**

1. Take a backup:

   ```bash
   docker compose exec postgres pg_dumpall -U ${POSTGRES_USER:-postgres} > backup.sql
   ```

2. Stop the stack and remove the old volume:

   ```bash
   docker compose down
   docker volume rm docker-orchestration_postgres-data
   ```

3. Update the base image tag in `src/postgres/Dockerfile`, then rebuild and start:

   ```bash
   docker compose build postgres
   docker compose up -d postgres
   ```

4. Restore the backup:

   ```bash
   docker compose exec -T postgres psql -U ${POSTGRES_USER:-postgres} < backup.sql
   ```

5. Start the remaining services:

   ```bash
   docker compose up -d
   ```

## Rolling Back a Service

If an update causes problems, roll back to the previous image by rebuilding from the last known-good commit:

```bash
git checkout <previous-commit-or-tag> -- src/<service-name>
docker compose build --no-cache <service-name>
docker compose up -d <service-name>
```

To roll back the entire stack:

```bash
git checkout <previous-commit-or-tag>
docker compose build --no-cache
docker compose up -d
```

## Keeping Base Images Up to Date

The following base images are used by the project. Check their release pages periodically for security updates:

| Service | Base image |
|---|---|
| `postgres` | [postgres](https://hub.docker.com/_/postgres) (currently `16-alpine`) |
| `velocity` | [itzg/mc-proxy](https://hub.docker.com/r/itzg/mc-proxy) |
| `survival`, `lobby`, `onboarding`, `project-0` | [itzg/minecraft-server](https://hub.docker.com/r/itzg/minecraft-server) |
| `mchprs` | [stackdoubleflow/mchprs](https://hub.docker.com/r/stackdoubleflow/mchprs) |
| `filebrowser` | [filebrowser/filebrowser](https://hub.docker.com/r/filebrowser/filebrowser) |
| `backup` | [offen/docker-volume-backup](https://hub.docker.com/r/offen/docker-volume-backup) |
