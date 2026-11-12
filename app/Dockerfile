# Small official Node.js image based on Alpine Linux (~50MB)
FROM node:22-alpine

# Run in production mode (skips dev-only stuff)
ENV NODE_ENV=production

# All app files go here inside the container
WORKDIR /app

# Copy only the dependency list first (for build caching)
COPY package.json package-lock.json ./

# Install exact versions from package-lock.json
RUN npm ci --omit=dev

# Copy the app code
COPY server.js ./

# Don't run as root (security) - "node" user exists in this image
USER node

# Document the port the app listens on
EXPOSE 3000

# Docker checks /health every 10s; marks container unhealthy if it fails
HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start the app
CMD ["node", "server.js"]
