# Documentation

Welcome to the IRC Services Docker Orchestration documentation. This folder contains guides for operating, customizing, and extending the stack.

## Contents

| Document | Description |
|---|---|
| [General Usage](general-usage.md) | Starting, stopping, and day-to-day management of the stack |
| [Deployment Customization](deployment-customization.md) | Environment variables, ports, volumes, networking, and backup configuration |
| [Updating](updating.md) | Updating services, base images, and the full stack |
| [Adding Minecraft Servers](adding-minecraft-servers.md) | Step-by-step guide for adding a new Minecraft server to the project |

## Quick Reference

```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# View logs for all services
docker compose logs -f

# View logs for a single service
docker compose logs -f <service-name>

# Rebuild and restart a single service
docker compose build <service-name> && docker compose up -d <service-name>
```

## Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- The custom AMcD `minecraft-server-image` image already built on the host machine. See the [build instructions](https://github.com/AdvancedMCDevices/minecraft-server-image/blob/master/README.md) if you have not done this yet.

## Project Layout

```
Docker-Orchestration/
├── compose.yml               # Main orchestration file
├── .env.example              # Environment variable template
├── backup.config.example     # Backup service configuration template
├── docs/                     # This documentation folder
│   ├── README.md
│   ├── general-usage.md
│   ├── deployment-customization.md
│   ├── updating.md
│   └── adding-minecraft-servers.md
└── src/
    ├── admin-panel/          # SvelteKit admin UI
    ├── backend/              # NestJS backend API
    ├── filebrowser/          # File Browser web UI
    ├── lobby/                # Minecraft lobby server
    ├── mchprs/               # MCHPRS redstone server
    ├── onboarding/           # Onboarding server
    ├── postgres/             # PostgreSQL database
    ├── project-0/            # Project-0 server
    ├── survival/             # Survival server
    └── velocity/             # Velocity proxy
```
