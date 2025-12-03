# League of Legends Champion Clustering Project

This project performs a fully reproducible clustering analysis of **League of Legends champion base statistics**, using:

- Web scraping (League Wiki)
- Data cleaning
- Exploratory data analysis (EDA)
- Optimal k selection (elbow, silhouette, gap statistic)
- K-means clustering + PCA visualization
- External validation against **champion roles**
- Feature importance (permutation)
- Full report rendered via R Markdown

The entire workflow is automated through:

- **Makefile** (automates whole project)
- **Dockerfile** (run projectin Docker container)
- **R Markdown** (`report.Rmd`) (final report)
- **R scripts** (`R/01_...R` through `R/07_...R`)

Running one command (`make report.pdf`) produces a complete analysis from scratch.

## How to Build and Run the Project
1. Clone the Repository
Type into the Terminal:
git clone https://github.com/Derek-Yao8/611_final_project

cd 611_final_project

2. Build Docker Image
docker build -t derekyao .

docker run --rm -p 8787:8787 -e PASSWORD=lolpass derekyao

Open your browser and go to http://localhost:8787
username: rstudio

password: lolpass


Inside the Terminal in RStudio, type in: 
cd /home/rstudio/work

make report.pdf

Then you have the final report in PDF format.


This project is entirely automated using a Makefile.

Each step produces files that depend on earlier steps:

01_scrape_clean.R → creates the cleaned data

02_eda.R → summary tables + correlation heatmap

03_choose_k.R → elbow/silhouette/gap + selected k

04_kmeans_clustering.R → clusters, PCA plots, labels

05_compare_labels.R → ARI/NMI vs roles

06_feature_importance.R → Permutation Features importance plot

07_compare_algorithms.R → internal/external validity, pairwise agreement

report.Rmd → combines all results into a PDF

Makefile manages all dependencies, so:

If a script changes → only necessary steps rerun

If data changes → downstream figures/tables regenerate

If figures/tables/results change → report is rebuilt automatically

This ensures full reproducibility.

To clean generated files: type in:
make clean

Data is obtained from the League of Legends Wiki and a Kaggle Dataset containing
League of Legends champion roles: 

https://wiki.leagueoflegends.com/en-us/List_of_champions/Base_statistics

https://www.kaggle.com/datasets/dem0nking/league-of-legends-champions-dataset?resource=download&select=champions.csv
