# 4_label_stories.R
# Asks the open model two questions about each sampled story, one call each, without the date:
#   1. is climate change the story's main subject? (yes, no)
#   2. for the stories that are: is warming, or its human cause, stated as fact, as uncertain, or not stated?
# Every reply is saved, raw, as one JSON file per story in replies/, so an interrupted run
# resumes where it stopped and a rerun makes no call
# In:  data/sample.csv, code/prompt_climate.txt, code/prompt_hedging.txt
# Out: data_clean/labels.csv (committed: id, date and both answers, no story text)
# Needs ellmer and Ollama running with the model pulled: ollama pull qwen3.5:4b-q4_K_M

library(ellmer)                    # install.packages("ellmer") once; calls language models from R
source("code/functions.R", local = TRUE)       # save_replies(), check()

# Parameters
MODEL        <- "qwen3.5:4b-q4_K_M"   # the model file, written once. This laptop has 8 GB: the 4b file, not the 9b
MODEL_PARAMS <- params(temperature = 0, seed = 6850, reasoning_effort = "none")   # same reply every run; thinking off
TEST_RUN       <- TRUE                # TRUE: only the 30 stories in data/hand_check.csv (timing, prompt checks)
PROMPT_VERSION <- "v1"                # change it with every edit to a prompt file: each version's replies stay apart
CLIMATE_PROMPT <- paste(readLines("code/prompt_climate.txt"), collapse = "\n")
HEDGING_PROMPT <- paste(readLines("code/prompt_hedging.txt"), collapse = "\n")
CLIMATE_LABELS <- c("yes", "no")                         # the only answers allowed to question 1
WARMING_LABELS <- c("fact", "uncertain", "not stated")   # ... and to question 2
SAMPLE_FILE    <- "data/sample.csv"
HAND_FILE      <- "data/hand_check.csv"
REPLY_DIR      <- "replies"
LABELS_FILE    <- "data_clean/labels.csv"

# The reply formats: the only answers allowed. quote comes first, so the model copies the words, then labels
climate_type <- type_object(climate = type_enum(CLIMATE_LABELS))
hedging_type <- type_object(quote = type_string("The story's words about warming or its human cause; empty if none"),
                            warming = type_enum(WARMING_LABELS))

# The story as the model reads it: headline, summary and first paragraph, no date
# My hand labels come first: the model does not run until all 30 are filled in (3_hand_sample.R)
hand <- read.csv(HAND_FILE, colClasses = "character")
check(hand$my_climate %in% CLIMATE_LABELS,
      paste("label every story in", HAND_FILE, "first (my_climate: yes or no), then run this again"))

s <- read.csv(SAMPLE_FILE)
s[is.na(s)] <- ""
if (TEST_RUN) s <- s[s$id %in% hand$id, ]
texts <- paste0("Headline: ", s$headline, "\nSummary: ", s$summary, "\nFirst paragraph: ", s$lead)
dir1 <- file.path(REPLY_DIR, PROMPT_VERSION, "climate")           # e.g. replies/v1/climate
dir2 <- file.path(REPLY_DIR, PROMPT_VERSION, "hedging")

# Question 1 on every story
save_replies(texts, s$id, dir1, CLIMATE_PROMPT, climate_type)
r1 <- lapply(file.path(dir1, paste0(id_to_file(s$id), ".json")), fromJSON)   # read back from disk
s$climate <- sapply(r1, function(x) x$answer$climate)

# Question 2 on the stories about climate
yes <- which(s$climate == CLIMATE_LABELS[1])
save_replies(texts[yes], s$id[yes], dir2, HEDGING_PROMPT, hedging_type)
r2 <- lapply(file.path(dir2, paste0(id_to_file(s$id[yes]), ".json")), fromJSON)
s$warming <- NA
s$warming[yes] <- sapply(r2, function(x) x$answer$warming)

# Checks: every story has an allowed answer, and warming only where climate is yes
check(sapply(c(r1, r2), function(x) x$model) == MODEL,
      "a saved reply came from another model: give this model its own PROMPT_VERSION")
check(s$climate %in% CLIMATE_LABELS, "a climate answer is missing or odd", s[, c("id", "climate")])
check(s$warming[yes] %in% WARMING_LABELS, "a warming answer is not an allowed label", s[yes, c("id", "warming")])

labels <- s[, c("id", "date", "climate", "warming")]
write.csv(labels, LABELS_FILE, row.names = FALSE, na = "")

# Time and counts, from the saved replies
sec <- unlist(lapply(c(r1, r2), function(x) x$seconds))           # seconds per call
print(c(calls = length(sec), sec_each = round(median(sec), 2), hours_all = round(sum(sec) / 3600, 2)))
print(table(climate = labels$climate))
print(table(warming = labels$warming))