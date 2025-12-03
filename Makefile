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

all: report.pdf

data results tables figs:
	mkdir -p $@

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
figs/kmeans_pca_clusters.png figs/kmeans_pca_role.png: \
	$(DATA) results/selected_k.txt R/04_kmeans_clustering.R R/common_packages.R
	$(RSCRIPT) R/04_kmeans_clustering.R

tables/confusion_role_kmeans.csv tables/label_agreement_kmeans.csv: \
    data/lol_base_stats_clean.csv results/kmeans_fit.rds R/05_compare_labels.R R/common_packages.R
	$(RSCRIPT) R/05_compare_labels.R

figs/feature_importance_permutation.csv: \
	results/kmeans_fit.rds $(DATA) R/06_feature_importance.R R/common_packages.R
	$(RSCRIPT) R/06_feature_importance.R

tables/compare_algorithms_internal.csv tables/compare_algorithms_external_role.csv \
tables/compare_algorithms_pairwise.csv: \
    data/lol_base_stats_clean.csv results/selected_k.txt R/07_compare_algorithms.R R/common_packages.R
	$(RSCRIPT) R/07_compare_algorithms.R

report.pdf: report.Rmd \
	tables/summary_stats.csv \
	figs/corrplot.png \
	figs/elbow_kmeans.png figs/gap_stat.png figs/silhouette_kmeans.png \
	results/selected_k.txt \
	figs/kmeans_pca_clusters.png \
	figs/kmeans_pca_role.png \
	tables/label_agreement_kmeans.csv \
	tables/compare_algorithms_internal.csv \
	figs/feature_importance_permutation.png
	R -e "rmarkdown::render('report.Rmd', output_format = 'pdf_document')"


clean:
	rm -f data/lol_base_stats_clean.csv
	rm -f tables/*.csv
	rm -f figs/*.png
	rm -f results/*.rds results/*.txt
	rm -f report.pdf