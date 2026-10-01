# Build the analysis file used by every chapter.
#
# By default this reads the SYNTHETIC workbook that ships with the repo, so the
# book builds for anyone. The real VCU CARES workbook has the same layout.
#
# Input : sample-data/vcu_cares_synthetic.xlsx   (default; synthetic, safe to share)
#         or pass a path to a workbook with the same layout, e.g. the real one:
#         Rscript R/01-prep-data.R data/raw/vcu_cares.xlsx   (never commit this file)
# Output: data/vcu_cares_long.csv   (derived; gitignored)
#
# One row per student answer. The three source sheets are stacked into a
# single long table. Demographics (major, GPA, gender, race/ethnicity) are
# dropped on purpose: no chapter needs them, and the less identifying
# information we carry around, the better.
#
# Run from the project root:  Rscript R/01-prep-data.R

library(tidyverse)
library(readxl)

args <- commandArgs(trailingOnly = TRUE)
raw  <- if (length(args)) args[1] else "sample-data/vcu_cares_synthetic.xlsx"
if (!file.exists(raw)) {
  stop("Can't find ", raw, ". Run from the project root, or pass the path to a workbook.",
       call. = FALSE)
}
dir.create("data", showWarnings = FALSE)

clean_level <- function(x) {
  x <- str_to_lower(str_squish(x))
  case_when(
    str_detect(x, "^undergrad") ~ "Undergraduate",
    str_detect(x, "^grad")      ~ "Graduate",
    str_detect(x, "professional") ~ "Professional",
    TRUE ~ NA_character_
  )
}

# ---- Sheet 1: the original form -------------------------------------------
# Columns are positional: level, strength text, 19 topic checkboxes,
# concern text, 19 topic checkboxes, idea text. The second set of checkbox
# columns repeats the first set's names with ".1" appended.
orig <- read_excel(raw, sheet = "Original Form", .name_repair = "minimal")

tag_names <- function(cols) {
  names(orig)[cols] |>
    str_remove("^.* - ") |>
    str_remove("(\\.1|\\.\\.\\.\\d+)$") |>
    str_squish() |>
    str_remove(" \\(.*\\)$")
}

collapse_tags <- function(cols) {
  nm <- tag_names(cols)
  m  <- !is.na(as.matrix(orig[cols]))
  keep <- nm != "None"
  apply(m[, keep, drop = FALSE], 1, \(r) {
    t <- nm[keep][r]
    if (length(t)) paste(t, collapse = "; ") else NA_character_
  })
}

orig_long <- bind_rows(
  tibble(question = "strength", text = orig[[2]],  topics = collapse_tags(3:21)),
  tibble(question = "concern",  text = orig[[22]], topics = collapse_tags(23:41)),
  tibble(question = "idea",     text = orig[[42]], topics = NA_character_)
) |>
  mutate(
    respondent = rep(seq_len(nrow(orig)), 3),
    level      = rep(clean_level(orig[[1]]), 3),
    source     = "original",
    event      = NA_character_
  )

# ---- Sheets 2 and 3: event-based forms -------------------------------------
# These have positive / negative / idea columns and no topic checkboxes.
# On the "Second Process" sheet the Date and Event headers are swapped
# (Date holds the event name), so we rename by position.
second <- read_excel(raw, sheet = "Second Process") |>
  transmute(event = Date, level = clean_level(Status),
            strength = `VCU: Positive Experience`,
            concern  = `VCU: Negative Experience`,
            idea     = `Ideas/Changes`, source = "second")

paper <- read_excel(raw, sheet = "Found Paper Forms") |>
  transmute(event = Event, level = clean_level(Status),
            strength = `VCU: Positive Experience`,
            concern  = `VCU: Negative Experience`,
            idea     = `Ideas/Changes`, source = "paper")

event_long <- bind_rows(second, paper) |>
  mutate(respondent = row_number() + nrow(orig)) |>
  pivot_longer(c(strength, concern, idea),
               names_to = "question", values_to = "text") |>
  mutate(topics = NA_character_)

# ---- Stack and write --------------------------------------------------------
vcu <- bind_rows(orig_long, event_long) |>
  mutate(
    resp_id = respondent,
    text    = str_squish(as.character(text)),
    text    = na_if(text, ""),
    question = factor(question, levels = c("strength", "concern", "idea"))
  ) |>
  filter(!is.na(text)) |>
  arrange(resp_id, question) |>
  mutate(doc_id = row_number()) |>
  select(doc_id, resp_id, source, event, level, question, text, topics)

write_csv(vcu, "data/vcu_cares_long.csv", na = "")
message("Wrote ", nrow(vcu), " answers from ", n_distinct(vcu$resp_id),
        " respondents to data/vcu_cares_long.csv")
