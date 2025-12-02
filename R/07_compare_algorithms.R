#!/usr/bin/env Rscript

# R/07_compare_algorithms.R

source("/home/rstudio/work/common_packages.R")

dir.create("tables", showWarnings = FALSE)


# 1. Load data and prepare numeric matrix
lol <- read.csv("data/lol_base_stats_clean.csv")

# numeric variables used for clustering
id_cols  <- c("champion", "role")
num_cols <- setdiff(names(lol), id_cols)

X_raw    <- lol %>% select(all_of(num_cols))
X_scaled <- scale(X_raw) %>% as.matrix()

n <- nrow(X_scaled)

# Load chosen k (from 03_choose_k.R)
k <- as.integer(readLines("results/selected_k.txt"))


# 2. Fit multiple clustering algorithms
clusterings <- list()

## --- K-means ------------------------------------------------------
set.seed(2034)
km_fit <- kmeans(X_scaled, centers = k, nstart = 50)
clusterings[["kmeans"]] <- km_fit$cluster

## --- Hierarchical clustering (Ward.D2) ----------------------------
d <- dist(X_scaled)
hc_fit <- hclust(d, method = "ward.D2")
clusterings[["hierarchical"]] <- cutree(hc_fit, k = k)

## --- Gaussian Mixture Model (optional if mclust installed) --------
if (requireNamespace("mclust", quietly = TRUE)) {
  gmm_fit <- mclust::Mclust(X_scaled, G = k)
  clusterings[["gmm"]] <- gmm_fit$classification
} else {
  warning("Package 'mclust' not available; skipping GMM.")
}

## --- Spectral clustering (optional if kernlab installed) ----------
if (requireNamespace("kernlab", quietly = TRUE)) {
  spec_fit <- kernlab::specc(X_scaled, centers = k)
  clusterings[["spectral"]] <- as.integer(spec_fit)
} else {
  warning("Package 'kernlab' not available; skipping spectral clustering.")
}

methods <- names(clusterings)

# -------------------------------------------------------------------
# 3. Internal metrics: WCSS & average silhouette
# -------------------------------------------------------------------

# helper: total within-cluster sum of squares
compute_wcss <- function(X, labels) {
  df <- as.data.frame(X)
  split_df <- split(df, labels)
  sum(vapply(split_df, function(cl_df) {
    if (nrow(cl_df) <= 1) return(0)
    center <- colMeans(cl_df)
    sum(rowSums((as.matrix(cl_df) - center)^2))
  }, numeric(1)))
}

internal_results <- list()
dist_mat <- dist(X_scaled)

for (m in methods) {
  lab <- clusterings[[m]]
  
  # WCSS
  wcss <- compute_wcss(X_scaled, lab)
  
  # average silhouette (can fail for degenerate labels, so wrap in try)
  sil_mean <- NA_real_
  if (length(unique(lab)) > 1) {
    sil_obj <- cluster::silhouette(lab, dist_mat)
    sil_mean <- mean(sil_obj[, "sil_width"])
  }
  
  internal_results[[m]] <- data.frame(
    method      = m,
    wcss        = wcss,
    sil_mean    = sil_mean
  )
}

internal_metrics <- bind_rows(internal_results) %>%
  arrange(method)

write.csv(internal_metrics,
          "tables/compare_algorithms_internal.csv",
          row.names = FALSE)

# -------------------------------------------------------------------
# 4. External metrics: agreement with ROLE (if present)
# -------------------------------------------------------------------

external_results <- list()

if ("role" %in% names(lol)) {
  idx_role <- !is.na(lol$role)
  
  if (any(idx_role)) {
    role_vec <- lol$role[idx_role]
    
    for (m in methods) {
      lab <- clusterings[[m]][idx_role]
      
      ari_val <- adjustedRandIndex(lab, role_vec)
      nmi_val <- NMI(lab, role_vec)
      
      external_results[[m]] <- data.frame(
        method   = m,
        ari_role = ari_val,
        nmi_role = nmi_val
      )
    }
    
    external_metrics <- bind_rows(external_results) %>%
      arrange(method)
    
    write.csv(external_metrics,
              "tables/compare_algorithms_external_role.csv",
              row.names = FALSE)
  } else {
    warning("All roles are NA; skipping external (role) comparison.")
  }
} else {
  warning("No 'role' column found in lol_base_stats_clean.csv; skipping external comparison.")
}

# -------------------------------------------------------------------
# 5. Pairwise agreement between algorithms (ARI & NMI)
# -------------------------------------------------------------------

pair_results <- list()

for (i in seq_along(methods)) {
  for (j in seq_along(methods)) {
    m1 <- methods[[i]]
    m2 <- methods[[j]]
    
    labs1 <- clusterings[[m1]]
    labs2 <- clusterings[[m2]]
    
    ari_ij <- adjustedRandIndex(labs1, labs2)
    nmi_ij <- NMI(labs1, labs2)
    
    pair_results[[length(pair_results) + 1]] <- data.frame(
      method1 = m1,
      method2 = m2,
      ari     = ari_ij,
      nmi     = nmi_ij
    )
  }
}

pairwise_agreement <- bind_rows(pair_results) %>%
  arrange(method1, method2)

write.csv(pairwise_agreement,
          "tables/compare_algorithms_pairwise.csv",
          row.names = FALSE)

cat("Algorithm comparison tables written to:\n",
    "  tables/compare_algorithms_internal.csv\n",
    "  tables/compare_algorithms_external_role.csv (if role present)\n",
    "  tables/compare_algorithms_pairwise.csv\n")

