# General Usage

This guide covers day-to-day operation of the IRC Services Docker Compose stack.

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- The AMcD `minecraft-server-image` built on the host. See the [build instructions](https://github.com/AdvancedMCDevices/minecraft-server-image/blob/master/README.md).

## First-Time Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/IlliniRedstoneComputing/Docker-Orchestration.git
   cd Docker-Orchestration
   ```

2. **Create your environment file**

   ```bash
   cp .env.example .env
   ```

   Open `.env` and set at least the following secrets before starting the stack:

   - `POSTGRES_PASSWORD` — PostgreSQL password
   - `VELOCITY_SECRET` — Shared forwarding secret between Velocity and all Minecraft servers
   - `API_SECRET` — Secret used by the backend and admin panel

   See [Deployment Customization](deployment-customization.md) for the full list of variables.

3. **Start all services**

   ```bash
   docker compose up -d
   ```

   Docker Compose will build all custom images, initialize the shared volume structure, and start every service.

4. **Verify all services are running**

   ```bash
   docker compose ps
   ```

## Starting and Stopping Services

### Start the entire stack

```bash
docker compose up -d
```

### Stop the entire stack (preserves data)

```bash
docker compose down
```

### Stop the entire stack and remove all data volumes

> **Warning:** This permanently deletes all persistent data including the PostgreSQL database, Minecraft worlds, and file browser data.

```bash
docker compose down -v
```

### Start a single service

```bash
docker compose up -d <service-name>
```

### Stop a single service

```bash
docker compose stop <service-name>
```

### Restart a single service

```bash
docker compose restart <service-name>
```

## Accessing Services

| Service | Default URL |
|---|---|
| Admin Panel | http://localhost:5000 |
| File Browser | http://localhost:8080 |
| Backend API | http://localhost:3000 |
| Minecraft (Velocity proxy) | `localhost:25565` |
| PostgreSQL | Internal only; see [Executing Commands](#executing-commands-in-containers) |

Ports can be changed in your `.env` file — see [Deployment Customization](deployment-customization.md).

## Viewing Logs

### Stream logs for all services

```bash
docker compose logs -f
```

### Stream logs for a specific service

```bash
docker compose logs -f <service-name>
```

Valid service names are: `volume_init`, `backup`, `postgres`, `backend`, `admin-panel`, `filebrowser`, `velocity`, `lobby`, `survival`, `onboarding`, `mchprs`, `project-0`.

### Show only the last N lines

```bash
docker compose logs --tail=100 <service-name>
```

## Executing Commands in Containers

### Open a PostgreSQL shell

```bash
docker compose exec postgres psql -U ${POSTGRES_USER:-postgres} -d ${POSTGRES_DB:-irc_db}
```

### Open a shell in any service container

```bash
docker compose exec <service-name> sh
```

### Run a one-off command

```bash
docker compose exec <service-name> <command>
```

## Health Checks

The following services include automatic health checks:

| Service | Health check mechanism |
|---|---|
| `postgres` | `pg_isready` |
| `backend` | HTTP GET `http://localhost:3000` |
| `admin-panel` | HTTP GET `http://localhost:5000` |

Check current health status:

```bash
docker compose ps
```

A service will show `healthy`, `unhealthy`, or `starting` under the **Status** column.

## Troubleshooting

### A service won't start

Check the logs for error messages:

```bash
docker compose logs <service-name>
```

### Services are stuck in a dependency wait loop

Some services (e.g., `velocity`, Minecraft servers) wait for `postgres` and `backend` to become `healthy` before starting. If `postgres` or `backend` never become healthy, all downstream services will be blocked. Start by checking their logs:

```bash
docker compose logs postgres
docker compose logs backend
```

### Network connectivity between containers

```bash
docker compose exec <service-name> ping <other-service-name>
```

### Full reset (all data lost)

```bash
docker compose down -v
docker compose up -d --build
```
