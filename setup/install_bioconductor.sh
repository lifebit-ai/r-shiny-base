#!/bin/bash
set -e

# Install Bioconductor for a specific R version
# This script installs BiocManager and sets up Bioconductor
# Usage: ./install_bioconductor.sh <r_version> <bioc_version>
# Example: ./install_bioconductor.sh 4.4.2 3.20

R_VERSION=${1}
BIOC_VERSION=${2}

if [ -z "$R_VERSION" ] || [ -z "$BIOC_VERSION" ]; then
    echo "Error: R version and Bioconductor version required"
    echo "Usage: $0 <r_version> <bioc_version>"
    echo "Example: $0 4.4.2 3.20"
    exit 1
fi

echo "=========================================="
echo "Installing Bioconductor ${BIOC_VERSION} for R ${R_VERSION}"
echo "=========================================="

# Path to the R installation
R_PREFIX="/opt/R/${R_VERSION}"
R_BIN="${R_PREFIX}/bin/R"

if [ ! -x "$R_BIN" ]; then
    echo "Error: R ${R_VERSION} not found at ${R_PREFIX}"
    exit 1
fi

# Install BiocManager first using P3M for faster installation
echo "Installing BiocManager from P3M (pre-compiled binary)..."
"${R_BIN}" --vanilla --slave << EOF
# Use Posit Package Manager for pre-compiled binaries
options(repos = c(CRAN = "https://p3m.dev/cran/__linux__/noble/latest"))

# Install BiocManager
install.packages("BiocManager")

# Verify installation
if (!requireNamespace("BiocManager", quietly = TRUE)) {
    stop("BiocManager installation failed")
}

cat("BiocManager version:", as.character(packageVersion("BiocManager")), "\n")
EOF

# Install and configure specific Bioconductor version using P3M binaries
echo "Configuring Bioconductor ${BIOC_VERSION} with P3M pre-compiled binaries..."
"${R_BIN}" --vanilla --slave << EOF
# Configure repositories to use P3M for both CRAN and Bioconductor
options(repos = c(
    CRAN = "https://p3m.dev/cran/__linux__/noble/latest",
    BioCsoft = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/bioc/__linux__/noble/latest",
    BioCann = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/data/annotation/__linux__/noble/latest",
    BioCexp = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/data/experiment/__linux__/noble/latest",
    BioCworkflows = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/workflows/__linux__/noble/latest",
    BioCbooks = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/books/__linux__/noble/latest"
))

cat("Using P3M Bioconductor repositories (pre-compiled binaries):\n")
print(getOption("repos"))

library(BiocManager)

# Install specific Bioconductor version
# This also installs core Bioconductor packages AS BINARIES
BiocManager::install(version = "${BIOC_VERSION}", ask = FALSE, update = TRUE)

# Verify Bioconductor version
bioc_version <- BiocManager::version()
cat("Installed Bioconductor version:", as.character(bioc_version), "\n")

if (as.character(bioc_version) != "${BIOC_VERSION}") {
    stop("Bioconductor version mismatch!")
}

# Install essential Bioconductor packages AS PRE-COMPILED BINARIES
# These are commonly used packages that should be pre-installed
cat("Installing essential Bioconductor packages (pre-compiled binaries)...\n")
BiocManager::install(c(
    "BiocGenerics",
    "BiocVersion",
    "S4Vectors",
    "IRanges",
    "GenomeInfoDb",
    "GenomicRanges",
    "Biostrings"
), ask = FALSE, update = FALSE)

cat("Bioconductor ${BIOC_VERSION} setup complete with P3M binaries!\n")
EOF

# Create a marker file indicating this Bioconductor version is installed
echo "${BIOC_VERSION}" > "${R_PREFIX}/BIOCONDUCTOR_VERSION"

# ==========================================
# Add Bioconductor config to Renviron.site
# ==========================================
RENVIRON_FILE="${R_PREFIX}/lib/R/etc/Renviron.site"

echo "Adding Bioconductor configuration to Renviron.site..."
cat >> "${RENVIRON_FILE}" << EOF

# Bioconductor version and P3M configuration
BIOCONDUCTOR_VERSION=${BIOC_VERSION}
BIOC_MIRROR=https://p3m.dev/bioconductor
EOF

# ==========================================
# Add Bioconductor repos to Rprofile.site
# ==========================================
RPROFILE_FILE="${R_PREFIX}/lib/R/etc/Rprofile.site"

echo "Adding P3M Bioconductor repositories to Rprofile.site..."
cat >> "${RPROFILE_FILE}" << EOF

# Configure P3M Bioconductor repositories
options(BioC_mirror = "https://p3m.dev/bioconductor")
options(BIOCONDUCTOR_CONFIG_FILE = "https://p3m.dev/bioconductor/config.yaml")

# Set up P3M Bioconductor repositories for version ${BIOC_VERSION}
local({
  bioc_repos <- c(
    BioCsoft = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/bioc/__linux__/noble/latest",
    BioCann = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/data/annotation/__linux__/noble/latest",
    BioCexp = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/data/experiment/__linux__/noble/latest",
    BioCworkflows = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/workflows/__linux__/noble/latest",
    BioCbooks = "https://p3m.dev/bioconductor/packages/${BIOC_VERSION}/books/__linux__/noble/latest"
  )
  r <- getOption("repos")
  r <- c(r, bioc_repos)
  options(repos = r)
})
EOF

echo "=========================================="
echo "Bioconductor ${BIOC_VERSION} installed successfully for R ${R_VERSION}!"
echo "=========================================="

# Verify installation
"${R_BIN}" --vanilla --slave -e "cat('R version:', as.character(getRversion()), '\n'); library(BiocManager); cat('Bioconductor version:', as.character(BiocManager::version()), '\n')"
