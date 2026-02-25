# Base Image: Ubuntu 24.04 LTS
#
# Build Strategy:
# - Stage 1 (base): System dependencies, s6-overlay (shared by all)
# - Stage 2 (r-version): R + Bioconductor + packages (version specified via ARG)
# - Stage 3 (final): Merge all stages + configuration + init scripts
#
# Supported R versions and Bioconductor mapping:
#   R 4.4.2 -> Bioconductor 3.20
#   R 4.5.2 -> Bioconductor 3.22 (default)

# Global build arguments (must be declared before FROM to be available in all stages)
ARG R_VERSION=4.5.2
ARG BIOC_VERSION=3.22

# ============================================
# STAGE 1: Base Layer (Shared Dependencies)
# ============================================
# This stage contains everything that's common to all R versions
# By sharing this, we avoid duplicating system dependencies
FROM ubuntu:24.04 AS base

LABEL maintainer="Lifebit AI"
LABEL description="RShiny app"
LABEL version="1.0"

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set s6-overlay version (v2.2.0.3 for native /etc/cont-init.d/ support)
ENV S6_VERSION=v2.2.0.3

# Set locale environment variables
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8

# ==========================================
# Install System Dependencies and s6-overlay
# ==========================================
COPY ./setup/install_system_deps.sh ./setup/create_rshiny_user.sh /tmp/
RUN chmod +x /tmp/install_system_deps.sh /tmp/create_rshiny_user.sh \
    && /tmp/install_system_deps.sh \
    && /tmp/create_rshiny_user.sh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/cache/apt/archives/*


# ============================================
# STAGE 2: Install R Version + Bioconductor
# ============================================
FROM base AS r-version

# Re-declare ARGs to inherit global values (required per Docker scoping rules)
ARG R_VERSION
ARG BIOC_VERSION

# Install R, Bioconductor, and packages (single optimized layer)
COPY ./setup/install_r_version.sh ./setup/install_bioconductor.sh /tmp/
COPY extra_packages.R /tmp/extra_packages.R
RUN chmod +x /tmp/install_r_version.sh /tmp/install_bioconductor.sh \
    && /tmp/install_r_version.sh ${R_VERSION} \
    && /tmp/install_bioconductor.sh ${R_VERSION} ${BIOC_VERSION} \
    && /opt/R/${R_VERSION}/bin/R -f /tmp/extra_packages.R \
    && rm -rf /tmp/* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# ============================================
# STAGE 3: Final Image (Merge All Stages)
# ============================================
# This stage merges all parallel stages into final image
# and adds configuration files, init scripts, etc.
FROM base AS final

# Re-declare ARG to inherit global value (required per Docker scoping rules)
ARG R_VERSION

# Set default R version as ENV (can be overridden at runtime)
ENV R_VERSION=${R_VERSION}

# ==========================================
# Copy R Installations from Parallel Stages
# ==========================================
RUN mkdir -p /opt/R

COPY --from=r-version /opt/R/${R_VERSION} /opt/R/${R_VERSION}

# Create version symlinks for convenience (optional, adjust as needed)
# These provide aliases to the installed version
RUN ln -sf /opt/R/${R_VERSION} /opt/R/default

# ==========================================
# Configure System (Combined Layer)
# ==========================================
# Set default R symlinks, create directories
RUN ln -sf /opt/R/${R_VERSION}/bin/R /usr/local/bin/R \
    && ln -sf /opt/R/${R_VERSION}/bin/Rscript /usr/local/bin/Rscript

# ==========================================
# Add Scripts and Configuration (Combined Layer)
# ==========================================
ADD ./cont-init.d /etc/cont-init.d
ADD ./services.d /etc/services.d
RUN chmod +x /etc/cont-init.d/* /etc/services.d/*/run /etc/services.d/*/finish \
    && sed -i 's/\r$//' /etc/cont-init.d/* /etc/services.d/*/run /etc/services.d/*/finish

# ==========================================
# Environment Variables
# ==========================================

# Define volume directories as ENV (available at build time and runtime)
ENV VOLUMES_DIR="/mnt"
ENV SESSION_RESULTS_DIR="/mnt/session_data"
ENV MOUNTED_DATA_DIR="/mnt/mounted-data"
ENV FILE_SYSTEMS_DIR="/mnt/file-systems"
ENV HOME="/home/rshiny"

# Create directories and persist env vars for s6-overlay v2
# s6-overlay v2 reads from /var/run/s6/container_environment/ at startup
RUN mkdir -p $SESSION_RESULTS_DIR \
    && mkdir -p $MOUNTED_DATA_DIR \
    && mkdir -p $FILE_SYSTEMS_DIR \
    && mkdir -p /mnt/src \
    && chown -R rshiny:rshiny /mnt \
    && mkdir -p /etc/cont-env \
    && echo "/mnt" > /etc/cont-env/VOLUMES_DIR \
    && echo "/mnt/session_data" > /etc/cont-env/SESSION_RESULTS_DIR \
    && echo "/mnt/mounted-data" > /etc/cont-env/MOUNTED_DATA_DIR \
    && echo "/mnt/file-systems" > /etc/cont-env/FILE_SYSTEMS_DIR \
    && echo "/home/rshiny" > /etc/cont-env/HOME

# ==========================================
# Copy Example Apps
# ==========================================
# Copy apps to /opt/shiny-apps (not affected by /mnt volume mounts)
COPY --chown=rshiny:rshiny ./apps /opt/shiny-apps

# Default app to run (can be overridden with -e SHINY_APP_PATH=other_app)
ENV SHINY_APP_PATH=demo

# ==========================================
# Expose RShiny App Port
# ==========================================
EXPOSE 8787

# ==========================================
# Entry Point
# ==========================================
# s6-overlay must start as root to manage services
# Services drop privileges to rshiny user via s6-setuidgid
WORKDIR /home/rshiny

# Use s6-overlay as init system to manage processes and run init scripts
# s6-overlay will automatically start services defined in /etc/services.d/
ENTRYPOINT ["/init"]
