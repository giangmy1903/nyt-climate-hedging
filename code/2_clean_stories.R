# 2_clean_stories.R
# Joins the 466 saved months, keeps news stories only (no blogs, no story twice), counts them
# by year, and draws at most 100 a year at random for the model to read
# In:  data/nyt/*.json
# Out: data_clean/stories_per_year.csv  (committed: counts only)
#      data/sample.csv                  (not committed: the stories' text)
#      data/filter_counts.csv           (the numbers for NOTES.md)

source("code/functions.R", local = TRUE)

# Parameters
PER_YEAR     <- 100                # at most 100 stories a year go to the model
YEARS        <- 1988:2026
N_MONTHS     <- 466                # Jan 1988 - Oct 2026, as saved by 1_download_nyt.R
MONTH_DIR    <- "data/nyt"
NEWS_TYPE    <- "News"             # type_of_material of a news story (not Op-Ed, Letter, Blog...)
BLOG_PATTERN <- "blogs\\.nytimes\\.com|/blogs/"   # a blog post's web address
MIN_CHARS    <- 20                 # shorter text is too empty to call two items the same story
SEED         <- 6850
PER_YEAR_FILE <- "data_clean/stories_per_year.csv"   # out: committed, counts only
SAMPLE_FILE   <- "data/sample.csv"                   # out: not committed, the stories' text
COUNTS_FILE   <- "data/filter_counts.csv"            # out: the numbers for NOTES.md

# Read the months
files  <- list.files(MONTH_DIR, pattern = "\\.json$", full.names = TRUE)
check(length(files) == N_MONTHS, paste("expected", N_MONTHS, "months, found", length(files)))
months <- lapply(files, fromJSON)                                  # each: month, n_items, stories
n_items <- sum(sapply(months, function(x) x$n_items))              # every item in the archive
stories <- do.call(rbind, lapply(months, function(x) if (length(x$stories)) x$stories))   # empty months add nothing
n_tagged <- nrow(stories)

# Filter 1: news stories only
stories <- stories[stories$type == NEWS_TYPE, ]
n_news <- nrow(stories)

# Filter 2: no blog posts (some years type them as News)
stories <- stories[!grepl(BLOG_PATTERN, stories$url), ]
n_noblog <- nrow(stories)

# Filter 3: no story twice: the same id, or the same headline, summary and first paragraph
stories <- stories[order(stories$date, stories$id), ]
words <- tolower(trimws(paste(stories$headline, stories$summary, stories$lead)))
twice <- duplicated(stories$id) | (duplicated(words) & nchar(words) > MIN_CHARS)   # empty items are not duplicates
stories <- stories[!twice, ]
n_unique <- nrow(stories)

stories$lead <- ifelse(stories$lead == "", stories$snippet, stories$lead)   # no first paragraph: use the snippet
stories$year <- as.integer(substr(stories$date, 1, 4))
check(stories$year %in% YEARS, "a story is dated outside 1988-2026", stories[, c("id", "date", "headline")])

# Tagged news stories per year: the top panel scales these
per_year <- data.frame(year = YEARS, tagged_news = as.vector(table(factor(stories$year, levels = YEARS))))
check(per_year$tagged_news > 0, "a year has no tagged news stories", per_year)
write.csv(per_year, PER_YEAR_FILE, row.names = FALSE)

# The sample: every story in a year with 100 or fewer, else 100 drawn at random
set.seed(SEED)                                                     # one seed, years in order: the same draw every run
by_year <- split(stories$id, stories$year)
pick <- unlist(lapply(by_year, function(ids) if (length(ids) <= PER_YEAR) ids else sample(ids, PER_YEAR)))
sampled <- stories[stories$id %in% pick, c("id", "date", "year", "headline", "summary", "lead")]
write.csv(sampled, SAMPLE_FILE, row.names = FALSE)

counts <- data.frame(
  step = c("all items in the archive, Jan 1988 - Oct 2026", "carry a climate subject tag",
           "type_of_material is News", "not a blog post", "not a duplicate",
           "read by the model (at most 100 a year)"),
  stories = c(n_items, n_tagged, n_news, n_noblog, n_unique, nrow(sampled))
)
write.csv(counts, COUNTS_FILE, row.names = FALSE)
print(counts, row.names = FALSE)