# syntax=docker/dockerfile:1

FROM node:20-alpine AS builder

WORKDIR /app

COPY shared ./shared
WORKDIR /app/shared
RUN npm install && npm run build

WORKDIR /app/server
COPY server/package*.json ./
RUN npm ci

COPY server/ .

RUN npm run build

FROM node:20-alpine

WORKDIR /app

RUN apk add --no-cache postgresql-client

COPY --from=builder /app/server/package*.json ./
COPY --from=builder /app/server/GeoLite2-City.mmdb ./GeoLite2-City.mmdb
COPY --from=builder /app/server/dist ./dist
COPY --from=builder /app/server/node_modules ./node_modules
COPY --from=builder /app/server/docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=builder /app/server/drizzle.config.ts ./drizzle.config.ts
COPY --from=builder /app/server/public ./public
COPY --from=builder /app/shared ./shared
COPY --from=builder /app/server/src ./src


RUN chmod +x /docker-entrypoint.sh

EXPOSE 3001

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["node", "dist/index.js"]
