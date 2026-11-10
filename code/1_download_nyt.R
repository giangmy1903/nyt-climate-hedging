# 1_download_nyt.R
# Asks the NYT Archive API for every month from January 1988 to October 2026, keeps the items
# that carry one of the four climate subject tags, and saves each month as data/nyt/YYYY-MM.json
# A month saved already is never requested again, so a run that stops picks up where it stopped
# Needs NYT_KEY in ~/.Renviron (restart R after adding it); the key is never printed or saved

source("code/functions.R", local = TRUE)       # httr2, jsonlite, wait_turn(), check()

# Parameters
API_BASE  <- "https://api.nytimes.com/svc/archive/v1"
MONTH_DIR <- "data/nyt"
MONTHS    <- seq(as.Date("1988-01-01"), as.Date("2026-10-01"), by = "month")   # 466 months; 2026 runs to October
PAUSE_SEC <- 12                    # the API allows one request every 12 seconds
TAGS      <- c("Global Warming", "Greenhouse Effect", "Greenhouse Gas Emissions",
               "United Nations Framework Convention on Climate Change")
# The API's names for what I read: where the items sit in a reply, the fields I keep, and the tags
DOCS_PATH <- c("response", "docs")              # reply$response$docs: the month's items
FIELDS    <- list(id = "_id", date = "pub_date", headline = c("headline", "main"), summary = "abstract",
                  lead = "lead_paragraph", snippet = "snippet", type = "type_of_material", url = "web_url")
TAG_LIST  <- "keywords"                         # each item's tags: a list of {name, value}
TAG_NAME  <- "name"                             # the kind of tag...
TAG_VALUE <- "value"                            # ...and the tag itself
TAG_KEEP  <- "subject"                          # only subject tags count, as the homework asks
MONTH_FMT <- "%Y-%m"                            # files and messages name a month "1988-06"
DATE_CHARS <- 10                                # "1988-06-24T00:00:00+0000" -> "1988-06-24"

key <- Sys.getenv("NYT_KEY")
if (key == "") stop("NYT_KEY is empty: add NYT_KEY=... to ~/.Renviron and restart R", call. = FALSE)

# Helpers
txt <- function(x) if (is.null(x) || length(x) == 0) "" else as.character(x[[1]])   # a missing field becomes ""

field <- function(d, path) {       # d[["headline"]][["main"]] for path c("headline", "main"); NULL when missing
  for (p in path) d <- d[[p]]
  d
}

climate_tags <- function(doc) {    # the climate tags one item carries, "" when none
  name  <- tolower(sapply(doc[[TAG_LIST]], function(k) txt(k[[TAG_NAME]])))
  value <- sapply(doc[[TAG_LIST]], function(k) txt(k[[TAG_VALUE]]))
  hits  <- value[name == TAG_KEEP & tolower(value) %in% tolower(TAGS)]   # older items write tags in capitals
  paste(unique(hits), collapse = "; ")
}

keep_climate <- function(docs) {   # one month of items -> the tagged ones, only the fields in FIELDS
  tags <- vapply(docs, climate_tags, character(1))
  docs <- docs[tags != ""]
  out  <- as.data.frame(lapply(FIELDS, function(path) vapply(docs, function(d) txt(field(d, path)), character(1))))
  out$date <- substr(out$date, 1, DATE_CHARS)
  out$tags <- tags[tags != ""]
  out
}

# Download, one month at a time
dir.create(MONTH_DIR, recursive = TRUE, showWarnings = FALSE)
files <- file.path(MONTH_DIR, paste0(format(MONTHS, MONTH_FMT), ".json"))   # one file per month
t0 <- Sys.time()

for (i in seq_along(MONTHS)) {
  if (file.exists(files[i])) next                                    # saved already: never request it twice
  wait_turn(PAUSE_SEC)
  y <- as.integer(format(MONTHS[i], "%Y"))
  m <- as.integer(format(MONTHS[i], "%m"))
  req <- request(sprintf("%s/%d/%d.json", API_BASE, y, m))        # .../1988/6.json
  req <- req_url_query(req, `api-key` = key)
  req <- req_timeout(req, 180)
  req <- req_retry(req, max_tries = 4, backoff = function(i) 60,    # too many requests (429) or a server error:
                   is_transient = function(r) resp_status(r) %in% c(429, 500, 502, 503, 504))   # wait a minute, retry
  docs <- field(resp_body_json(req_perform(req), simplifyVector = FALSE), DOCS_PATH)
  check(length(docs) > 0, paste("the API returned no items for", format(MONTHS[i], MONTH_FMT)))

  stories <- keep_climate(docs)
  rec <- list(month = format(MONTHS[i], MONTH_FMT), n_items = length(docs), stories = stories)   # n_items: for NOTES.md
  write_json(rec, paste0(files[i], ".part"), auto_unbox = TRUE, dataframe = "rows")
  file.rename(paste0(files[i], ".part"), files[i])

  message(sprintf("%s: %5d items, %3d tagged  (%d of %d months, %.0f min)",
                  rec$month, length(docs), nrow(stories), sum(file.exists(files)), length(files),
                  as.numeric(difftime(Sys.time(), t0, units = "mins"))))
}

check(file.exists(files), "some months were not saved", data.frame(file = files))
message("All ", length(files), " months saved in ", MONTH_DIR)
