#!/usr/bin/env Rscript

source("/home/rstudio/work/common_packages.R")

dir.create("tables", showWarnings = FALSE)

lol    <- read.csv("data/lol_base_stats_clean.csv")
km_fit <- readRDS("results/kmeans_fit.rds")

clusters_km <- km_fit$cluster
num_vars    <- lol %>% select(where(is.numeric)) %>% names()

lol_clust <- lol %>%
  mutate(cluster_km = clusters_km)


## 6.2 ANOVA F-stat per stat
anova_results <- map_dfr(num_vars, function(v) {
  df <- lol_clust %>%
    select(cluster_km, all_of(v)) %>%
    drop_na()
  
  fit  <- aov(reformulate("factor(cluster_km)", v), data = df)
  tidy <- broom::tidy(fit)
  
  data.frame(
    stat    = v,
    f_value = tidy$statistic[1],
    p_value = tidy$p.value[1]
  )
})

anova_results <- anova_results %>% arrange(desc(f_value))
write.csv(anova_results, "tables/feature_importance_anova.csv", row.names = FALSE)
