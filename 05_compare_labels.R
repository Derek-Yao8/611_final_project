#!/usr/bin/env Rscript

source("/home/rstudio/work/common_packages.R")

dir.create("tables", showWarnings = FALSE)

lol    <- read.csv("data/lol_base_stats_clean.csv")
km_fit <- readRDS("results/kmeans_fit.rds")

clusters_km <- km_fit$cluster

meta <- lol %>%
  mutate(cluster_km = clusters_km)

results_list <- list()

## Compare to Role
if ("role" %in% names(meta)) {
  
  # Keep only champions with non-missing role
  idx_role <- !is.na(meta$role)
  
  if (any(idx_role)) {
    tab_role <- table(meta$role[idx_role], meta$cluster_km[idx_role])
    
    ari_role <- adjustedRandIndex(
      meta$cluster_km[idx_role],
      meta$role[idx_role]
    )
    
    nmi_role <- NMI(
      meta$cluster_km[idx_role],
      meta$role[idx_role]
    )
    
    results_list[["role"]] <- data.frame(
      label_type = "role",
      ari        = ari_role,
      nmi        = nmi_role
    )
    
    write.csv(as.data.frame(tab_role),
              "tables/confusion_role_kmeans.csv",
              row.names = FALSE)
  } else {
    warning("All roles are NA; skipping role-based evaluation.")
  }
}


if (length(results_list) > 0) {
  label_agreement <- bind_rows(results_list)
  write.csv(label_agreement, "tables/label_agreement_kmeans.csv", row.names = FALSE)
}


