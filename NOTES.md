# HW4: How often do climate stories hedge on the science?

## How to run
Open `hw4.Rproj`, then source `code/run_everything.R`.
1. Pull the NYT data, 1 file per month, needs a key in ~/.Renviron, keeps only stories with 4 climate tags
2. Decided which stories to keep -> keep news only, no blogs, no duplicates, count new stories per year, and draw stories randomly, drew at most 100 a year
3. Picked 30 stories randomly for hand labelling, before the model runs, so seeing the answers first pull labels towards them
4. This run needs ollama pull qwen3.5:4b-q4_K_M, it asks the model 2 questions on climate? fact/uncertain/not stated? per story
5. Compared the 30 hand-labeled stories with the models, print agreement, base rate, confusion table, and disagreement
6. Combined stories, labels, NASA temp, NYT's logo image to produce the figure

Packages used: httr2, jsonlite, ellmer, magick, ragg
No key: if NYT_KEY is empty, and labels file exist, it runs only script 6

## What is where
- `code/`: run 1 to 6; `prompt_climate.txt` and `prompt_hedging.txt`, the two prompts
- `data_clean/`: `stories_per_year.csv` and `labels.csv` (committed)
- `data/`, `replies/`: the NYT months, the sample, my hand-check sheet and every raw model reply (not committed: the NYT's terms)
- `figures/hw4_target.png`

## Stories left after each filter
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
- `TAGS`, `TAG_KEEP` (1_download_nyt.R): TAGS = “Global Warming”, “Greenhouse Effect”, “Greenhouse Gas Emissions”, “United Nations Framework Convention on Climate Change”; TAG_KEEP = “subject”
- `FIELDS`, `DOCS_PATH` (1_download_nyt.R): FIELDS = _id, pub_date, headline → main, abstract, lead_paragraph, snippet, type_of_material, web_url; D0CS_PATH = response to doc
- `NEWS_TYPE` (2_clean_stories.R):"News"
- `BLOG_PATTERN` (2_clean_stories.R): blogs\.nytimes\.com|/blogs/
- `MIN_CHARS`, the duplicate rule (2_clean_stories.R): min char is 20
- `CLIMATE_LABELS`, `WARMING_LABELS` (4_label_stories.R, 5_hand_check.R): CLIMATE_LABELS = yes / no; WARMING_LABELS = fact / uncertain / not stated
- `NASA_ANNUAL`, `NASA_MISSING` (6_make_figure.R): NASA_ANNUAL = “J-D”; NASA_MISSING = “***”
- `PLOT_IN`, `TOP_MAX` = 800 `EVENTS` dx and y (6_make_figure.R)
- `LOGO_URL`No free font matched, so used the logo image 

## Checks
| Where | What it checks | The mistake it would catch |
|---|---|---|
| 1_download_nyt.R:28 | the NYT key is set | without the key, the requests fail |
| 1_download_nyt.R:60 | a month already saved is skipped | f a run stopped at month 200, rerunning all 466 again, wasting time and exceed 500 request limit |
| 1_download_nyt.R:70 | the API returned at least one item for the month | a wrong key could return an empty month, quitely making that month shows 0 story |
| 1_download_nyt.R:82 | all 466 month files exist at the end | a crash would leave some months missing |
| 2_clean_stories.R:26 | exactly 466 month files are read | catches a download that hasn't done |
| 2_clean_stories.R:49 | every story is dated 1988–2026 | catches a date that is read wrongly that could put the story in the wrong year |
| 2_clean_stories.R:53 | every year has at least one tagged news story | this could be the mistake i made since there's empty bar in the bottom target figure, i mistook labelling this for year wth 0 story  |
| 3_hand_sample.R:14 | an existing hand-check sheet is never drawn again | rerun the pipeline would draw 30 new stories and delete my hand labels |
| 4_label_stories.R:36 | all 30 hand labels are filled in before the model runs | strop the model from running before i finished labelling the story |
| 4_label_stories.R:59 | every saved reply came from `MODEL` | switched model but keep the prompt version  |
| 4_label_stories.R:61 | every climate answer is yes or no | reply |
| 4_label_stories.R:62 | every warming answer is fact, uncertain or not stated | reply |
| 5_hand_check.R:29 | my climate labels are yes or no | disagreement |
| 5_hand_check.R:30 | my warming labels are allowed, and empty on "no" stories | disagreement |
| 5_hand_check.R:36 | every hand-labelled story has a model label | silently drop story |
| 6_make_figure.R:83 | stories_per_year.csv has every year | would have been able to catcj figure drawn from the 30 story test run or missing year, but it didn't turn out right ... |
| 6_make_figure.R:84 | labels.csv has every year |same as above  |
| 6_make_figure.R:100 | NASA has a temperature for every year |catch NASA that hasn't had a year, like 2026, making a cell blank  |
| 6_make_figure.R:133 | the nameplate image has a gap between its words | drop the first word could cut the wrong part of the logo |
| 6_make_figure.R:143 | the panels fit in the figure | make sure that the panel not destroy the figure when being shrink or enlarged  |
| 6_make_figure.R:164 | no year has more climate stories than the 0-800 axis | a future year with more than 800 would be cut off at the top of the axis |
| 6_make_figure.R:170 | every event label sits above its bar | a label sitting on or below its bar would be unreadable|
| functions.R:19 | a file already downloaded (NASA, the nameplate) is not downloaded again | rerunning downloads NASA’s file and the nameplate every time |
| functions.R:46 | a story already answered is not sent to the model again |rerunning sends all 4,717 questions to the model again,  wasting another 4 hours, and the answers would change |

## The model
I used qwen3.5:4b-q4_K_M via Ollama: 4b because my laptop has only 8 GB of memory
temp 0, seed 6850, thinking off reasoning_effort = none
one fresh conversation per story, a structured reply per conversation
run on Nov 9-10, 2026, 22:03 - 2:07, a total of 4,717 calls = 2,930 climate questions + 1,787 hedging questions
median 2.9s per call, 4 hours in total
the test runs were slower (8 to 15s per call) as there were many Google Chrome tabs opened :) 

