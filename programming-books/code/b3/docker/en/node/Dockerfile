# stage 1: the production dependencies only, from the lock file
FROM node:22-slim AS deps
WORKDIR /app
# copied before the code: this layer is rebuilt only when the dependencies change
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# stage 2: the image that runs; nothing from stage 1 except node_modules
FROM node:22-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./
COPY src ./src
# never run as root inside the container
USER node
EXPOSE 3000
# Docker asks the app itself whether it is healthy
HEALTHCHECK --interval=5s --timeout=2s \
  CMD node -e "fetch('http://localhost:3000/health').then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))"
CMD ["node", "src/server.ts"]
