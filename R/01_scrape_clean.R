#!/usr/bin/env Rscript

source("/home/rstudio/work/common_packages.R")

dir.create("data", showWarnings = FALSE)

### --- Scrape champion base stats ------------------------------------------------------

url  <- "https://wiki.leagueoflegends.com/en-us/List_of_champions/Base_statistics"
page <- read_html(url)

stat_tables <- page %>%
  html_elements("table.wikitable") %>%
  html_table(fill = TRUE)

lol_raw <- stat_tables[[1]]

lol_clean <- lol_raw %>% clean_names()

# Rename any *_2 columns to _growth
names(lol_clean) <- gsub("_2$", "_growth", names(lol_clean))

lol_stats <- lol_clean %>%
  rename(champion = champions)


### --- Load champion roles -------------------------------------------------------------

roles <- read.csv("data/champions.csv")   # <= your roles file
roles <- roles %>% clean_names()

# Ensure champion column matches spelling/case
roles <- roles %>% select(champion_name, role)

roles <- roles %>% 
  rename(
    champion = champion_name,
    role = role
  )


### --- Merge roles onto stats ----------------------------------------------------------

lol <- lol_stats %>%
  left_join(roles, by = "champion")

# Print champions that did NOT match (typos etc.)
unmatched <- lol %>% filter(is.na(role))
if (nrow(unmatched) > 0) {
  warning("Some champions did not match roles:")
  print(unmatched$champion)
}


### --- Convert numeric columns ---------------------------------------------------------

id_cols   <- c("champion", "role")   # role should *not* become numeric
stat_cols <- setdiff(names(lol), id_cols)

lol <- lol %>%
  mutate(across(all_of(stat_cols), ~ {
    if (is.numeric(.x)) .x else as.numeric(gsub("[^0-9\\.-]", "", .x))
  }))

write.csv(lol, "data/lol_base_stats_clean.csv", row.names = FALSE)


