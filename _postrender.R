# _postrender.R --------------------------------------------------------------
# Runs automatically after every `quarto render`. Registered in _quarto.yml
# under project: post-render.
#
# Two jobs:
#   1. Create docs/.nojekyll, which GitHub Pages needs. Without it, Jekyll
#      ignores folders whose names begin with an underscore, and Quarto
#      generates several of those. The result is a site with no styling.
#      Doing this here means it survives re-renders that clear docs/.
#   2. Warn if the rendered pages reference polyfill.io, a CDN that was sold
#      in 2024 and briefly served malware. This project uses KaTeX to avoid
#      it, but a config change could quietly reintroduce it.

out_dir <- Sys.getenv("QUARTO_PROJECT_OUTPUT_DIR", unset = "docs")

if (!dir.exists(out_dir)) {
  message("post-render: no output directory found at '", out_dir, "', skipping")
} else {

  # 1. .nojekyll
  nojekyll <- file.path(out_dir, ".nojekyll")
  if (!file.exists(nojekyll)) {
    file.create(nojekyll)
    message("post-render: created ", nojekyll)
  }

  # 2. third-party script check
  html_files <- list.files(out_dir, pattern = "\\.html$",
                           recursive = TRUE, full.names = TRUE)

  flagged <- character(0)
  for (f in html_files) {
    txt <- readLines(f, warn = FALSE)
    if (any(grepl("polyfill\\.io", txt, fixed = FALSE))) {
      flagged <- c(flagged, basename(f))
    }
  }

  if (length(flagged)) {
    warning("post-render: polyfill.io referenced in ", length(flagged),
            " file(s): ", paste(head(flagged, 5), collapse = ", "),
            "\n  Check that html-math-method is still set to katex in _quarto.yml.",
            call. = FALSE, immediate. = TRUE)
  } else {
    message("post-render: no polyfill.io references (", length(html_files),
            " HTML files checked)")
  }
}
