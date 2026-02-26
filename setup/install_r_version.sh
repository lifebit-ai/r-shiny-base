#!/bin/bash
set -e

# Install R from Posit Pre-compiled Binaries
# This script installs a specific version of R using Posit's pre-compiled .deb packages
# Available versions: https://docs.posit.co/resources/install-r.html
# NOTE: If you need a version not available from Posit, you can fall back to source builds

R_VERSION=${1}
if [ -z "$R_VERSION" ]; then
    echo "Error: R version not specified"
    echo "Usage: $0 <version>"
    echo "Example: $0 4.4.2"
    exit 1
fi

echo "=========================================="
echo "Installing R ${R_VERSION} from Posit binaries"
echo "Architecture: $(dpkg --print-architecture)"
echo "=========================================="

# Set installation prefix - each version gets its own directory
# Posit binaries install to /opt/R/${R_VERSION}/ by default
R_PREFIX="/opt/R/${R_VERSION}"

# Download R binary from Posit CDN
echo "Downloading R ${R_VERSION} binary..."
cd /tmp
ARCH=$(dpkg --print-architecture)
curl -LO "https://cdn.posit.co/r/ubuntu-2404/pkgs/r-${R_VERSION}_1_${ARCH}.deb"

# Install the .deb package
echo "Installing R ${R_VERSION}..."
apt-get install -y "./r-${R_VERSION}_1_${ARCH}.deb"

# Clean up downloaded .deb
rm -f "r-${R_VERSION}_1_${ARCH}.deb"

# ==========================================
# Configure R Environment (Renviron.site)
# ==========================================
echo "Configuring Renviron.site..."
cat > "${R_PREFIX}/lib/R/etc/Renviron.site" << EOF
# R Environment Configuration for R ${R_VERSION}
# Generated at build time by install_r_version.sh

# P3M CRAN mirror for pre-compiled binaries
R_REPOS=https://p3m.dev/cran/__linux__/noble/latest
EOF

# ==========================================
# Configure R Profile (Rprofile.site)
# ==========================================
echo "Configuring Rprofile.site with P3M CRAN repository..."
cat > "${R_PREFIX}/lib/R/etc/Rprofile.site" << 'EOF'
# R Profile Configuration
# Generated at build time by install_r_version.sh
# Using P3M (Posit Package Manager) for pre-compiled binaries

# Set P3M CRAN mirror
local({
  r <- getOption("repos")
  r["CRAN"] <- "https://p3m.dev/cran/__linux__/noble/latest"
  options(repos = r)
})

# Optimize CPU usage
options(Ncpus = max(1, parallel::detectCores() - 1))

# Set defaults for non-interactive sessions (Shiny apps)
options(
  menu.graphics = FALSE,
  browserNLdisabled = TRUE,
  internet.info = 2,
  show.error.locations = TRUE
)
EOF

# Create a version info file
echo "${R_VERSION}" > "${R_PREFIX}/VERSION"

# Create symbolic links in /usr/local/bin for this version
echo "Creating versioned symbolic links..."
ln -sf "${R_PREFIX}/bin/R" "/usr/local/bin/R-${R_VERSION}"
ln -sf "${R_PREFIX}/bin/Rscript" "/usr/local/bin/Rscript-${R_VERSION}"

echo "=========================================="
echo "R ${R_VERSION} installed successfully!"
echo "Installation path: ${R_PREFIX}"
echo "=========================================="

# Verify installation
echo "Verifying R installation..."
"${R_PREFIX}/bin/R" --version | head -n 1

echo "Verifying Rscript installation..."
"${R_PREFIX}/bin/Rscript" --version
