#!/bin/bash
set -e

# Enable debug output
set -x

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}R36S Android Build Environment${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}[DEBUG] Script started at $(date)${NC}"

# Set default values
REPO_SYNC_JOBS="${REPO_SYNC_JOBS:-4}"
BUILD_TARGET="${BUILD_TARGET:-lineage_r36s-userdebug}"
WORKDIR="/build"

echo -e "${BLUE}[DEBUG] REPO_SYNC_JOBS=${REPO_SYNC_JOBS}${NC}"
echo -e "${BLUE}[DEBUG] BUILD_TARGET=${BUILD_TARGET}${NC}"
echo -e "${BLUE}[DEBUG] WORKDIR=${WORKDIR}${NC}"

cd "$WORKDIR"
echo -e "${BLUE}[DEBUG] Changed to directory: $(pwd)${NC}"

# Check if .repo directory exists and is initialized
echo -e "${BLUE}[DEBUG] Checking for .repo/manifests directory...${NC}"
if [ ! -d ".repo/manifests" ]; then
    echo -e "${YELLOW}Initializing repo...${NC}"
    echo -e "${BLUE}[DEBUG] Running: repo init -u https://github.com/andr36oid/android.git -b lineage-18.1 --git-lfs${NC}"
    repo init -u https://github.com/andr36oid/android.git -b lineage-18.1 --git-lfs
    echo -e "${BLUE}[DEBUG] Repo init completed${NC}"
else
    echo -e "${GREEN}Repo already initialized, skipping...${NC}"
fi

# Always ensure local manifests are present and valid
echo -e "${BLUE}[DEBUG] Checking for .repo/local_manifests directory...${NC}"
if [ ! -d ".repo/local_manifests" ]; then
    echo -e "${YELLOW}Cloning local manifests...${NC}"
    echo -e "${BLUE}[DEBUG] Running: git clone https://github.com/andr36oid/local_manifests .repo/local_manifests${NC}"
    git clone https://github.com/andr36oid/local_manifests .repo/local_manifests
    echo -e "${BLUE}[DEBUG] Local manifests cloned${NC}"
else
    echo -e "${GREEN}Local manifests directory exists, checking contents...${NC}"
    echo -e "${BLUE}[DEBUG] Contents of .repo/local_manifests:${NC}"
    ls -la .repo/local_manifests/

    # Check if directory is empty or has no XML files
    if [ ! -f ".repo/local_manifests/local_manifests.xml" ]; then
        echo -e "${YELLOW}Local manifests directory is empty or invalid, re-cloning...${NC}"
        echo -e "${BLUE}[DEBUG] Removing broken local_manifests directory${NC}"
        rm -rf .repo/local_manifests
        echo -e "${BLUE}[DEBUG] Running: git clone https://github.com/andr36oid/local_manifests .repo/local_manifests${NC}"
        git clone https://github.com/andr36oid/local_manifests .repo/local_manifests
        echo -e "${GREEN}Local manifests re-cloned successfully${NC}"
        ls -la .repo/local_manifests/
    else
        echo -e "${GREEN}Local manifests are valid${NC}"
    fi
fi

# Upgrade repo to latest version
echo -e "${BLUE}[DEBUG] Checking for repo upgrade...${NC}"
if [ -f ".repo/repo/repo" ]; then
    echo -e "${YELLOW}Upgrading repo to latest version...${NC}"
    cp .repo/repo/repo /usr/bin/repo
    echo -e "${GREEN}Repo upgraded successfully${NC}"
    /usr/bin/repo version
fi

# Sync sources
echo -e "${YELLOW}Syncing repository (this may take a while on first run)...${NC}"
echo -e "${BLUE}[DEBUG] Starting repo sync at $(date)${NC}"
echo -e "${BLUE}[DEBUG] Running: repo sync -j${REPO_SYNC_JOBS} --verbose${NC}"
repo sync -j"${REPO_SYNC_JOBS}" --verbose
echo -e "${BLUE}[DEBUG] Repo sync completed at $(date)${NC}"

# Set up build environment
echo -e "${YELLOW}Setting up build environment...${NC}"
echo -e "${BLUE}[DEBUG] Sourcing build/envsetup.sh at $(date)${NC}"
source build/envsetup.sh
echo -e "${BLUE}[DEBUG] Build environment loaded${NC}"

# Check device tree exists
echo -e "${BLUE}[DEBUG] Checking if device tree exists...${NC}"
if [ -d "device/gameconsole/r36s" ]; then
    echo -e "${GREEN}Device tree found at device/gameconsole/r36s${NC}"
    ls -la device/gameconsole/r36s/
else
    echo -e "${RED}ERROR: Device tree not found!${NC}"
    exit 1
fi

# Select build target
echo -e "${YELLOW}Selecting build target: ${BUILD_TARGET}${NC}"
echo -e "${BLUE}[DEBUG] Running: lunch ${BUILD_TARGET}${NC}"
lunch "${BUILD_TARGET}"
echo -e "${BLUE}[DEBUG] Lunch completed successfully${NC}"

# Build boot and system images
echo -e "${YELLOW}Building bootimage and systemimage...${NC}"
echo -e "${BLUE}[DEBUG] Starting build at $(date)${NC}"
echo -e "${BLUE}[DEBUG] This will take a long time (1-3 hours)...${NC}"
mka bootimage systemimage
echo -e "${BLUE}[DEBUG] Build completed at $(date)${NC}"

# Create final image
echo -e "${YELLOW}Creating final image...${NC}"
echo -e "${BLUE}[DEBUG] Changing to device/gameconsole/r36s${NC}"
cd device/gameconsole/r36s
echo -e "${BLUE}[DEBUG] Current directory: $(pwd)${NC}"
echo -e "${BLUE}[DEBUG] Running mkimg.sh...${NC}"
./mkimg.sh
echo -e "${BLUE}[DEBUG] mkimg.sh completed${NC}"

# Move results to output directory
echo -e "${YELLOW}Moving build artifacts to results directory...${NC}"
echo -e "${BLUE}[DEBUG] Creating results directory${NC}"
mkdir -p "$WORKDIR/results"
echo -e "${BLUE}[DEBUG] Looking for ZIP files in $(pwd)${NC}"
ls -lh *.zip 2>/dev/null || echo -e "${YELLOW}No ZIP files found yet${NC}"
mv *.zip "$WORKDIR/results/" 2>/dev/null && echo -e "${GREEN}ZIP files moved successfully${NC}" || echo -e "${YELLOW}No ZIP files found to move${NC}"

cd "$WORKDIR"
echo -e "${BLUE}[DEBUG] Returned to ${WORKDIR}${NC}"

# List results
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Build completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo -e "${BLUE}[DEBUG] Build finished at $(date)${NC}"
echo -e "${GREEN}Output files:${NC}"
ls -lh "$WORKDIR/results/"*.zip 2>/dev/null || echo -e "${RED}No ZIP files found in results directory${NC}"

echo -e "${GREEN}Build artifacts are available in the 'results' directory${NC}"
