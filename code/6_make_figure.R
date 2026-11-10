# 6_make_figure.R
# Three panels on one time axis, 1988-2026, on a dark background:
#   top:    climate stories per year = tagged news stories x the share the model found to be about climate
#   middle: the share of climate stories that state warming, or its human cause, as uncertain
#   bottom: one cell a year, coloured by NASA's global temperature anomaly, cool to warm
# In:  data_clean/stories_per_year.csv, data_clean/labels.csv, NASA GISTEMP v4 (downloaded once)
# Out: figures/hw4_target.png
# Runs from a fresh clone: no NYT key, no model

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

# Layout, measured on the target figure: the middle panel is the tallest, the top one next, the strip thin
FIG_IN    <- c(width = 10, height = 10.5)
FIG_DPI   <- 200
TITLE_IN  <- 0.95                                      # the title and the years under it
PLOT_IN   <- c(top = 2.38, middle = 3.38, heat = 0.53) # each panel's plotting area, in inches
MARGIN_IN <- c(bottom = 0.5, left = 1.0, top = 0.5, right = 0.3)   # around each panel: its title and its years
PANEL_TITLE_LINE <- 1.0                                # panel titles sit this many lines above the plot
TOP_HEADROOM <- 1.08                                   # the top axis runs 8% past its highest gridline
MID_HEADROOM <- 1.04

# Colours
BG         <- "#0b1020"
GRID       <- "#1c2540"
TEXT       <- "#eef0f6"
SUBTEXT    <- "#8b93a7"
ARROW_COL  <- "#a9b0c2"
COUNT_COL  <- "#eef0f6"            # top bars, and the 2026 bar below
COUNT_PART <- "#767b8c"
SHARE_COL  <- "#f0b135"            # middle bars, and the 2026 bar below
SHARE_PART <- "#6e5626"
HEAT_COLS  <- c("#2166ac", "#4393c3", "#92c5de", "#d1e5f0", "#f2f0ec",   # cool: blue
                "#fddbc7", "#f4a582", "#d6604d", "#b2182b")              # warm: red

# The five events: an arrow from the label to the top of that year's bar
# dx: how far left of the bar the label ends, in years; dy: how far above the bar it sits, as a share of the axis
EVENTS <- data.frame(
  year  = c(1997, 2007, 2009, 2015, 2021),
  label = c("Kyoto (COP3)", "IPCC AR4", "Copenhagen (COP15)", "Paris (COP21)", "Glasgow (COP26)"),
  dx    = c(2.8, 3.7, 2.75, 2.75, 2.7),         # measured on the target
  dy    = c(0.18, 0.175, 0.32, 0.37, 0.06)
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
  axis(2, at = ticks, labels = tick_labels, las = 1, tick = FALSE, col.axis = SUBTEXT, cex.axis = 1.05)
  axis(1, at = YEAR_TICKS, tick = FALSE, col.axis = SUBTEXT, cex.axis = 1.05, line = -0.2)
  mtext(title, side = 3, line = PANEL_TITLE_LINE, col = TEXT, font = 2, cex = 1.2)
}

draw_bars <- function(values, col, col_partial, ylim) {         # one bar a year; 2026 dimmed, with a star
  cols <- ifelse(YEARS == PARTIAL, col_partial, col)
  keep <- values > 0
  rect(YEARS[keep] - BAR_HALF, 0, YEARS[keep] + BAR_HALF, values[keep], col = cols[keep], border = NA)
  text(PARTIAL, values[YEARS == PARTIAL] + 0.035 * diff(ylim), "*", col = TEXT, cex = 1.5, font = 2)
}

curved_arrow <- function(x0, y0, x1, y1) {                       # leaves the label going right, lands on the bar going down
  t <- seq(0, 1, length.out = 60)
  x <- (1 - t)^2 * x0 + 2 * (1 - t) * t * x1 + t^2 * x1          # a curve bent towards the point (x1, y0)
  y <- (1 - t)^2 * y0 + 2 * (1 - t) * t * y0 + t^2 * y1
  lines(x, y, col = ARROW_COL, lwd = 1.3)
  arrows(x[58], y[58], x[60], y[60], col = ARROW_COL, lwd = 1.3, length = 0.08)   # the head, on the last step
}

