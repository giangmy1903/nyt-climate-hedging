# 6_make_figure.R
# Three panels on one time axis, 1988-2026, on a dark background:
#   top:    climate stories per year = tagged news stories x the share the model found to be about climate
#   middle: the share of climate stories that state warming, or its human cause, as uncertain
#   bottom: one cell a year, coloured by NASA's global temperature anomaly, cool to warm
# In:  data_clean/stories_per_year.csv, data_clean/labels.csv, NASA GISTEMP v4 (downloaded once)
# Out: figures/hw4_target.png
# Runs from a fresh clone: no NYT key, no model
# Needs magick (the nameplate image) and ragg (exact colours): install.packages(c("magick", "ragg")) once

source("code/functions.R", local = TRUE)       # download_once(), check()

# Parameters
NASA_URL   <- "https://data.giss.nasa.gov/gistemp/tabledata_v4/GLB.Ts+dSST.csv"
NASA_FILE  <- "data/nasa/GLB.Ts+dSST.csv"
OUT_FILE   <- "figures/hw4_target.png"
PER_YEAR_FILE <- "data_clean/stories_per_year.csv"
LABELS_FILE   <- "data_clean/labels.csv"
CLIMATE_YES   <- "yes"             # the model's labels counted in the top panel...
UNCERTAIN     <- "uncertain"       # ...and in the middle one
NASA_ANNUAL   <- "J-D"             # NASA's column for the January-December mean
NASA_MISSING  <- "***"             # how NASA writes a value not published yet
NASA_SKIP     <- 1                 # the title line above the column names
YEARS      <- 1988:2026
PARTIAL    <- 2026                 # runs to October: marked with a star
X_RANGE    <- c(1987.45, 2026.55)
YEAR_TICKS <- seq(1990, 2025, by = 5)
BAR_HALF   <- 0.38                 # half a bar's width, in years
# The nameplate: no free font matches it, so the image from Wikimedia Commons (public domain as a text logo)
LOGO_URL   <- "https://upload.wikimedia.org/wikipedia/commons/thumb/0/02/The_New_York_Times_Logo.svg/1920px-The_New_York_Times_Logo.svg.png"
LOGO_FILE  <- "data/logo/nyt_nameplate.png"
LOGO_GAP_PX <- 20                  # an empty run of columns this wide ends a word: the first word, "The", is dropped
TITLE_REST <- "climate stories"    # in bold sans after the nameplate
FOOTNOTE   <- sprintf("* %d to date", PARTIAL)
TOP_MAX    <- 800                  # the top axis runs 0-800 in 200s, the middle one counts in 10%, as on the target
TOP_STEP   <- 200
MID_STEP   <- 0.1

# Layout, measured on the target figure: the middle panel is the tallest, the top one next, the strip thin
FIG_IN    <- c(width = 10, height = 10.5)
FIG_DPI   <- 200
TITLE_IN  <- 0.95                                      # the title and the years under it
PLOT_IN   <- c(top = 2.38, middle = 3.38, heat = 0.53) # each panel's plotting area, in inches
MARGIN_IN <- c(bottom = 0.5, left = 1.0, top = 0.5, right = 0.3)   # around each panel: its title and its years
PANEL_TITLE_LINE <- 1.0                                # panel titles sit this many lines above the plot
TOP_HEADROOM <- 1.08                                   # the top axis runs 8% past its highest gridline
MID_HEADROOM <- 1.04
# Text sizes (cex), measured on the target against the first draft
CEX <- c(title_rest = 2.65, subtitle = 1.95, panel_title = 1.3, axis = 1.37, event = 1.42, star = 1.5, footnote = 1.05)
# The title, measured on the target: nameplate width, the space after it, and each part's centre from the top
TITLE_W_IN   <- c(logo = 2.26, gap = 0.1)
TITLE_Y_IN   <- c(logo = 0.43, rest = 0.415, years = 0.79)
ARROW_GAP    <- 0.012                                  # arrows stop this far above the bar, as a share of the axis
PLOT_CENTER <- (MARGIN_IN[["left"]] + (FIG_IN[["width"]] - MARGIN_IN[["left"]] - MARGIN_IN[["right"]]) / 2) /
               FIG_IN[["width"]]                       # the title is centred over the plots, not the page