## My two questions, word for word

**Question 1 (climate filter):** You read the headline, summary and first paragraph of one New York Times news story.
yes: the story's main subject is climate change: global warming, the greenhouse gases that cause it, or the science, treaties, policies or damage tied to it.
no: climate change comes up only in passing in a story mainly about something else, such as energy prices, an election, a business deal or one day's weather. 

**Question 2 (hedging):** You read the headline, summary and first paragraph of one New York Times news story about climate change.
Judge only two claims: that the Earth is warming, and that people are causing that warming.
First copy into quote the story's words about warming or its cause, or leave it empty.
fact: the story states the warming or its human cause as established, in the reporter's own voice or by citing scientists without doubt.
uncertain: the story presents the warming or its human cause as unsettled, with words such as predict, believe, may, could, might, theory or possible, or it gives doubters equal weight.
not stated: the story says nothing about whether the Earth is warming or why.
Rules for the cases in between:
- Doubt about the effects of warming, its costs, or a treaty or policy does not count: label the story by what it says about the warming itself.
- A story that reports doubters but states the science as settled: fact.
- A forecast that burning fossil fuels may warm the planet, with no statement that it is warming now: uncertain.
- uncertain needs words in quote that hedge on the warming itself or its human cause; if quote is empty or hedges only on something else, the label is fact or not stated.
Give exactly one label.

** The hedging prompt’s last rule is the v2 addition

## Hand check
handchecked 30 stories
v1	v2 (final)	Base rate
Q1: climate is the main subject? (30 stories)	0.77	0.77	0.67, always “yes”
Q2: fact / uncertain / not stated (16 stories)	0.38	0.44	0.56, always “fact”
Final v2 Q2 confusion table (rows determined by me, columns by the model):
fact: 2 / 1 / 6 (fact / not stated / uncertain)
not stated: 0 / 3 / 1
uncertain: 1 / 0 / 2
The main error: I said “fact” and the model said “uncertain”, 6 times :)
All 16 disagreements are in data/final_hand_check.txt.

## Prompt versions
there was one change from v1 -> v2 by adding the rule "uncertain needs words in quote that hedge on the warming itself"
result: q2 went from 0.38 to 0.44; however, the model still said "uncertain" 9 times, 4 of them with an empty quote so the model just ignored the rule

## Results
top panel: spikes at Kyoto 1997, 2007 IPCC AR4, Copenhagen 2009, Paris 2015 and Glasgow 2021 (tallest, ~500)
uncertain: 59% in 1988-1997, 40% in 1998-2006, 30% in 2007-2026
the decline matches Boykoff & Boykoff story about balanced reporting raises doubt more substantially in the early years, then declined but the level is different from the target, because Q2 doesn't perfom well up to the base rate and the model overcalls "uncertain"

## AI disclosure
Claude opus 5.5
Claude helped me write and debug scripts, fixed the produced figure to match target figure, logged my project progress
I labeled the 30 stories, chose v2, evaluated produced vs. target figure, judged the disagreements, wrote the notes
