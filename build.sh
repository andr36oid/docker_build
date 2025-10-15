#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}R36S Android Build Environment${NC}"
echo -e "${GREEN}========================================${NC}"

# Set default values
REPO_SYNC_JOBS="${REPO_SYNC_JOBS:-4}"
BUILD_TARGET="${BUILD_TARGET:-lineage_r36s-userdebug}"
WORKDIR="/build"

cd "$WORKDIR"

# Check if .repo directory exists and is initialized
if [ ! -d ".repo/manifests" ]; then
    echo -e "${YELLOW}Initializing repo...${NC}"
    repo init -u https://github.com/andr36oid/android.git -b lineage-18.1 --git-lfs

    echo -e "${YELLOW}Cloning local manifests...${NC}"
    if [ ! -d ".repo/local_manifests" ]; then
        git clone https://github.com/andr36oid/local_manifests .repo/local_manifests
    fi
else
    echo -e "${GREEN}Repo already initialized, skipping...${NC}"
fi

# Sync sources
echo -e "${YELLOW}Syncing repository (this may take a while on first run)...${NC}"
repo sync -j"${REPO_SYNC_JOBS}"

# Set up build environment
echo -e "${YELLOW}Setting up build environment...${NC}"
source build/envsetup.sh

# Select build target
echo -e "${YELLOW}Selecting build target: ${BUILD_TARGET}${NC}"
lunch "${BUILD_TARGET}"

# Build boot and system images
echo -e "${YELLOW}Building bootimage and systemimage...${NC}"
mka bootimage systemimage

# Create final image
echo -e "${YELLOW}Creating final image...${NC}"
cd device/gameconsole/r36s
./mkimg.sh

# Move results to output directory
echo -e "${YELLOW}Moving build artifacts to results directory...${NC}"
mkdir -p "$WORKDIR/results"
mv *.zip "$WORKDIR/results/" 2>/dev/null || echo -e "${YELLOW}No ZIP files found to move${NC}"

cd "$WORKDIR"

# List results
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Output files:${NC}"
ls -lh "$WORKDIR/results/"*.zip 2>/dev/null || echo -e "${RED}No ZIP files found in results directory${NC}"

echo -e "${GREEN}Build artifacts are available in the 'results' directory${NC}"