# Colours, read from the target's pixels
BG         <- "#0c1020"
GRID       <- "#1c2540"
TEXT       <- "#eef0f6"
SUBTEXT    <- "#8b93a7"
ARROW_COL  <- "#a9b0c2"
COUNT_COL  <- "#eef1f7"            # top bars, and the 2026 bar below
COUNT_PART <- "#717682"
SHARE_COL  <- "#f2b234"            # middle bars, and the 2026 bar below
SHARE_PART <- "#735828"
HEAT_COLS  <- c("#2166ac", "#4393c3", "#92c5de", "#d1e5f0", "#f2f0ec",   # cool: blue
                "#fddbc7", "#f4a582", "#d6604d", "#b2182b")              # warm: red

# The five events: an arrow from the label to the top of that year's bar
# dx: how far left of the bar the label ends, in years; y: the label's height on the 0-800 axis. Both measured on the target
EVENTS <- data.frame(
  year  = c(1997, 2007, 2009, 2015, 2021),
  label = c("Kyoto (COP3)", "IPCC AR4", "Copenhagen (COP15)", "Paris (COP21)", "Glasgow (COP26)"),
  dx    = c(2.8, 3.7, 2.75, 2.75, 2.7),
  y     = c(238, 386, 506, 616, 727)
)

# The two CSV files
per_year <- read.csv(PER_YEAR_FILE)          # year, tagged_news
labels   <- read.csv(LABELS_FILE)                    # id, date, climate, warming (NA when not climate)
labels$year <- factor(substr(labels$date, 1, 4), levels = YEARS)
check(YEARS %in% per_year$year, "stories_per_year.csv is missing a year")
check(table(labels$year) > 0, "labels.csv is missing a year: was 4_label_stories.R run with TEST_RUN <- FALSE?")

n_read      <- tapply(labels$id, labels$year, length)                                 # stories the model read
n_climate   <- tapply(labels$climate == CLIMATE_YES, labels$year, sum)                       # ... about climate
n_uncertain <- tapply(labels$warming %in% UNCERTAIN, labels$year, sum)               # ... uncertain
yr <- data.frame(year = YEARS, tagged = per_year$tagged_news[match(YEARS, per_year$year)],
                 n_read = as.vector(n_read), n_climate = as.vector(n_climate), n_uncertain = as.vector(n_uncertain))
yr$climate_stories <- yr$tagged * yr$n_climate / yr$n_read                             # top panel
yr$share_uncertain <- ifelse(yr$n_climate > 0, yr$n_uncertain / yr$n_climate, 0)       # middle panel

# NASA: the annual mean is column J-D; 2026 is not over, so its J-D is "***" (missing):
# the mean of the months published so far stands in
download_once(NASA_URL, NASA_FILE)
nasa <- read.csv(NASA_FILE, skip = NASA_SKIP, na.strings = NASA_MISSING, check.names = FALSE)
nasa$anomaly <- ifelse(is.na(nasa[[NASA_ANNUAL]]), rowMeans(nasa[, month.abb], na.rm = TRUE), nasa[[NASA_ANNUAL]])
yr$anomaly <- nasa$anomaly[match(YEARS, nasa$Year)]
check(!is.na(yr$anomaly), "NASA has no temperature for a year", yr)
print(yr, row.names = FALSE)

