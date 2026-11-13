#!/usr/bin/env bash
set -euo pipefail

# Name of the Docker volume and container
VOLUME="open-webui"
CONTAINER="open-webui"
IMAGE="ghcr.io/open-webui/open-webui:cuda"
HOST_PORT=3000
CONTAINER_PORT=8080

# Create the Docker volume if it doesn't exist
if ! docker volume inspect "${VOLUME}" >/dev/null 2>&1; then
  echo "Creating Docker volume: ${VOLUME}"
  docker volume create "${VOLUME}"
fi

# Remove any existing container with the same name
if docker ps -a --format '{{.Names}}' | grep -qx "${CONTAINER}"; then
  echo "Removing existing container: ${CONTAINER}"
  docker rm -f "${CONTAINER}"
fi

# Run the container
echo "Starting container ${CONTAINER} from image ${IMAGE}"
docker run -d \
  -p "${HOST_PORT}:${CONTAINER_PORT}" \
  --gpus all \
  -v "${VOLUME}:/app/backend/data" \
  --name "${CONTAINER}" \
  "${IMAGE}"

echo "Open WebUI is now running at http://localhost:${HOST_PORT}"
