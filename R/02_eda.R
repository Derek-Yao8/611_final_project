#!/usr/bin/env Rscript

source("/home/rstudio/work/R/common_packages.R")

dir.create("tables", showWarnings = FALSE)
dir.create("figs", showWarnings = FALSE)

lol <- read.csv("data/lol_base_stats_clean.csv")

num_vars <- lol %>% select(where(is.numeric)) %>% names()
X_raw    <- lol %>% select(all_of(num_vars))

## Summary stats table
summary_df <- X_raw %>%
  summarise(
    across(
      everything(),
      list(
        mean   = ~ mean(.x, na.rm = TRUE),
        sd     = ~ sd(.x, na.rm = TRUE),
        min    = ~ min(.x, na.rm = TRUE),
        q25    = ~ quantile(.x, 0.25, na.rm = TRUE),
        median = ~ median(.x, na.rm = TRUE),
        q75    = ~ quantile(.x, 0.75, na.rm = TRUE),
        max    = ~ max(.x, na.rm = TRUE)
      )
    )
  ) %>%
  pivot_longer(
    everything(),
    names_to      = c("stat", ".value"),
    names_pattern = "^(.*)_(mean|sd|min|q25|median|q75|max)$"
  )

stat_labels <- c(
  hp              = "Health (Base)",
  hp_growth       = "Health Growth / Level",
  hp5        = "Health Regen (Base)",
  hp5_growth = "Health Regen Growth / Level",
  mp              = "Mana (Base)",
  mp_growth       = "Mana Growth / Level",
  mp5        = "Mana Regen (Base)",
  mp5_growth = "Mana Regen Growth / Level",
  ad              = "Attack Damage (Base)",
  ad_growth       = "Attack Damage Growth / Level",
  as            = "Attack Speed (Base)",
  as_growth       = "Attack Speed Growth / Level",
  ar           = "Armor (Base)",
  ar_growth    = "Armor Growth / Level",
  mr              = "Magic Resist (Base)",
  mr_growth       = "MR Growth / Level",
  ms       = "Movement Speed",
  range           = "Attack Range"
)

summary_stats_labeled <- summary_df %>%
  mutate(
    stat = dplyr::recode(stat, !!!stat_labels)
  )

write.csv(summary_stats_labeled, "tables/summary_stats.csv", row.names = FALSE)

## Correlation matrix table
label_map <- c(
  hp              = "Health (Base)",
  hp_growth       = "Health Growth / Level",
  hp5        = "Health Regen (Base)",
  hp5_growth = "Health Regen Growth / Level",
  mp              = "Mana (Base)",
  mp_growth       = "Mana Growth / Level",
  mp5        = "Mana Regen (Base)",
  mp5_growth = "Mana Regen Growth / Level",
  ad              = "Attack Damage (Base)",
  ad_growth       = "Attack Damage Growth / Level",
  as            = "Attack Speed (Base)",
  as_growth       = "Attack Speed Growth / Level",
  ar           = "Armor (Base)",
  ar_growth    = "Armor Growth / Level",
  mr              = "Magic Resist (Base)",
  mr_growth       = "MR Growth / Level",
  ms       = "Movement Speed",
  range           = "Attack Range"
)

cor_mat <- cor(X_raw, use = "pairwise.complete.obs")
write.csv(cor_mat, "tables/cor_matrix.csv")

labeled_stats <- ifelse(
  colnames(cor_mat) %in% names(label_map),
  label_map[colnames(cor_mat)],
  colnames(cor_mat)
)

rownames(cor_mat) <- labeled_stats
colnames(cor_mat) <- labeled_stats

## Correlation heatmap figure
png("figs/corrplot.png", width = 1200, height = 1000, res = 150)
par(oma = c(0,0,4,0))
par(mar = c(3,3,2,2))
corrplot(cor_mat, method = "color", tl.cex = 0.7)
mtext("Correlation Heatmap of Champion Base Stats", side = 3, line = 3, cex = 2, font = 2)
dev.off()