# Drawing helpers
empty_panel <- function(ylim, ticks, tick_labels, title) {      # gridlines, y labels, year axis, title
  plot(NA, xlim = X_RANGE, ylim = ylim, axes = FALSE, xlab = "", ylab = "", xaxs = "i", yaxs = "i")
  abline(v = YEAR_TICKS, h = ticks, col = GRID, lwd = 1)
  axis(2, at = ticks, labels = tick_labels, las = 1, tick = FALSE, col.axis = SUBTEXT, cex.axis = CEX[["axis"]])
  axis(1, at = YEAR_TICKS, tick = FALSE, col.axis = SUBTEXT, cex.axis = CEX[["axis"]], line = -0.2)
  mtext(title, side = 3, line = PANEL_TITLE_LINE, col = TEXT, font = 2, cex = CEX[["panel_title"]])
}

draw_bars <- function(values, col, col_partial, ylim) {         # one bar a year; 2026 dimmed, with a star
  cols <- ifelse(YEARS == PARTIAL, col_partial, col)
  keep <- values > 0
  rect(YEARS[keep] - BAR_HALF, 0, YEARS[keep] + BAR_HALF, values[keep], col = cols[keep], border = NA)
  text(PARTIAL, values[YEARS == PARTIAL] + 0.035 * diff(ylim), "*", col = TEXT, cex = CEX[["star"]], font = 2)
}

curved_arrow <- function(x0, y0, x1, y1) {                       # leaves the label going right, lands on the bar going down
  t <- seq(0, 1, length.out = 60)
  x <- (1 - t)^2 * x0 + 2 * (1 - t) * t * x1 + t^2 * x1          # a curve bent towards the point (x1, y0)
  y <- (1 - t)^2 * y0 + 2 * (1 - t) * t * y0 + t^2 * y1
  lines(x, y, col = ARROW_COL, lwd = 1.3)
  arrows(x[58], y[58], x[60], y[60], col = ARROW_COL, lwd = 1.3, length = 0.08)   # the head, on the last step
}

# The nameplate: downloaded once; drop the first word, trim the empty edges, recolour it to the title colour
download_once(LOGO_URL, LOGO_FILE)
logo  <- magick::image_trim(magick::image_read(LOGO_FILE))
ink   <- colSums(as.integer(magick::image_data(logo, "rgba"))[, , 4]) > 0    # columns with any ink (alpha > 0)
runs  <- rle(ink)
words <- which(!runs$values & runs$lengths >= LOGO_GAP_PX)                     # the gaps between words
check(length(words) >= 1, "the nameplate image has no gap between words: is LOGO_URL still the nameplate?")
cut   <- sum(runs$lengths[seq_len(words[1])])                                  # the columns up to the end of the first gap
logo  <- magick::image_trim(magick::image_crop(logo, sprintf("%dx%d+%d+0", length(ink) - cut,
                                                              magick::image_info(logo)$height, cut)))
logo  <- magick::image_colorize(logo, 100, TEXT)
logo_h_in <- TITLE_W_IN[["logo"]] * magick::image_info(logo)$height / magick::image_info(logo)$width

# Draw: each panel's row is its plot plus the margins above and below; the footnote takes what is left
rows_in <- c(TITLE_IN, PLOT_IN + MARGIN_IN[["bottom"]] + MARGIN_IN[["top"]])
rows_in <- c(rows_in, FIG_IN[["height"]] - sum(rows_in))
check(rows_in > 0, "the panels are taller than the figure: lower PLOT_IN or TITLE_IN")
dir.create(dirname(OUT_FILE), showWarnings = FALSE)
ragg::agg_png(OUT_FILE, width = FIG_IN[["width"]], height = FIG_IN[["height"]], units = "in", res = FIG_DPI,
              background = BG)                         # ragg keeps the colours exact; the Mac's png() shifts them
layout(matrix(1:5, ncol = 1), heights = rows_in)        # title, three panels, footnote
par(bg = BG, family = "sans", col = TEXT)

