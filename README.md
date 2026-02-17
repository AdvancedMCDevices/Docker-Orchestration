# Docker-Orchestration

Network of containers running the bulk of AMcD services built on Docker Compose.

## Overview

This repository provides a Docker Compose framework for orchestrating multiple containerized services. The setup includes a PostgreSQL database with a custom Dockerfile, and additional services using pre-built images.

## Services

The following services are included in this orchestration:

### 1. PostgreSQL Database (`postgres`)
- **Custom Dockerfile**: Yes (located in `postgres/Dockerfile`)
- **Image**: postgres:16-alpine
- **Purpose**: Primary database service
- **Port**: 5432 (configurable via `POSTGRES_PORT`)
- **Features**:
  - Custom initialization scripts
  - Health checks
  - Persistent data storage

### 2. Web Application (`webapp`)
- **Custom Dockerfile**: No (uses pre-built nginx:alpine image)
- **Purpose**: Frontend web server
- **Port**: 8080 (configurable via `WEBAPP_PORT`)
- **Notes**: Mount your static content in `webapp/html/`

### 3. API Service (`api`)
- **Custom Dockerfile**: No (uses pre-built node:20-alpine image)
- **Purpose**: Backend API service
- **Port**: 3000 (configurable via `API_PORT`)
- **Notes**: Mount your Node.js application in `api/`

### 4. Cache Service (`cache`)
- **Custom Dockerfile**: No (uses pre-built redis:7-alpine image)
- **Purpose**: Redis cache for application data
- **Port**: 6379

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

2. **Configure environment variables**
   ```bash
   cp .env.example .env.local
   # Edit .env.local with your preferred settings
   ```

3. **Start all services**
   ```bash
   docker-compose up -d
   ```

4. **Check service status**
   ```bash
   docker-compose ps
   ```

5. **View logs**
   ```bash
   docker-compose logs -f
   ```

### Access Services

- **Web Application**: http://localhost:8080
- **API Service**: http://localhost:3000
- **PostgreSQL**: localhost:5432
- **Redis Cache**: localhost:6379

## Project Structure

```
Docker-Orchestration/
├── docker-compose.yml          # Main orchestration file
├── .env.example                # Environment variables template
├── .gitignore                  # Git ignore rules
├── postgres/                   # PostgreSQL service (ONLY service with custom Dockerfile)
│   ├── Dockerfile              # Custom PostgreSQL Dockerfile
│   └── docker-entrypoint-initdb.d/
│       └── init.sql            # Database initialization script
├── webapp/                     # Web application (uses pre-built image)
│   └── html/
│       └── index.html          # Static web content
└── api/                        # API service (uses pre-built image)
    └── README.md               # API documentation
```

## Managing Services

### Start Services
```bash
docker-compose up -d
```

### Stop Services
```bash
docker-compose down
```

### Rebuild PostgreSQL (custom Dockerfile)
```bash
docker-compose build postgres
docker-compose up -d postgres
```

### View Service Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f postgres
```

### Execute Commands in Containers
```bash
# PostgreSQL
docker-compose exec postgres psql -U postgres -d amcd_db

# API (Node.js)
docker-compose exec api sh

# Redis
docker-compose exec cache redis-cli
```

## Configuration

### Environment Variables

Edit `.env.local` (or create it from `.env.example`) to customize:

- `POSTGRES_USER`: PostgreSQL username
- `POSTGRES_PASSWORD`: PostgreSQL password
- `POSTGRES_DB`: PostgreSQL database name
- `POSTGRES_PORT`: PostgreSQL exposed port
- `WEBAPP_PORT`: Web application port
- `API_PORT`: API service port
- `NODE_ENV`: Node.js environment (development/production)

### Adding Your Application Code

#### For the API Service
1. Place your Node.js application in the `api/` directory
2. Update the `command` in `docker-compose.yml` to start your application:
   ```yaml
   command: sh -c "npm install && npm start"
   ```

#### For the Web Application
1. Place your static files in `webapp/html/`
2. The nginx server will automatically serve them

## Data Persistence

Data is persisted using Docker volumes:
- `postgres_data`: PostgreSQL database files
- `redis_data`: Redis cache data

To remove all data:
```bash
docker-compose down -v
```

## Network Architecture

All services communicate through a custom bridge network (`amcd-network`), allowing:
- Service discovery by service name
- Isolated network communication
- Easy inter-service connectivity

## Health Checks

All services include health checks:
- **PostgreSQL**: `pg_isready` command
- **Web App**: HTTP health endpoint
- **Redis**: `redis-cli ping`

Check health status:
```bash
docker-compose ps
```

## Customization

### Adding New Services

To add a new service without a custom Dockerfile:

```yaml
new-service:
  image: your-image:tag
  container_name: amcd-new-service
  restart: unless-stopped
  networks:
    - amcd-network
  depends_on:
    - postgres
```

### Modifying PostgreSQL

The PostgreSQL service is the **only** service with a custom Dockerfile. To modify:

1. Edit `postgres/Dockerfile`
2. Add initialization scripts to `postgres/docker-entrypoint-initdb.d/`
3. Rebuild: `docker-compose build postgres`

## Troubleshooting

### Services won't start
```bash
docker-compose logs [service-name]
```

### Reset everything
```bash
docker-compose down -v
docker-compose up -d --build
```

### Check network connectivity
```bash
docker-compose exec api ping postgres
```

## License

[Specify your license here]

## Contributing

[Add contribution guidelines here]
