# R36S Android Build Environment (Docker)

This Docker environment provides a complete, reproducible build system for creating Android images for the R36S game console based on LineageOS 18.1.

## Directory Structure

```
docker-build/
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Docker Compose configuration
├── build.sh               # Build script (runs inside container)
├── cache/                 # Mounted: stores .repo directory
├── results/               # Mounted: contains final ZIP files
└── README.md              # This file
```

## Prerequisites

- Docker
- Docker Compose
- At least 200GB of free disk space
- 16GB+ RAM recommended
- Fast internet connection (first build downloads ~50GB of sources)

## Quick Start

### First Build

```bash
cd docker-build
docker compose up
```

The first build will:
1. Build the Docker image (~10-15 minutes)
2. Initialize the repo and download sources (~1-2 hours depending on connection)
3. Build the Android system (~2-4 hours depending on CPU)
4. Generate the final ZIP file in `results/` directory

### Subsequent Builds

Subsequent builds are incremental and reuse:
- Cached source code in `cache/.repo/`
- Build artifacts in the container

Just run:
```bash
docker compose up -d
docker compose logs
```

Remember, this will take multiple hours (or even days on slow computers).

## Configuration

### Environment Variables

You can customize the build by setting environment variables in `docker-compose.yml` or via a `.env` file:

#### REPO_SYNC_JOBS
Number of parallel jobs for `repo sync` (default: 4)
```yaml
environment:
  - REPO_SYNC_JOBS=8
```

Or via command line:
```bash
REPO_SYNC_JOBS=8 docker compose up
```

#### BUILD_TARGET
Build variant target (default: lineage_r36s-userdebug)
```yaml
environment:
  - BUILD_TARGET=lineage_r36s-userdebug
```

### Changing Sync Jobs

To prevent throttling, the default is set to 4 parallel jobs. If you have a fast connection and want to speed up the initial sync:

```bash
REPO_SYNC_JOBS=8 docker compose up
```

## Build Output

After a successful build, you'll find the final ZIP file in:
```
docker-build/results/lineage-18.1-YYYYMMDD-HHMM-r36s-android.img.zip
```

This file can be flashed to your R36S device.

## Troubleshooting

### Out of Disk Space
The build requires significant disk space:
- Source code: ~50GB (cached in `cache/`)
- Build artifacts: ~100GB (stored in container)
- Final output: ~1GB (in `results/`)

### Out of Memory
If builds fail due to memory issues, you can:
1. Increase Docker's memory limit
2. Reduce parallel jobs: `REPO_SYNC_JOBS=2 docker compose up`

### Clean Build
To start fresh (this will re-download everything):
```bash
# Remove cached sources
rm -rf cache/.repo/*

# Remove results
rm -rf results/*

# Rebuild container
docker compose up --build
```

### Debugging
To enter the container for debugging:
```bash
docker compose run --rm r36s-builder bash
```

## Advanced Usage

### Manual Build Steps
If you want to run build steps manually:

```bash
# Start container with shell
docker compose run --rm r36s-builder bash

# Inside container, run build commands manually
repo sync -j4
source build/envsetup.sh
lunch lineage_r36s-userdebug
mka bootimage systemimage
cd device/gameconsole/r36s
./mkimg.sh
mv *.zip /build/results/
```

### Updating Sources
To update to the latest sources:
```bash
docker compose run --rm r36s-builder bash
# Inside container:
repo sync -j4
# Then exit and rebuild:
exit
docker compose up
```

## Storage Management

### Cache Directory
The `cache/` directory stores the `.repo` metadata and git objects. This prevents re-downloading sources on each build.

**Size**: ~50GB after initial sync

To preserve this between builds, never delete `cache/.repo/`.

### Results Directory
The `results/` directory contains the final flashable ZIP files.

You can safely clean old builds:
```bash
rm results/*.zip
```

## Technical Details

- **Base Image**: Ubuntu 24.04
- **LineageOS Version**: 18.1 (Android 11)
- **Device Target**: R36S game console
- **Build System**: AOSP/LineageOS build system
- **Toolchain**: GCC Linaro 6.3.1

## Support

For issues with:
- The build process: Check the Android/LineageOS documentation
- The R36S device: Visit the andr36oid GitHub repository
- This Docker setup: Review the build logs and Dockerfile

## Credits

- LineageOS Team: https://lineageos.org/
- andr36oid: https://github.com/andr36oid
