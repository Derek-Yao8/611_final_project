#!/usr/bin/env Rscript

source("/home/rstudio/work/common_packages.R")

dir.create("tables", showWarnings = FALSE)
dir.create("figs", showWarnings = FALSE)

lol <- read.csv("data/lol_base_stats_clean.csv")

num_vars <- lol %>% select(where(is.numeric)) %>% names()
X_raw    <- lol %>% select(all_of(num_vars))

## Summary stats table
summary_df <- X_raw %>%
  summarize(across(everything(), list(mean = mean, sd = sd, min = min,
                                      q25 = ~ quantile(.x, 0.25),
                                      median = median,
                                      q75 = ~ quantile(.x, 0.75),
                                      max = max), na.rm = TRUE)) %>%
  pivot_longer(everything(),
               names_to = c("stat", ".value"),
               names_sep = "_")

write.csv(summary_df, "tables/summary_stats.csv", row.names = FALSE)

## Correlation matrix table
cor_mat <- cor(X_raw, use = "pairwise.complete.obs")
write.csv(cor_mat, "tables/cor_matrix.csv")

## Correlation heatmap figure
png("figs/corrplot.png", width = 1200, height = 1000, res = 150)
corrplot(cor_mat, method = "color", tl.cex = 0.7)
dev.off()
