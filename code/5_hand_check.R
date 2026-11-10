# 5_hand_check.R
# Scores the model against my hand labels, as session 17 scores it against the annotators:
# agreement rate, base rate, confusion table, and every story we disagree on
# In:  data/hand_check.csv (mine), data_clean/labels.csv (the model's)
# Out: printed; copy the numbers and the disagreements into NOTES.md

source("code/functions.R", local = TRUE)       # check()

# Parameters
HAND_FILE   <- "data/hand_check.csv"
LABELS_FILE <- "data_clean/labels.csv"
CLIMATE_LABELS <- c("yes", "no")                         # the labels I may type, as in 4_label_stories.R
WARMING_LABELS <- c("fact", "uncertain", "not stated")
CLIMATE_YES <- CLIMATE_LABELS[1]   # question 2 is scored on the stories we both give this label
WRAP_WIDTH  <- 90                  # characters a line when the disagreements are printed

# Base rate: the agreement of a lazy rater who always gives my most common label
base_rate <- function(mine) max(prop.table(table(mine)))
most_common <- function(mine) names(which.max(table(mine)))

hand <- read.csv(HAND_FILE, colClasses = "character")            # empty cells stay "", not NA
hand$my_climate <- tolower(trimws(hand$my_climate))
hand$my_warming <- tolower(trimws(hand$my_warming))

if (all(hand$my_climate == "")) {
  message(HAND_FILE, " has no labels yet: label the stories first")
} else {
  # My own labels: a typo ("uncertian") or a warming label on a "no" story would be scored as a disagreement
  check(hand$my_climate %in% CLIMATE_LABELS, "a my_climate cell is not yes or no", hand[, c("id", "my_climate")])
  check(ifelse(hand$my_climate == CLIMATE_YES, hand$my_warming %in% WARMING_LABELS, hand$my_warming == ""),
        "my_warming must be fact, uncertain or not stated on a yes story, and empty on a no story",
        hand[, c("id", "my_climate", "my_warming")])

  labels <- read.csv(LABELS_FILE, colClasses = "character")
  k <- match(hand$id, labels$id)                                   # the model's row for each hand-labelled story
  check(!is.na(k), "a hand-labelled story has no model label: run 4_label_stories.R first", hand[, c("id", "headline")])
  hand$climate <- labels$climate[k]
  hand$warming <- labels$warming[k]

  # Question 1: about climate? On all the stories
  cat("Question 1, agreement:", mean(hand$my_climate == hand$climate), "on", nrow(hand), "stories\n")
  cat("Base rate, always '", most_common(hand$my_climate), "': ", base_rate(hand$my_climate), "\n", sep = "")
  print(table(me = hand$my_climate, model = hand$climate))

  # Question 2: fact, uncertain or not stated? On the stories we both call climate
  both <- hand[hand$my_climate == CLIMATE_YES & hand$climate == CLIMATE_YES, ]
  cat("\nQuestion 2, agreement:", mean(both$my_warming == both$warming), "on", nrow(both), "stories\n")
  cat("Base rate, always '", most_common(both$my_warming), "': ", base_rate(both$my_warming), "\n", sep = "")
  print(table(me = both$my_warming, model = both$warming))

  # Every story we disagree on, to read again
  wrong <- hand$my_climate != hand$climate |
           (hand$my_climate == CLIMATE_YES & hand$climate == CLIMATE_YES & hand$my_warming != hand$warming)
  cat("\nDisagreements:", sum(wrong), "\n")
  writeLines(strwrap(paste0(hand$id[wrong], " (me: ", hand$my_climate[wrong], " / ", hand$my_warming[wrong],
                            "; model: ", hand$climate[wrong], " / ", hand$warming[wrong], ") ",
                            hand$headline[wrong]), width = WRAP_WIDTH, exdent = 2))
}
