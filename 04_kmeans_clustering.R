#!/usr/bin/env Rscript

source("/home/rstudio/work/common_packages.R")

dir.create("tables", showWarnings = FALSE)
dir.create("figs", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

lol <- read.csv("data/lol_base_stats_clean.csv")
num_vars <- lol %>% select(where(is.numeric)) %>% names()
X_raw    <- lol %>% select(all_of(num_vars))
X        <- scale(X_raw) %>% as.matrix()

meta <- lol %>% select(champion)  # add role/class later if merged

## Read selected k from previous step
k <- as.integer(readLines("results/selected_k.txt"))

set.seed(2024)
km_fit      <- kmeans(X, centers = k, nstart = 50)
clusters_km <- km_fit$cluster

## Save kmeans fit for other scripts
saveRDS(km_fit, "results/kmeans_fit.rds")

lol_clust <- lol %>% mutate(cluster_km = clusters_km)

## Cluster summary table
cluster_summary <- lol_clust %>%
  group_by(cluster_km) %>%
  summarise(
    across(all_of(num_vars), mean, .names = "mean_{.col}"),
    n = n(),
    .groups = "drop"
  )

write.csv(cluster_summary, "tables/kmeans_cluster_summary.csv", row.names = FALSE)

## Outliers table (top 10)
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

## Simple scatterplot using first two numeric vars
var_x <- num_vars[1]
var_y <- num_vars[2]

p_scatter <- lol_clust %>%
  ggplot(aes_string(x = var_x, y = var_y, colour = "factor(cluster_km)")) +
  geom_point() +
  labs(
    x      = var_x,
    y      = var_y,
    colour = "Cluster",
    title  = paste("k-means clusters in", var_x, "vs", var_y)
  ) +
  theme_minimal()

ggsave("figs/kmeans_scatter_1_2.png", p_scatter, width = 6, height = 4, dpi = 300)

## Save champion + cluster assignments
write.csv(lol_clust, "tables/champion_clusters_kmeans.csv", row.names = FALSE)
