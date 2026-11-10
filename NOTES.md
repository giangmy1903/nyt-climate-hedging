# HW4: How often do climate stories hedge on the science?

## How to run
Open `hw4.Rproj`, then source `code/run_everything.R`.
<!-- TODO (your words): what each of 1-6 does; that a fresh clone without a key only draws the figure -->

## What is where
- `code/`: the scripts, numbered in the order they run; `prompt_climate.txt` and `prompt_hedging.txt`, the two prompts
- `data_clean/`: `stories_per_year.csv` and `labels.csv` (committed)
- `data/`, `replies/`: the NYT months, the sample, my hand-check sheet and every raw model reply (not committed: the NYT's terms)
- `figures/hw4_target.png`

## Stories left after each filter
<!-- TODO: the table 2_clean_stories.R prints (also in data/filter_counts.csv), plus the stories the model called climate -->
| step | stories |
|---|---|
| all items in the archive, Jan 1988 - Oct 2026 | 3,435,087 |
| carry a climate subject tag | 16,516 |
| type_of_material is News | 11,550 |
| not a blog post | 10,410 |
| not a duplicate | 10,395 |
| read by the model (at most 100 a year) | 2,930 |
| the model says climate is the main subject | 1,787 |

## How the scripts find what they read
<!-- TODO (your words, one line each; HW3 lost a point for leaving this out): how each pattern finds what it should, and why it is written that way. All of them are in the scripts' parameter sections -->
- `TAGS`, `TAG_KEEP` (1_download_nyt.R): 
- `FIELDS`, `DOCS_PATH` (1_download_nyt.R): 
- `NEWS_TYPE` (2_clean_stories.R): 
- `BLOG_PATTERN` (2_clean_stories.R): 
- `MIN_CHARS`, the duplicate rule (2_clean_stories.R): 
- `CLIMATE_LABELS`, `WARMING_LABELS` (4_label_stories.R, 5_hand_check.R): 
- `NASA_ANNUAL`, `NASA_MISSING` (6_make_figure.R): 
- `PLOT_IN`, `EVENTS` dx and dy (6_make_figure.R): 

## Checks
<!-- TODO (your words): fill the last column for every row, saying what mistake the check would catch. If you edit a script, update its line numbers -->
| Where | What it checks | The mistake it would catch |
|---|---|---|
| 1_download_nyt.R:28 | the NYT key is set | |
| 1_download_nyt.R:60 | a month already saved is skipped | |
| 1_download_nyt.R:70 | the API returned at least one item for the month | |
| 1_download_nyt.R:82 | all 466 month files exist at the end | |
| 2_clean_stories.R:26 | exactly 466 month files are read | |
| 2_clean_stories.R:49 | every story is dated 1988–2026 | |
| 2_clean_stories.R:53 | every year has at least one tagged news story | |
| 3_hand_sample.R:14 | an existing hand-check sheet is never drawn again | |
| 4_label_stories.R:36 | all 30 hand labels are filled in before the model runs | |
| 4_label_stories.R:59 | every saved reply came from `MODEL` | |
| 4_label_stories.R:61 | every climate answer is yes or no | |
| 4_label_stories.R:62 | every warming answer is fact, uncertain or not stated | |
| 5_hand_check.R:29 | my climate labels are yes or no | |
| 5_hand_check.R:30 | my warming labels are allowed, and empty on "no" stories | |
| 5_hand_check.R:36 | every hand-labelled story has a model label | |
| 6_make_figure.R:83 | stories_per_year.csv has every year | |
| 6_make_figure.R:84 | labels.csv has every year | |
| 6_make_figure.R:100 | NASA has a temperature for every year | |
| 6_make_figure.R:133 | the nameplate image has a gap between its words | |
| 6_make_figure.R:143 | the panels fit in the figure | |
| 6_make_figure.R:164 | no year has more climate stories than the 0-800 axis | |
| 6_make_figure.R:170 | every event label sits above its bar | |
| functions.R:19 | a file already downloaded (NASA, the nameplate) is not downloaded again | |
| functions.R:46 | a story already answered is not sent to the model again | |

## The model
<!-- TODO: model id (qwen3.5:4b-q4_K_M: this laptop has 8 GB of memory, so the 4b file, not the 9b), temperature 0, seed 6850, thinking off; run dates; number of calls; median seconds a call and total hours (4_label_stories.R prints them) -->

## My two questions, word for word
<!-- TODO: paste the final code/prompt_climate.txt and code/prompt_hedging.txt -->

**Question 1 (climate filter):**

**Question 2 (hedging):**

## Hand check
<!-- TODO, from 5_hand_check.R: how many stories; agreement on each question against its base rate; the confusion table; each story the model got wrong (headline, my label, its label, and why I think it missed) -->

## Prompt versions
<!-- TODO: v1, v2, ...: the one thing changed each time, and the agreement with my hand labels -->

## Results
<!-- TODO: what the figure shows in 2-3 sentences, compared with Boykoff & Boykoff (2004) -->
<!-- TODO: one line on the layout: the panel heights (PLOT_IN) and label positions (EVENTS) were measured on the target, so the middle panel is the tallest, as there -->

## AI disclosure
