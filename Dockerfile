# syntax=docker/dockerfile:1

FROM node:20-alpine AS builder

WORKDIR /app

# Copy and build shared package first
COPY shared ./shared
WORKDIR /app/shared
RUN npm install && npm run build

# Install server dependencies
WORKDIR /app/server
COPY server/package*.json ./
RUN npm ci

# Copy server source code
COPY server/ .

# Build the application
RUN npm run build

# Runtime image
FROM node:20-alpine

WORKDIR /app

# Install PostgreSQL client for migrations
RUN apk add --no-cache postgresql-client

# Copy built application and dependencies
COPY server/package*.json ./
COPY server/GeoLite2-City.mmdb ./GeoLite2-City.mmdb
COPY server/dist ./dist
COPY --from=builder /app/server/node_modules ./node_modules
COPY server/docker-entrypoint.sh /docker-entrypoint.sh
COPY server/drizzle.config.ts ./drizzle.config.ts
COPY server/public ./public
COPY server/src ./src
COPY shared ./shared

# Make the entrypoint executable
RUN chmod +x /docker-entrypoint.sh

# Expose the API port
EXPOSE 3001

# Use our custom entrypoint script
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["node", "dist/index.js"]
