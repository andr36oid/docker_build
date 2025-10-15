FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set up build environment variables
ENV USE_CCACHE=0
ENV ANDROID_JACK_VM_ARGS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4G"

# Install build dependencies
RUN apt-get update && apt-get install -y \
    bc \
    bison \
    build-essential \
    ccache \
    curl \
    flex \
    g++-multilib \
    gcc-multilib \
    git \
    git-lfs \
    gnupg \
    gperf \
    imagemagick \
    protobuf-compiler \
    python3-protobuf \
    lib32readline-dev \
    lib32z1-dev \
    libdw-dev \
    libelf-dev \
    lz4 \
    libsdl1.2-dev \
    libssl-dev \
    libxml2 \
    libxml2-utils \
    lzop \
    pngcrush \
    rsync \
    schedtool \
    squashfs-tools \
    xsltproc \
    zip \
    zlib1g-dev \
    libncurses5-dev \
    python-is-python3 \
    mtools \
    kpartx \
    repo \
    sudo \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install specific ncurses packages from Ubuntu 22.04
RUN wget -q https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libtinfo5_6.3-2_amd64.deb && \
    dpkg -i libtinfo5_6.3-2_amd64.deb && \
    rm -f libtinfo5_6.3-2_amd64.deb && \
    wget -q https://archive.ubuntu.com/ubuntu/pool/universe/n/ncurses/libncurses5_6.3-2_amd64.deb && \
    dpkg -i libncurses5_6.3-2_amd64.deb && \
    rm -f libncurses5_6.3-2_amd64.deb

# Create build user (Android builds typically shouldn't run as root)
RUN useradd -m -s /bin/bash builder && \
    echo "builder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Set up git-lfs
RUN git lfs install --system

# Clone the Linaro toolchain
RUN mkdir -p /opt/toolchains && \
    git clone --depth=1 https://github.com/andr36oid/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu \
    /opt/toolchains/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu

# Set up working directory
WORKDIR /build

# Copy the build script
COPY build.sh /usr/local/bin/build.sh
RUN chmod +x /usr/local/bin/build.sh

# Switch to builder user
USER builder

# Configure git for the builder user
RUN git config --global color.ui auto && \
    git lfs install

# Set the entrypoint
ENTRYPOINT ["/usr/local/bin/build.sh"]
