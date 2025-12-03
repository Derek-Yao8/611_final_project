source("/home/rstudio/work/R/common_packages.R")

dir.create("figs", showWarnings = FALSE)
dir.create("tables", showWarnings = FALSE)

kfit <- readRDS("results/kmeans_fit.rds")

# Baseline cluster assignments (DO NOT recompute)
clusters <- kfit$cluster
k <- length(unique(clusters))

# ---------------------------------------------------------
# Load the data used in k-means
# ---------------------------------------------------------
X <- read_csv("data/lol_base_stats_clean.csv")

# Numeric features only
X_num <- X %>% dplyr::select(where(is.numeric))

# IMPORTANT: use the SAME transformation as in 04_kmeans_clustering.R
# If you used scale(X_num) there, do the same here:
X_scaled <- scale(X_num)
X_scaled <- as.data.frame(X_scaled)

# ---------------------------------------------------------
# ARI-based permutation importance
# ---------------------------------------------------------
perm_importance_ari <- function(data, clusters, k, n_perm = 30) {
  vars <- colnames(data)
  importance <- numeric(length(vars))
  
  set.seed(123)
  
  for (i in seq_along(vars)) {
    var <- vars[i]
    ari_scores <- numeric(n_perm)
    
    for (b in seq_len(n_perm)) {
      # permute one variable
      data_perm <- data
      data_perm[[var]] <- sample(data_perm[[var]])
      
      # use SAME k and SAME starting centers as original model
      km_perm <- kmeans(data_perm, centers = kfit$centers)
      
      ari_scores[b] <- adjustedRandIndex(clusters, km_perm$cluster)
    }
    
    # importance = drop in ARI
    importance[i] <- 1 - mean(ari_scores)
  }
  
  tibble(stat = vars, importance = importance)
}

fi_ari <- perm_importance_ari(X_scaled, clusters, k, n_perm = 30)

# ---------------------------------------------------------
# Pretty labels
# ---------------------------------------------------------
stat_labels <- c(
  hp              = "Health (Base)",
  hp_growth       = "Health Growth / Level",
  hp5             = "Health Regen (Base)",
  hp5_growth      = "Health Regen Growth / Level",
  mp              = "Mana (Base)",
  mp_growth       = "Mana Growth / Level",
  mp5             = "Mana Regen (Base)",
  mp5_growth      = "Mana Regen Growth / Level",
  ad              = "Attack Damage (Base)",
  ad_growth       = "Attack Damage Growth / Level",
  `as`            = "Attack Speed (Base)",
  as_growth       = "Attack Speed Growth / Level",
  ar              = "Armor (Base)",
  ar_growth       = "Armor Growth / Level",
  mr              = "Magic Resist (Base)",
  mr_growth       = "MR Growth / Level",
  ms              = "Movement Speed",
  range           = "Attack Range"
)

fi_ari_pretty <- fi_ari %>%
  mutate(stat = recode(stat, !!!stat_labels)) %>%
  arrange(desc(importance))

# ---------------------------------------------------------
# Save table
# ---------------------------------------------------------
write_csv(fi_ari_pretty, "tables/feature_importance_permutation.csv")

# ---------------------------------------------------------
# Plot (descending)
# ---------------------------------------------------------
fi_plot <- fi_ari_pretty %>%
  mutate(stat = fct_reorder(stat, importance))

p <- ggplot(fi_plot, aes(x = stat, y = importance)) +
  geom_col() +
  coord_flip() +
  labs(
    x = "Base Statistic",
    y = "Importance (1 − ARI)",
    title = "Permutation Feature Importance (ARI Drop)"
  ) +
  theme_minimal(base_size = 12)

ggsave("figs/feature_importance_permutation.png",
       p,
       width = 7, height = 5, dpi = 300)