# Title: the nameplate image, then the rest in bold sans, centred together over the plots
par(mar = c(0, 0, 0, 0))
plot.new()                                                       # x and y run 0-1 across this row
to_y <- function(in_from_top) 1 - in_from_top / TITLE_IN
w_logo <- TITLE_W_IN[["logo"]] / FIG_IN[["width"]]
w_gap  <- TITLE_W_IN[["gap"]] / FIG_IN[["width"]]
w_rest <- strwidth(TITLE_REST, cex = CEX[["title_rest"]], font = 2)
x0 <- PLOT_CENTER - (w_logo + w_gap + w_rest) / 2
h_logo <- logo_h_in / TITLE_IN
rasterImage(as.raster(logo), x0, to_y(TITLE_Y_IN[["logo"]]) - h_logo / 2, x0 + w_logo, to_y(TITLE_Y_IN[["logo"]]) + h_logo / 2)
text(x0 + w_logo + w_gap, to_y(TITLE_Y_IN[["rest"]]), TITLE_REST, adj = 0, cex = CEX[["title_rest"]], font = 2)
text(PLOT_CENTER, to_y(TITLE_Y_IN[["years"]]), sprintf("%d–%d", min(YEARS), max(YEARS)), cex = CEX[["subtitle"]])

# Top: climate stories per year, with the five events
check(max(yr$climate_stories) <= TOP_MAX, "a year has more climate stories than TOP_MAX: raise it")
top_ticks <- seq(0, TOP_MAX, by = TOP_STEP)
top_ylim  <- c(0, max(top_ticks) * TOP_HEADROOM)
par(mai = MARGIN_IN)
empty_panel(top_ylim, top_ticks, top_ticks, "Climate stories per year")
draw_bars(yr$climate_stories, COUNT_COL, COUNT_PART, top_ylim)
check(EVENTS$y > yr$climate_stories[match(EVENTS$year, yr$year)], "an event label sits below its bar: raise its y", EVENTS)
for (i in seq_len(nrow(EVENTS))) {
  bar <- yr$climate_stories[yr$year == EVENTS$year[i]]
  lx  <- EVENTS$year[i] - EVENTS$dx[i]                           # where the label ends
  ly  <- EVENTS$y[i]
  text(lx, ly, EVENTS$label[i], adj = c(1, 0.5), cex = CEX[["event"]])
  curved_arrow(lx + 0.25, ly, EVENTS$year[i], bar + ARROW_GAP * diff(top_ylim))
}

# Middle: share uncertain
mid_top   <- max(MID_STEP, ceiling(max(yr$share_uncertain) / MID_STEP) * MID_STEP)   # up to the next 10%
mid_ticks <- seq(0, mid_top, by = MID_STEP)
mid_ylim  <- c(0, mid_top * MID_HEADROOM)
empty_panel(mid_ylim, mid_ticks, paste0(round(mid_ticks * 100), "%"),
            "Share of stories that call warming, or its human cause, uncertain")
draw_bars(yr$share_uncertain, SHARE_COL, SHARE_PART, mid_ylim)

# Bottom: one cell a year, from the coolest year (blue) to the warmest (red)
plot(NA, xlim = X_RANGE, ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "", xaxs = "i", yaxs = "i")
scaled   <- (yr$anomaly - min(yr$anomaly)) / diff(range(yr$anomaly))   # 0 coolest, 1 warmest
heat_col <- rgb(colorRamp(HEAT_COLS)(scaled), maxColorValue = 255)
rect(YEARS - 0.5, 0, YEARS + 0.5, 1, col = heat_col, border = heat_col)
axis(1, at = YEAR_TICKS, tick = FALSE, col.axis = SUBTEXT, cex.axis = CEX[["axis"]], line = -0.2)
mtext("Global temperature anomalies (NASA)", side = 3, line = PANEL_TITLE_LINE, col = TEXT, font = 2,
      cex = CEX[["panel_title"]])

# Footnote
par(mai = c(0, MARGIN_IN[["left"]], 0, MARGIN_IN[["right"]]))
plot(NA, xlim = X_RANGE, ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "", xaxs = "i", yaxs = "i")
text(X_RANGE[2], 0.5, FOOTNOTE, adj = 1, col = SUBTEXT, cex = CEX[["footnote"]])

invisible(dev.off())
message("Figure written to ", OUT_FILE)