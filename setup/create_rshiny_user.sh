#!/bin/bash
set -e

# Create rshiny user and group
# This script sets up the rshiny user with UID/GID 1000
# which is expected by Lifebit infrastructure

echo "=========================================="
echo "Setting up rshiny user and group"
echo "=========================================="

# ==========================================
# User and Group Setup
# ==========================================
# Lifebit infrastructure expects rshiny user/group to have UID/GID 1000
# Ubuntu 24.04 base image may have ubuntu user with UID/GID 1000
# We need to reassign ubuntu user/group to UID/GID 3000 to free up 1000

echo "Setting up rshiny user and group with UID/GID 1000..."

# Check if GID 1000 exists and reassign it if it's not rshiny
if getent group 1000 > /dev/null 2>&1; then
    EXISTING_GROUP=$(getent group 1000 | cut -d: -f1)
    if [ "$EXISTING_GROUP" != "rshiny" ]; then
        echo "Reassigning group '$EXISTING_GROUP' from GID 1000 to GID 3000..."
        groupmod -g 3000 "$EXISTING_GROUP" 2>/dev/null || true
    fi
fi

# Check if UID 1000 exists and reassign it if it's not rshiny
if id 1000 > /dev/null 2>&1; then
    EXISTING_USER=$(id -un 1000)
    if [ "$EXISTING_USER" != "rshiny" ]; then
        echo "Reassigning user '$EXISTING_USER' from UID 1000 to UID 3000..."
        usermod -u 3000 "$EXISTING_USER" 2>/dev/null || true
        # Update ownership of home directory
        if [ -d "/home/$EXISTING_USER" ]; then
            chown -R 3000:3000 "/home/$EXISTING_USER" 2>/dev/null || true
        fi
    fi
fi

# Create rshiny group with GID 1000
if ! getent group rshiny > /dev/null 2>&1; then
    echo "Creating rshiny group with GID 1000..."
    groupadd -g 1000 rshiny
fi

# Create rshiny user with UID 1000
if ! id -u rshiny > /dev/null 2>&1; then
    echo "Creating rshiny user with UID 1000..."
    useradd -m -s /bin/bash -u 1000 -g 1000 rshiny
    echo "rshiny:rshiny" | chpasswd

    # Add rshiny user to staff group for library access
    usermod -a -G staff rshiny
fi

# ==========================================
# Set up home directory structure
# ==========================================
RSHINY_HOME="/home/rshiny"

echo "Setting up home directory at ${RSHINY_HOME}..."

# Create standard directories
mkdir -p "${RSHINY_HOME}/.local/share"
mkdir -p "${RSHINY_HOME}/.cache"
mkdir -p "${RSHINY_HOME}/.config"

# Set ownership of home directory
chown -R rshiny:rshiny "${RSHINY_HOME}"

# ==========================================
# Set permissions for R libraries
# ==========================================
echo "Setting R library permissions for rshiny user..."

# Give rshiny user write access to R library directories
if [ -d /opt/R ]; then
    # Create user-writable library directory
    for R_DIR in /opt/R/*/lib/R/library; do
        if [ -d "$R_DIR" ]; then
            chmod -R g+w "$R_DIR" 2>/dev/null || true
            chgrp -R rshiny "$R_DIR" 2>/dev/null || true
        fi
    done
fi

echo "=========================================="
echo "rshiny user setup complete!"
echo "  User: rshiny (UID 1000)"
echo "  Group: rshiny (GID 1000)"
echo "  Home: ${RSHINY_HOME}"
echo "=========================================="