# Draw: each panel's row is its plot plus the margins above and below; the footnote takes what is left
rows_in <- c(TITLE_IN, PLOT_IN + MARGIN_IN[["bottom"]] + MARGIN_IN[["top"]])
rows_in <- c(rows_in, FIG_IN[["height"]] - sum(rows_in))
check(rows_in > 0, "the panels are taller than the figure: lower PLOT_IN or TITLE_IN")
dir.create(dirname(OUT_FILE), showWarnings = FALSE)
png(OUT_FILE, width = FIG_IN[["width"]], height = FIG_IN[["height"]], units = "in", res = FIG_DPI, bg = BG)
layout(matrix(1:5, ncol = 1), heights = rows_in)        # title, three panels, footnote
par(bg = BG, family = "sans", col = TEXT)

# Title: "New York Times" in a serif face, the rest in sans, centred together
par(mar = c(0, 0, 0, 0))
plot.new()
w1 <- strwidth("New York Times", cex = 2.3, font = 2, family = "serif")
w2 <- strwidth(" climate stories", cex = 2.3, font = 2, family = "sans")
x0 <- 0.5 - (w1 + w2) / 2
text(x0, 0.56, "New York Times", adj = 0, cex = 2.3, font = 2, family = "serif")
text(x0 + w1, 0.56, " climate stories", adj = 0, cex = 2.3, font = 2, family = "sans")
text(0.5, 0.17, sprintf("%d–%d", min(YEARS), max(YEARS)), cex = 1.5)

# Top: climate stories per year, with the five events
top_ticks <- pretty(c(0, max(yr$climate_stories) * 1.12), n = 4)
top_ylim  <- c(0, max(top_ticks) * TOP_HEADROOM)
par(mai = MARGIN_IN)
empty_panel(top_ylim, top_ticks, top_ticks, "Climate stories per year")
draw_bars(yr$climate_stories, COUNT_COL, COUNT_PART, top_ylim)
for (i in seq_len(nrow(EVENTS))) {
  bar <- yr$climate_stories[yr$year == EVENTS$year[i]]
  lx  <- EVENTS$year[i] - EVENTS$dx[i]                           # where the label ends
  ly  <- bar + EVENTS$dy[i] * diff(top_ylim)
  text(lx, ly, EVENTS$label[i], adj = c(1, 0.5), cex = 1.0)
  curved_arrow(lx + 0.25, ly, EVENTS$year[i], bar + 0.025 * diff(top_ylim))
}

# Middle: share uncertain
mid_top   <- max(0.1, ceiling(max(yr$share_uncertain) * 10) / 10)   # up to the next 10%
mid_ticks <- seq(0, mid_top, by = 0.1)
mid_ylim  <- c(0, mid_top * MID_HEADROOM)
empty_panel(mid_ylim, mid_ticks, paste0(round(mid_ticks * 100), "%"),
            "Share of stories that call warming, or its human cause, uncertain")
draw_bars(yr$share_uncertain, SHARE_COL, SHARE_PART, mid_ylim)

# Bottom: one cell a year, from the coolest year (blue) to the warmest (red)
plot(NA, xlim = X_RANGE, ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "", xaxs = "i", yaxs = "i")
scaled   <- (yr$anomaly - min(yr$anomaly)) / diff(range(yr$anomaly))   # 0 coolest, 1 warmest
heat_col <- rgb(colorRamp(HEAT_COLS)(scaled), maxColorValue = 255)
rect(YEARS - 0.5, 0, YEARS + 0.5, 1, col = heat_col, border = heat_col)
axis(1, at = YEAR_TICKS, tick = FALSE, col.axis = SUBTEXT, cex.axis = 1.05, line = -0.2)
mtext("Global temperature anomalies (NASA)", side = 3, line = PANEL_TITLE_LINE, col = TEXT, font = 2, cex = 1.2)

# Footnote
par(mai = c(0, MARGIN_IN[["left"]], 0, MARGIN_IN[["right"]]))
plot(NA, xlim = X_RANGE, ylim = c(0, 1), axes = FALSE, xlab = "", ylab = "", xaxs = "i", yaxs = "i")
text(X_RANGE[2], 0.5, sprintf("* %d to date (to October)", PARTIAL), adj = 1, col = SUBTEXT, cex = 0.85)
text(X_RANGE[1], 0.5, "Sources: NYT Archive API; labels by qwen3.5 via Ollama; NASA GISTEMP v4",
     adj = 0, col = SUBTEXT, cex = 0.85)

invisible(dev.off())
message("Figure written to ", OUT_FILE)