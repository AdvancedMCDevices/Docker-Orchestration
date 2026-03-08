# PostgreSQL Database Dockerfile
FROM postgres:16-alpine

# Install additional extensions (optional)
# RUN apk add --no-cache postgresql-contrib

# Copy initialization scripts
COPY docker-entrypoint-initdb.d/ /docker-entrypoint-initdb.d/

# Expose PostgreSQL port
EXPOSE 5432

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD pg_isready -U ${POSTGRES_USER:-postgres} || exit 1
