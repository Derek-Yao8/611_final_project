#!/usr/bin/env Rscript

source("/home/rstudio/work/R/common_packages.R")

dir.create("tables", showWarnings = FALSE)
dir.create("figs", showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)

lol <- read.csv("data/lol_base_stats_clean.csv")
num_vars <- lol %>% select(where(is.numeric)) %>% names()
X_raw    <- lol %>% select(all_of(num_vars))
X        <- scale(X_raw) %>% as.matrix()

set.seed(2393)

## Elbow plot
p_elbow <- fviz_nbclust(X, kmeans, method = "wss") +
  ggtitle("Elbow Method for Choosing k")
ggsave("figs/elbow.png", p_elbow, width = 6, height = 4, dpi = 300)

## Silhouette plot
p_sil <- fviz_nbclust(X, kmeans, method = "silhouette") +
  ggtitle("Silhouette Method for Choosing k")
ggsave("figs/silhouette.png", p_sil, width = 6, height = 4, dpi = 300)

## Gap statistic
gap_res <- clusGap(X, kmeans, nstart = 25, K.max = 12, B = 50)
p_gap   <- suppressWarnings(fviz_gap_stat(gap_res) + ggtitle("Gap Statistic for Choosing k"))
ggsave("figs/gap.png", p_gap, width = 6, height = 4, dpi = 300)

## Data frame of k vs silhouette for programmatic choice
sil_scores <- tibble(
  k   = 2:12,
  sil = map_dbl(2:12, ~{
    km <- kmeans(X, centers = .x, nstart = 25)
    ss <- silhouette(km$cluster, dist(X))
    mean(ss[, "sil_width"])
  })
)

write.csv(sil_scores, "tables/k_grid_silhouette.csv", row.names = FALSE)

best_k_sil <- sil_scores %>% filter(sil == max(sil)) %>% pull(k)

## Save chosen k to results 
writeLines(as.character(best_k_sil), "results/selected_k.txt")

