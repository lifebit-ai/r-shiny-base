#!/bin/bash

# Build script for R Shiny Base Image
# This script builds the Docker image with R and Bioconductor

set -e

echo "=========================================="
echo "R Shiny Base Image Build"
echo "=========================================="

# Configuration
IMAGE_NAME="rshiny-base"

# R and Bioconductor version mapping
R_VERSION="${R_VERSION:-4.5.2}"

# Map R version to Bioconductor version
case "${R_VERSION}" in
    4.4.2) BIOC_VERSION="3.20" ;;
    4.5.2) BIOC_VERSION="3.22" ;;
    *)
        echo "ERROR: Unsupported R version ${R_VERSION}"
        echo "Supported versions: 4.4.2, 4.5.2"
        exit 1
        ;;
esac

# Generate image tag based on versions
IMAGE_TAG="r-${R_VERSION}_bioc-${BIOC_VERSION}"
FULL_IMAGE_NAME="${IMAGE_NAME}:${IMAGE_TAG}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Image: ${FULL_IMAGE_NAME}${NC}"
echo -e "${YELLOW}R Version: ${R_VERSION}${NC}"
echo -e "${YELLOW}Bioconductor Version: ${BIOC_VERSION}${NC}"
echo ""

# Confirm build
echo "This build will:"
echo "  - Use Ubuntu 24.04 as base"
echo "  - Install R ${R_VERSION} using Posit Package Manager (P3M) pre-compiled binaries"
echo "  - Install Bioconductor ${BIOC_VERSION} using Posit Package Manager (P3M) pre-compiled binaries"
echo "  - Install essential R packages using P3M pre-compiled binaries"
echo "  - Configure for running Shiny apps"
echo ""
echo "Note: Build time is approximately 10-15 minutes using P3M pre-compiled binaries."
echo ""
read -p "Continue with build? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled."
    exit 1
fi

# Start build
echo ""
echo -e "${GREEN}Starting Docker build...${NC}"
echo ""

# Build with BuildKit for better caching and output
DOCKER_BUILDKIT=1 docker build \
    --progress=plain \
    --tag "${FULL_IMAGE_NAME}" \
    --build-arg R_VERSION="${R_VERSION}" \
    --build-arg BIOC_VERSION="${BIOC_VERSION}" \
    --build-arg BUILDKIT_INLINE_CACHE=1 \
    .

# Check if build was successful
if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}=========================================="
    echo "Build completed successfully!"
    echo "==========================================${NC}"
    echo ""
    echo "Image: ${FULL_IMAGE_NAME}"
    echo "R Version: ${R_VERSION}"
    echo "Bioconductor Version: ${BIOC_VERSION}"
    echo ""
    echo "Quick start:"
    echo ""
    echo "  # Run the included demo app"
    echo "  docker run -d -p 8787:8787 ${FULL_IMAGE_NAME}"
    echo ""
    echo "  # Extend this base image for your own app:"
    echo "  # Dockerfile:"
    echo "  #   FROM ${FULL_IMAGE_NAME}"
    echo "  #   COPY ./my-shiny-app /mnt/src/myapp"
    echo "  #   ENV SHINY_APP_PATH=myapp"
    echo ""
    echo "  # Build with different R version:"
    echo "  #   R_VERSION=4.4.2 ./build.sh"
    echo ""
    echo "Access Shiny app at: http://localhost:8787"
    echo ""
else
    echo ""
    echo "Build failed! Check the output above for errors."
    exit 1
fi
