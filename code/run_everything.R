# run_everything.R
# Open hw4.Rproj, so that R starts in the project folder, then source this file
# The first full run: about 2.5 hours of downloads (466 months, 12 seconds apart) and several hours
# of model calls. Saved months and saved replies are never redone, so a rerun takes seconds
# Without an NYT key (a grader on a fresh clone), only the figure is drawn, from the two committed CSV files

steps <- c(
  "code/1_download_nyt.R",         # NYT Archive API -> data/nyt/ (needs NYT_KEY)
  "code/2_clean_stories.R",        # filters, sample -> data_clean/stories_per_year.csv, data/sample.csv
  "code/3_hand_sample.R",          # 30 stories for me to label by hand -> data/hand_check.csv
  "code/4_label_stories.R",        # the open model -> replies/, data_clean/labels.csv (needs Ollama)
  "code/5_hand_check.R",           # my labels against the model's, printed
  "code/6_make_figure.R"           # the two CSV files + NASA -> figures/hw4_target.png
)

if (Sys.getenv("NYT_KEY") == "" && file.exists("data_clean/labels.csv")) {
  message("No NYT_KEY: drawing the figure from the committed CSV files only")
  steps <- "code/6_make_figure.R"
}
for (step in steps) {
  message("\n==== ", step, " ====")
  source(step, local = new.env())
}