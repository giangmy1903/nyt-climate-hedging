# 3_hand_sample.R
# Draws 30 stories at random from the model's sample for me to label by hand, BEFORE the model
# reads them: a label you have seen pulls yours towards it (session 17)
# In:  data/sample.csv
# Out: data/hand_check.csv (not committed: story text). Fill in the two empty columns, then save as CSV:
#      my_climate: yes or no
#      my_warming: fact, uncertain or not stated (empty when my_climate is no)

N_HAND      <- 30
SEED        <- 6850
SAMPLE_FILE <- "data/sample.csv"
HAND_FILE   <- "data/hand_check.csv"

if (file.exists(HAND_FILE)) {
  message(HAND_FILE, " exists already: not drawing again, so your labels are safe")
} else {
  s <- read.csv(SAMPLE_FILE)
  set.seed(SEED)
  pick <- sample(nrow(s), N_HAND)                                  # random, so the easy ones are not picked by eye
  hand <- data.frame(id = s$id[pick], headline = s$headline[pick], summary = s$summary[pick],
                     lead = s$lead[pick], my_climate = "", my_warming = "")   # no date, as for the model
  write.csv(hand, HAND_FILE, row.names = FALSE)
  message("Label the ", N_HAND, " stories in ", HAND_FILE, " before running 4_label_stories.R")
}