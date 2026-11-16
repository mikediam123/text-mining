# _prerender.R ---------------------------------------------------------------
# Runs automatically before every `quarto render`. Registered in _quarto.yml
# under project: pre-render.
#
# The rendered site (docs/) and cached results (_freeze/) are committed and
# published, so they must only ever come from the SYNTHETIC data. This script
# stops the render, before anything is written, unless data/vcu_cares_long.csv
# was built from sample-data/vcu_cares_synthetic.xlsx.
#
# R/01-prep-data.R records a fingerprint (an MD5 checksum) of the workbook it
# read in data/source-md5.txt. If that fingerprint does not match the synthetic
# workbook, the data came from somewhere else, and the render is refused.

synthetic <- "sample-data/vcu_cares_synthetic.xlsx"
stamp     <- "data/source-md5.txt"

expected <- unname(tools::md5sum(synthetic))
recorded <- if (file.exists(stamp)) readLines(stamp, warn = FALSE)[1] else NA

if (is.na(recorded)) {
  stop("pre-render: can't tell which workbook built data/vcu_cares_long.csv.\n",
       "  Run  Rscript R/01-prep-data.R  (with no path) and render again.",
       call. = FALSE)
}

if (!identical(recorded, expected)) {
  stop("pre-render: data/vcu_cares_long.csv was NOT built from the synthetic workbook.\n",
       "  The rendered site is published, so it must never contain real responses.\n",
       "  Run  Rscript R/01-prep-data.R  (with no path) and render again.\n",
       "  Analyze real data in a separate folder outside this project.",
       call. = FALSE)
}

message("pre-render: data built from the synthetic workbook, OK to render")
