# Start from rocker/verse (includes R, tidyverse, knitr, etc.)
FROM --platform=linux/amd64 rocker/verse:latest

# Ensure root
USER root

# Install TeX Live, Pandoc, and extra LaTeX packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    pandoc \
    && rm -rf /var/lib/apt/lists/*

# Install/upgrade R packages for rendering
RUN Rscript -e "install.packages(c('rmarkdown', 'dplyr', 'tidyverse', 'tidyr', 'ggplot2', 'cluster', 'rvest', 'janitor', 'factoextra', 'mclust', 'aricode', 'corrplot', 'broom', 'kernlab', 'stringr'), repos='https://cloud.r-project.org')"

# Default workdir
WORKDIR /home/rstudio/work
COPY . /home/rstudio/work