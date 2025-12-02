# R/common_packages.R
required_pkgs <- c(
  "tidyverse", "rvest", "janitor", "cluster",
  "factoextra", "mclust", "aricode", "corrplot",
  "broom", "kernlab", "stringr"
)

new_pkgs <- setdiff(required_pkgs, rownames(installed.packages()))
if (length(new_pkgs) > 0) install.packages(new_pkgs)

lapply(required_pkgs, library, character.only = TRUE)
