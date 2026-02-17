# API Service Placeholder

This directory is mounted into the API container. Place your Node.js application code here.

## Getting Started

1. Add your `package.json` file
2. Update the `command` in `docker-compose.yml` to run your application
3. The API service can connect to PostgreSQL using the `DATABASE_URL` environment variable

## Example Structure

```
api/
├── package.json
├── package-lock.json
├── src/
│   ├── index.js
│   └── ...
└── ...
```

## Environment Variables

The following environment variables are available:
- `NODE_ENV`: Development/production environment
- `DATABASE_URL`: PostgreSQL connection string
