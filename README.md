# R Shiny Base Image

Repository containing source code to build a Docker base image for running R Shiny applications with R and Bioconductor pre-installed.

## Supported Versions

| R Version | Bioconductor Version |
| --------- | -------------------- |
| 4.4.2     | 3.20                 |
| 4.5.2     | 3.22 (default)       |

## Quick Start

```bash
docker pull <registry>/rshiny-base:r-4.5.2_bioc-3.22
docker run -d -p 8787:8787 rshiny-base:r-4.5.2_bioc-3.22
```

Access at: <http://localhost:8787>

## Extending with Your Own App

Your Shiny app folder must contain one of these file structures:

```
my-app/
├── app.R                 # Single-file app (recommended)
```

or

```
my-app/
├── ui.R                  # UI definition (required)
├── server.R              # Server logic (required)
└── global.R              # (optional) Global variables/setup
```

Create a `Dockerfile`:

```dockerfile
FROM <registry>/rshiny-base:r-4.5.2_bioc-3.22

# (Optional) Install additional packages
RUN R -e "install.packages(c('leaflet', 'plotly'))"
RUN R -e "BiocManager::install('DESeq2')"

# Copy your Shiny app folder
COPY --chown=rshiny:rshiny ./my-app /opt/shiny-apps/myapp

# Set the app path
ENV SHINY_APP_PATH=myapp
```

Build and run:

```bash
docker build -t my-shiny-app .
docker run -d -p 8787:8787 my-shiny-app
```

## Environment Variables

| Variable         | Description                              | Default |
| ---------------- | ---------------------------------------- | ------- |
| `SHINY_APP_PATH` | App folder name inside `/opt/shiny-apps` | `demo`  |

## Building from Source

```bash
# Default (R 4.5.2 + Bioconductor 3.22)
./build.sh

# With R 4.4.2
R_VERSION=4.4.2 ./build.sh
```
