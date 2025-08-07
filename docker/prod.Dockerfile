FROM node:24.5 AS builder

WORKDIR /build

COPY . .

RUN npm ci

RUN npm run build

FROM node:24.5-alpine3.21

WORKDIR /app

COPY --from=builder /build/dist ./dist

CMD ["node", "dist/index.js"]