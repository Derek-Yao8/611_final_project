#!/usr/bin/env Rscript

# R/01_scrape_clean.R

source("/home/rstudio/work/common_packages.R")

dir.create("data", showWarnings = FALSE)

url  <- "https://wiki.leagueoflegends.com/en-us/List_of_champions/Base_statistics"
page <- read_html(url)

# Extract all tables with class "wikitable"
stat_tables <- page %>%
  html_elements("table.wikitable") %>%
  html_table(fill = TRUE)

# Inspect manually first time (use View() in RStudio)
# View(stat_tables[[1]])
lol_raw <- stat_tables[[1]]   # adjust index if needed

# Clean to snake_case
lol_clean <- lol_raw %>% clean_names()

# >>> NEW STEP: rename columns ending with "_2" to "_growth"
# Example: hp_2 → hp_growth
names(lol_clean) <- gsub("_2$", "_growth", names(lol_clean))

# Check the new names
# print(names(lol_clean))

# TODO: adjust champion column name if different in the table
lol <- lol_clean %>%
  rename(
    champion = champions   # e.g. could be name, champion_name, etc.
    # role  = role_col_if_present,
    # class = class_col_if_present
  )

# Columns that should NOT be converted to numeric
id_cols <- c("champion")  # add "role", "class" later if merged

# Everything else → numeric stats
stat_cols <- setdiff(names(lol), id_cols)

lol <- lol %>%
  mutate(across(all_of(stat_cols), ~ {
    if (is.numeric(.x)) {
      .x
    } else {
      as.numeric(gsub("[^0-9\\.-]", "", .x))
    }
  }))

write.csv(lol, "data/lol_base_stats_clean.csv", row.names = FALSE)

