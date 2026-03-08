# Docker-Orchestration

Network of containers running the bulk of AMcD services built on Docker Compose.

## IMPORTANT

**Only run this setup on a machine that already contains the built AMcD minecraft-server-image image. If you have not built this image yet, please follow ![the build instructions](https://github.com/AdvancedMCDevices/minecraft-server-image/blob/master/README.md) before proceeding.**

## Overview

This repository provides a Docker Compose framework for orchestrating AMcD services. The stack includes a PostgreSQL database built from a custom Dockerfile, an admin panel, a file browser, a placeholder API container, a Velocity proxy, and Minecraft server containers.

## Services

The following services are defined in [compose.yml](compose.yml):

### 1. PostgreSQL Database (`postgres`)

- **Custom Dockerfile**: Yes (located in `src/postgres/Dockerfile`)
- **Purpose**: Primary database service
- **Ports**: Internal only (not published to the host by default)
- **Features**:
  - Custom initialization script at `src/postgres/docker-entrypoint-initdb.d/init.sql`
  - Health checks
  - Persistent data storage (`postgres-data` volume)

### 2. Admin Panel (`admin-panel`)

- **Custom Dockerfile**: Yes (located in `src/admin-panel/dockerfile`)
- **Purpose**: SvelteKit admin UI
- **Port**: 5173 in-container, mapped to `ADMIN_PANEL_PORT` (default `5000`)
- **Notes**: Depends on `postgres` and `api` and performs an HTTP health check

### 3. File Browser (`file-browser`)

- **Custom Dockerfile**: Yes (located in `src/filebrowser/Dockerfile`)
- **Purpose**: Manage files in the shared `managed-files` volume
- **Port**: 80 in-container, mapped to `FILE_BROWSER_PORT` (default `8080`)
- **Data**: `managed-files` and `filebrowser-db` volumes

### 4. Backend/API Service (`backend`)

- **Custom Dockerfile**: Yes (located in `src/backend/Dockerfile`)
- **Purpose**: Placeholder API container waiting for your app code
- **Port**: 3000 in-container, mapped to `API_PORT` (default `8000`)
- **Notes**: The placeholder README lives in `src/api/`. If you keep the current structure, update the volume path in `compose.yml` to `./src/api` or move your API code to `./api` at the repo root.

### 5. Velocity Proxy (`velocity`)

- **Custom Dockerfile**: Yes (located in `src/velocity/Dockerfile`)
- **Purpose**: Minecraft proxy
- **Port**: 25565 in-container, mapped to `VELOCITY_PORT` (default `25565`)
- **Notes**: Requires `VELOCITY_FORWARD_SECRET` for forwarding

### 6. Minecraft Servers

- **Lobby**: `src/lobby`
- **Survival**: `src/survival`
- **MCHPRS**: `src/mchprs`

Each server uses the shared `managed-files` volume for logs/world data and expects `VELOCITY_FORWARD_SECRET`. Memory tuning is done via `JAVA_OPTS`.

## Quick Start

### Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+

### Setup

1. **Clone the repository**

   ```bash
   git clone https://github.com/AdvancedMCDevices/Docker-Orchestration.git
   cd Docker-Orchestration
   ```

2. **Configure environment variables (optional but recommended)**

   Create a `.env` file in the repo root if you want to override defaults. At minimum, set `VELOCITY_FORWARD_SECRET`.

3. **Start all services**

   ```bash
   docker compose up -d
   ```

4. **Check service status**

   ```bash
   docker compose ps
   ```

5. **View logs**
   ```bash
   docker compose logs -f
   ```

### Access Services

- **Admin Panel**: http://localhost:5000 (or your `ADMIN_PANEL_PORT`)
- **File Browser**: http://localhost:8080 (or your `FILE_BROWSER_PORT`)
- **API Service**: http://localhost:8000 (or your `API_PORT`)
- **PostgreSQL**: internal only; access via `docker compose exec postgres psql ...`

## Project Structure

```
Docker-Orchestration/
├── compose.yml                 # Main orchestration file
├── README.md                   # This documentation
├── config/                     # Example config templates
│   ├── filebrowser.json.example
│   └── mchprs.toml.example
└── src/
    ├── admin-panel/            # SvelteKit admin UI
    ├── api/                    # API placeholder README
    ├── filebrowser/            # File browser service
    ├── lobby/                  # Minecraft lobby server
    ├── mchprs/                 # MCHPRS server
    ├── postgres/               # PostgreSQL service
    ├── survival/               # Survival server
    └── velocity/               # Velocity proxy
```

## Managing Services

### Start Services

```bash
docker compose up -d
```

### Stop Services

```bash
docker compose down
```

### Rebuild a Service (custom Dockerfile)

```bash
docker compose build postgres
docker compose up -d postgres
```

### View Service Logs

```bash
# All services
docker compose logs -f

# Specific service
docker compose logs -f postgres
```

### Execute Commands in Containers

```bash
# PostgreSQL
docker compose exec postgres psql -U postgres -d amcd_db

# API (Node.js)
docker compose exec api sh

# File browser
docker compose exec file-browser sh
```

## Configuration

### Environment Variables

Create a `.env` file in the repo root to customize:

- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name
- `ADMIN_PANEL_PORT`: Admin panel port (host -> container 5173)
- `FILE_BROWSER_PORT`: File browser port (host -> container 80)
- `API_PORT`: API service port (host -> container 3000)
- `NODE_ENV`: Node.js environment (development/production)
- `VELOCITY_PORT`: Velocity proxy port
- `VELOCITY_FORWARD_SECRET`: Shared secret for proxy forwarding
- `JAVA_OPTS`: JVM options for Minecraft servers

### Adding Your Application Code

#### For the API Service

1. Place your Node.js application in the `src/api/` directory (or move it to `./api` and update the volume in `compose.yml`)
2. Update the `command` in `compose.yml` to start your application:
   ```yaml
   command: sh -c "npm install && npm start"
   ```

#### For the Admin Panel

The SvelteKit app lives in `src/admin-panel`. Use `pnpm install` and `pnpm dev` locally if you want to develop outside Docker.

## Data Persistence

Data is persisted using Docker volumes:

- `postgres-data`: PostgreSQL database files
- `managed-files`: Shared files for Minecraft servers and the file browser
- `filebrowser-db`: File browser database storage
- `velocity-logs`: Velocity proxy logs

To remove all data:

```bash
docker compose down -v
```

## Network Architecture

All services communicate through a custom bridge network (`amcd-network`), allowing:

- Service discovery by service name
- Isolated network communication
- Easy inter-service connectivity

## Health Checks

Some services include health checks:

- **PostgreSQL**: `pg_isready` command
- **Admin Panel**: HTTP check against the API container

Check health status:

```bash
docker compose ps
```

## Customization

### Adding New Minecraft Servers

To add a new Minecraft server, create a directory under `src/` and add a matching service entry in `compose.yml` below the existing server block. Use the existing server definitions as a template.

### Modifying PostgreSQL

Several services use custom Dockerfiles. To modify PostgreSQL specifically:

1. Edit `src/postgres/Dockerfile`
2. Add initialization scripts to `src/postgres/docker-entrypoint-initdb.d/`
3. Rebuild: `docker compose build postgres`

## Troubleshooting

### Services won't start

```bash
docker compose logs [service-name]
```

### Reset everything

```bash
docker compose down -v
docker compose up -d --build
```

### Check network connectivity

```bash
docker compose exec api ping postgres
```

## License

[Specify your license here]

## Contributing

[Add contribution guidelines here]
