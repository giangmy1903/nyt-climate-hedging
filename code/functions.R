# functions.R: the shared toolbox every script sources
# wait_turn() spaces out requests, download_once() saves a file once, check() stops on bad data,
# save_replies() asks the model once per item and saves each raw reply as one JSON file

library(httr2)                     # sends requests to the NYT and NASA
library(jsonlite)                  # reads and writes JSON, the format the API and the model reply in

# Waiting between requests
last_request_time <- as.POSIXct("1970-01-01", tz = "UTC")   # no request yet

wait_turn <- function(pause) {     # wait until `pause` seconds have passed since the last request
  wait <- pause - as.numeric(difftime(Sys.time(), last_request_time, units = "secs"))
  if (wait > 0) Sys.sleep(wait)
  last_request_time <<- Sys.time()
}

# Downloading a file once
download_once <- function(url, dest, pause = 0) {
  if (file.exists(dest)) return(invisible(FALSE))            # saved already: never download twice
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  wait_turn(pause)
  message("Downloading ", url)
  tmp <- paste0(dest, ".part")                               # a half file never looks finished
  req_perform(req_timeout(request(url), 120), path = tmp)
  file.rename(tmp, dest)
  invisible(TRUE)
}

# Checking
# ok: TRUE where the data is as expected; bad_rows: printed before it stops
check <- function(ok, msg, bad_rows = NULL) {
  if (all(ok)) return(invisible(TRUE))
  if (!is.null(bad_rows)) print(bad_rows[!ok, , drop = FALSE])
  stop("Check failed: ", msg, call. = FALSE)
}

id_to_file <- function(id) gsub("[^A-Za-z0-9]+", "_", id)  # "nyt://article/1a2b" -> "nyt_article_1a2b"

# Saving the model's replies (session 17's save_replies(), with the local model)
# texts, ids: what the model reads, and each item's id; folder: one JSON file per item goes here
# prompt: the system prompt; type: the reply format. Needs MODEL and MODEL_PARAMS (set in 4_label_stories.R)
save_replies <- function(texts, ids, folder, prompt, type) {
  dir.create(folder, recursive = TRUE, showWarnings = FALSE)                # make the folder if it is missing
  for (j in seq_along(texts)) {
    f <- file.path(folder, paste0(id_to_file(ids[j]), ".json"))             # one file per item
    if (file.exists(f)) next                                                # saved already: no call
    chat <- chat_ollama(system_prompt = prompt, model = MODEL, params = MODEL_PARAMS)  # a fresh conversation per item
    t0 <- Sys.time()
    ans <- chat$chat_structured(texts[j], type = type)                      # the call: one answer back
    rec <- list(id = ids[j], answer = ans, model = MODEL,
                seconds = as.numeric(difftime(Sys.time(), t0, units = "secs")),
                reply = chat$last_turn()@json)                              # the reply as the server sent it
    writeLines(toJSON(rec, auto_unbox = TRUE, null = "null"), f)
    if (j %% 25 == 0) message(sprintf("  %s: %d of %d", basename(folder), j, length(texts)))
  }
}