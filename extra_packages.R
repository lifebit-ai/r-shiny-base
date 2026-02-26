# Install essential packages for the current R version

# Configure Posit Package Manager (P3M) for pre-compiled binaries
# This dramatically reduces build time by using binary packages instead of compiling from source
# For Ubuntu 24.04 (noble), P3M provides pre-compiled binaries for most packages
options(repos = c(
  CRAN = "https://p3m.dev/cran/__linux__/noble/latest"
))

# Verify we're using the binary repository
cat("\n=================================================\n")
cat("Using Posit Package Manager (P3M) for binaries:\n")
cat(getOption("repos")["CRAN"], "\n")
cat("=================================================\n\n")

# Core packages - tidyverse is a meta-package that installs multiple packages
# Includes: ggplot2, dplyr, tidyr, readr, purrr, tibble, stringr, forcats
cat("Installing tidyverse (pre-compiled binary)...\n")
install.packages('tidyverse')

# Core development and documentation packages
cat("Installing devtools and rmarkdown (pre-compiled binaries)...\n")
install.packages('devtools')
install.packages('littler')
install.packages('docopt')
install.packages('rmarkdown')

# Markdown is required for some RStudio features and otherwise will be downloaded on first use
# we need to pre-install it to guarantee features availability in offline environments
install.packages("markdown")

# Database backends (commonly used dependencies)
# These are installed in the official Bioconductor images to prevent
# "there is no package called 'X'" errors when loading packages
cat("Installing database backends (pre-compiled binaries)...\n")
install.packages('DBI')          # Database interface
install.packages('RSQLite')      # SQLite interface (required by many Bioc packages)
install.packages('dbplyr')       # Database backend for dplyr
install.packages('RMariaDB')     # MariaDB/MySQL interface
install.packages('RPostgres')    # PostgreSQL interface

# Additional data manipulation packages
cat("Installing data manipulation packages (pre-compiled binaries)...\n")
install.packages('vroom')        # Fast data reading
install.packages('arrow')        # Apache Arrow interface (HEAVY - but binary is much faster!)
install.packages('dtplyr')       # data.table backend for dplyr
install.packages('duckdb')       # DuckDB interface (HEAVY - but binary is much faster!)
install.packages('fst')          # Fast serialization

# Version control integration
cat("Installing version control tools (pre-compiled binaries)...\n")
install.packages('gert')         # Git integration

# Extra libraries for cloudos users
cat("Installing CloudOS libraries (pre-compiled binaries)...\n")
install.packages('ggfortify')
install.packages('DT')
install.packages('plotly')

cat("\n=================================================\n")
cat("Package installation complete!\n")
cat("=================================================\n\n")
