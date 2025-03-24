FROM --platform=linux/amd64 node:18.17.0

WORKDIR /app

# Install build dependencies
RUN apt-get update && \
    apt-get install -y python3 make g++ && \
    rm -rf /var/lib/apt/lists/*

# Copy package files
COPY package*.json ./

# Clean install dependencies
RUN npm cache clean --force && \
    npm install --no-package-lock --legacy-peer-deps

# Copy the rest of the application
COPY . .

# Set production environment and build
ENV NODE_ENV=production
ENV VITE_BACKEND_URL=http://backend:8000

# Build the application
RUN npm run build

# Expose port 5173 for development server
EXPOSE 5173

# Start the application
CMD ["npm", "run", "dev", "--", "--host"]
