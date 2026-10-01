# Shared setup for every chapter. Each chapter starts with
#   source("R/helpers.R")
# so that the data loading and cleaning rules live in exactly one place.

suppressPackageStartupMessages(library(tidyverse))

# Course palette (same teal as the EDUS 664 book)
vcu_teal  <- "#1a7a6e"
vcu_gold  <- "#c9972b"
vcu_dark  <- "#1a2e2b"

theme_set(theme_minimal(base_size = 13) +
            theme(plot.title.position = "plot",
                  panel.grid.minor = element_blank()))
update_geom_defaults("bar", list(fill = vcu_teal))
update_geom_defaults("col", list(fill = vcu_teal))

# Answers that carry no content. Chapter 1 shows how we found these.
placeholder_pattern <- paste0(
  "^(none|n/?a|na|nothing|no concerns?|no answers?( given)?|no response|",
  "not sure|test|testing form|f|did not respond|i don'?t know|doesn'?t know|",
  "don'?t have any|none right now|nothing right now|nothing yet)[.!\\s]*$"
)

# Read the long file written by R/01-prep-data.R.
#   clean = FALSE keeps the placeholder answers (used in Chapter 1).
load_vcu <- function(path = "data/vcu_cares_long.csv", clean = TRUE) {
  if (!file.exists(path)) {
    stop("Can't find ", path, ". Run  Rscript R/01-prep-data.R  from the project root ",
         "first. See SETUP.md.", call. = FALSE)
  }
  # na = "" so that an answer that is literally the text "NA" is kept as text
  d <- readr::read_csv(path, na = "", show_col_types = FALSE) |>
    mutate(
      question = factor(question, levels = c("strength", "concern", "idea")),
      # Curly apostrophes (it's) would not match the straight ones in stop-word
      # lists, so "don't" would survive stop-word removal. Straighten them.
      text = str_replace_all(text, "[\u2018\u2019]", "'")
    )
  if (clean) {
    d <- d |> filter(!str_detect(str_to_lower(str_squish(text)), placeholder_pattern))
  }
  d
}
