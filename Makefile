# Makefile for LoL clustering project

RSCRIPT = Rscript

DATA    = data/lol_base_stats_clean.csv
RESULTS = results/selected_k.txt results/kmeans_fit.rds
TABLES  = tables/summary_stats.csv tables/cor_matrix.csv \
          tables/k_grid_silhouette.csv tables/kmeans_cluster_summary.csv \
          tables/kmeans_outliers_top10.csv tables/champion_clusters_kmeans.csv \
          tables/feature_importance_sd.csv tables/feature_importance_anova.csv \
          tables/algorithm_ari_comparison.csv
FIGS    = figs/corrplot.png figs/elbow.png figs/silhouette.png figs/gap.png \
          figs/kmeans_scatter_1_2.png

.PHONY: all clean

all: $(DATA) $(FIGS) $(TABLES)

$(DATA): R/01_scrape_clean.R R/common_packages.R
	$(RSCRIPT) R/01_scrape_clean.R

tables/summary_stats.csv tables/cor_matrix.csv figs/corrplot.png: \
	$(DATA) R/02_eda.R R/common_packages.R
	$(RSCRIPT) R/02_eda.R

results/selected_k.txt tables/k_grid_silhouette.csv figs/elbow.png \
figs/silhouette.png figs/gap.png: \
	$(DATA) R/03_choose_k.R R/common_packages.R
	$(RSCRIPT) R/03_choose_k.R

results/kmeans_fit.rds tables/kmeans_cluster_summary.csv \
tables/kmeans_outliers_top10.csv tables/champion_clusters_kmeans.csv \
figs/kmeans_scatter_1_2.png: \
	$(DATA) results/selected_k.txt R/04_kmeans_clustering.R R/common_packages.R
	$(RSCRIPT) R/04_kmeans_clustering.R

tables/feature_importance_sd.csv tables/feature_importance_anova.csv: \
	results/kmeans_fit.rds $(DATA) R/06_feature_importance.R R/common_packages.R
	$(RSCRIPT) R/06_feature_importance.R

tables/algorithm_ari_comparison.csv results/hc_fit.rds results/gmm_fit.rds: \
	results/selected_k.txt $(DATA) results/kmeans_fit.rds \
	R/07_compare_algorithms.R R/common_packages.R
	$(RSCRIPT) R/07_compare_algorithms.R

# If you want label comparison, add a target for 05_compare_labels.R

clean:
	rm -rf data/*.csv results/* tables/* figs/*
