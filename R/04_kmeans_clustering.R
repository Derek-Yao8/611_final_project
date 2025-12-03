#!/usr/bin/env Rscript

# R/04_kmeans_clustering.R

source("/home/rstudio/work/R/common_packages.R")

dir.create("tables", showWarnings = FALSE)
dir.create("figs", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)


# 1. Load data and prepare numeric matrix for clustering
lol <- read.csv("data/lol_base_stats_clean.csv")

# Numeric variables used for clustering (base stats only)
num_vars <- lol %>% select(where(is.numeric)) %>% names()
X_raw    <- lol %>% select(all_of(num_vars))
X        <- scale(X_raw) %>% as.matrix()

# Metadata
has_role <- "role" %in% names(lol)

# Read selected k from previous step
k <- as.integer(readLines("results/selected_k.txt"))


# 2. Run k-means clustering
set.seed(3934)
km_fit      <- kmeans(X, centers = k, nstart = 50)
clusters_km <- km_fit$cluster

# Save k-means fit for use in later scripts
saveRDS(km_fit, "results/kmeans_fit.rds")

lol_clust <- lol %>% mutate(cluster_km = clusters_km)


# 3. Cluster summary table (mean stats per cluster)
cluster_summary <- lol_clust %>%
  group_by(cluster_km) %>%
  summarise(
    across(all_of(num_vars), mean, .names = "mean_{.col}"),
    n = n(),
    .groups = "drop"
  )

write.csv(cluster_summary, "tables/kmeans_cluster_summary.csv", row.names = FALSE)


# 4. Outliers: champions farthest from their cluster centroid
centers <- km_fit$centers

dist_to_center <- purrr::map_dbl(seq_len(nrow(X)), function(i) {
  cl <- clusters_km[i]
  sqrt(sum((X[i, ] - centers[cl, ])^2))
})

outlier_df <- lol_clust %>%
  select(champion, cluster_km) %>%
  mutate(dist_to_center = dist_to_center) %>%
  arrange(desc(dist_to_center))

write.csv(head(outlier_df, 10), "tables/kmeans_outliers_top10.csv", row.names = FALSE)

# Save full champion + cluster assignments
write.csv(lol_clust, "tables/champion_clusters_kmeans.csv", row.names = FALSE)


# 5. PCA *for visualization only* (not used for clustering)
pca <- prcomp(X, scale. = FALSE)
var_explained <- (pca$sdev^2) / sum(pca$sdev^2)

pca_df <- data.frame(
  PC1      = pca$x[, 1],
  PC2      = pca$x[, 2],
  cluster  = factor(clusters_km),
  champion = lol$champion
)

if ("role" %in% names(lol)) {
  pca_df$role <- factor(lol$role)
}
if ("class" %in% names(lol)) {
  pca_df$class <- factor(lol$class)
}

x_lab <- sprintf("PC1 (%.1f%% variance)", 100 * var_explained[1])
y_lab <- sprintf("PC2 (%.1f%% variance)", 100 * var_explained[2])

pca_df$dist <- sqrt(pca_df$PC1^2 + pca_df$PC2^2)

threshold <- quantile(pca_df$dist, 0.95)
outliers <- pca_df %>% filter(dist >= threshold)
# 6. PCA scatterplot colored by k-means cluster
p_pca_outliers <- ggplot(pca_df, aes(PC1, PC2, color = cluster)) +
  geom_point(size = 2, alpha = 0.8) +
  geom_point(data = outliers, color = "red", size = 3) +
  geom_text_repel(
    data = outliers,
    aes(label = champion),
    size = 3,
    box.padding = 0.4,
    point.padding = 0.3,
    max.overlaps = Inf,
    min.segment.length = 0
  ) +
  labs(
    title = "PCA Scatterplot of Champions with Outlier Labels",
    x = "PC1",
    y = "PC2"
  ) +
  theme_minimal(base_size = 12)

ggsave("figs/kmeans_pca_clusters.png", p_pca_outliers,
       width = 7, height = 5, dpi = 300)


# 7. PCA scatterplot colored by role
if (has_role) {
  p_pca_role <- ggplot(pca_df, aes(x = PC1, y = PC2, color = role)) +
    geom_point(size = 3, alpha = 0.85) +
    labs(
      title = "Champion Roles in PCA Space",
      x     = x_lab,
      y     = y_lab,
      color = "Role"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title   = element_text(hjust = 0.5, face = "bold"),
      legend.position = "right",
      panel.grid.minor = element_blank()
    )
  
  ggsave("figs/kmeans_pca_role.png", p_pca_role,
         width = 7, height = 5, dpi = 300)
}
