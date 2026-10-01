# Setup and Publishing Guide

## Before you start

You need R, RStudio, and Quarto (bundled with recent RStudio; check with `quarto --version` in the Terminal tab). Install the packages once:

```r
install.packages(c(
  "tidyverse", "readxl", "tidytext", "topicmodels", "stm",
  "glmnet", "ggraph", "igraph", "rsample"
))
```

`topicmodels` needs the GNU Scientific Library on some Linux systems (`libgsl-dev`).

## Step 1: Put the data in place

The data are deliberately not in the repository. Get `ICRE Data _VCU Cares Final.xlsx` from the lab's secure storage and save it as:

```
data/raw/vcu_cares.xlsx
```

(Create the folders if they do not exist. `data/` is in `.gitignore`.)

**No access to the real data?** Skip this step and use the synthetic sample that ships with the repository instead (`sample-data/`). It has the same structure and size, but the text is invented; see `sample-data/README.md` for what it can and cannot be used for.

## Step 2: Build the analysis file

From the project root, in the Terminal tab:

```bash
Rscript R/01-prep-data.R
```

or, for the synthetic sample:

```bash
Rscript R/01-prep-data.R sample-data/vcu_cares_synthetic.xlsx
```

This stacks the workbook's three sheets into one long table, `data/vcu_cares_long.csv`, with one row per answer. It drops demographics (major, GPA, gender, race/ethnicity) because no chapter uses them. It should report about 3,600 to 3,700 answers from about 1,240 respondents (the real data and the synthetic sample are both close to this).

If a chapter stops with "Can't find data/vcu_cares_long.csv", you skipped this step.

## Step 3: Render

Open `TextMining.Rproj`, then either click **Render Book** in the Build pane, or run `quarto render` in the Terminal. To work on one chapter, run its chunks interactively in RStudio first; it is much easier than debugging a whole-book render.

Chapters 4 and 5 (topic models) were drafted without access to `topicmodels` and `stm`. Expect to proofread them on the first run.

## Publishing: decide this before you commit `docs/`

The MLM book commits `docs/` and serves it with GitHub Pages. That works because its data are public course datasets. Here the rendered pages and the `_freeze/` cache contain **verbatim student quotes**, so this repository ignores both by default.

Options:

1. **Keep it local.** Render on your machine and share the HTML folder with lab members directly. Nothing student-derived touches GitHub. This is the default.
2. **Private repo plus Pages.** Remove `/docs/` and `/_freeze/` from `.gitignore`. GitHub Pages from a *private* repo requires a paid plan, and you should confirm the site's visibility is restricted to people with repo access.
3. **Public site.** Only after the quotes have been reviewed for identifiability and your approvals allow it. Consider replacing `text` columns in displayed output with aggregates.

The `_postrender.R` script creates `docs/.nojekyll` automatically, as in the MLM book.

## Updating the site

```bash
git add .
git commit -m "Describe your change"
git push
```

`git add .` will not pick up anything in `data/`, because of `.gitignore`. Run `git status` before committing and confirm no spreadsheet or CSV from `data/` appears.
