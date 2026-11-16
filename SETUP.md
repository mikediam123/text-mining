# Setup and Publishing Guide

## Before you start

You need R, RStudio, and Quarto (bundled with recent RStudio; check with `quarto --version` in the Terminal tab). Install the packages once:

```r
install.packages(c(
  "tidyverse", "readxl", "tidytext", "topicmodels", "stm",
  "glmnet", "ggraph", "igraph", "rsample", "reshape2"
))
```

`topicmodels` needs the GNU Scientific Library on some Linux systems (`libgsl-dev`).

## Getting the files (no GitHub account needed)

You can read the book without an account at <https://mikediam123.github.io/text-mining/>. To run the code, you need a copy of the project folder. Pick whichever of these is easiest:

- **Download ZIP.** On the repository page (<https://github.com/mikediam123/text-mining>), click the green **Code** button, then **Download ZIP**, and unzip it. No account required.
- **A shared Drive folder.** Someone with a copy can upload the unzipped folder, or the ZIP, to Google Drive and share it. This is a **snapshot**: it does not update when the repository changes, so re-download when you hear there is a new version.
- **GitHub Desktop.** If you do want updates, GitHub Desktop can clone the repository and pull changes without using a terminal.

Whichever you choose, **copy the project to a local folder before opening it.** RStudio and Quarto can be slow or unreliable when working inside a synced Google Drive folder. Then open `TextMining.Rproj` and continue with the steps below.

> **Important:** Keep real VCU CARES data out of any shared folder unless that is approved for student statements. If you have approved access, put the workbook in `data/raw/` on your own machine only (see Step 1).

## Step 1: Build the analysis file

The book runs on a **synthetic** dataset that ships with the repository (`sample-data/vcu_cares_synthetic.xlsx`). It has the same structure and size as the real VCU CARES workbook, but every word of text is invented. See `sample-data/README.md` for what it can and cannot be used for.

From the project root, in the Terminal tab:

```bash
Rscript R/01-prep-data.R
```

This stacks the workbook's three sheets into one long table, `data/vcu_cares_long.csv`, with one row per answer. It should report about 3,600 answers from about 1,240 respondents. If a chapter stops with "Can't find data/vcu_cares_long.csv", you skipped this step.

### Using the real data (approved users only)

This project publishes its rendered output, so **analyze real data in a separate copy of the project, outside this repository folder** (for example, a "Download ZIP" copy with no `.git` folder). Keep the real workbook in that copy's `data/` folder and point the script at it:

```bash
Rscript R/01-prep-data.R data/raw/vcu_cares.xlsx
```

The script drops demographics (major, GPA, gender, race/ethnicity) because no chapter uses them. Never commit the real workbook or anything derived from it. As a safety net, `_prerender.R` refuses to render the book unless `data/` was built from the synthetic workbook: `01-prep-data.R` records a fingerprint of the workbook it read, and the render stops if it isn't the synthetic one. You can still run chunks interactively on real data; you just can't render. The prose in the book was written against the synthetic data, so real results will differ.

## Step 2 (Chapter 8 only): Create the embeddings

Chapter 8 uses a small pretrained language model (MiniLM) that runs on your own computer, through one short Python script. Nothing else in the book needs Python, and if you skip this step every other chapter still renders (Chapter 8 will stop with a message telling you to run it).

You need Python 3.9 or newer. Install the packages once, from the project root. Install PyTorch first, because the CPU-only build is much smaller than the default one:

```bash
python -m pip install torch --index-url https://download.pytorch.org/whl/cpu
python -m pip install -r py/requirements.txt
```

Then, after Step 1:

```bash
python py/embed.py
```

The first run downloads the model (about 90 MB) and takes a minute or two. It writes `data/embeddings_minilm.csv`, which is gitignored like everything else in `data/`. After the first download the model works offline, and no text leaves your computer. The script pins the exact model version (`MODEL_REVISION` in `py/embed.py`) so results reproduce; set it to `None` to use the latest.

## Step 3: Render

Open `TextMining.Rproj`, then either click **Render Book** in the Build pane, or run `quarto render` in the Terminal. To work on one chapter, run its chunks interactively in RStudio first; it is much easier than debugging a whole-book render.

Chapters 4 and 5 (topic models) were drafted without access to `topicmodels` and `stm`. Expect to proofread them on the first run.

## Publishing the site

The book is rendered **locally** and the rendered site is committed. GitHub Pages serves the `docs/` folder from `main`; nothing is built on GitHub.

**Each time you update the book**

1. Make sure `data/` came from the synthetic workbook (`Rscript R/01-prep-data.R` with no path). The render refuses otherwise.
2. Render: **Render Book** in RStudio, or `quarto render`. Because `freeze: auto` is on, only chapters you changed are re-run; the rest reuse their cached results in `_freeze/`.
3. Commit everything, including `docs/` and `_freeze/`, and push to `main`. The site updates within a minute or two.

Chapter 8 needs the embeddings (Step 2) only when it re-runs, which is only when you edit it. Its cached results in `_freeze/` are used otherwise.

**One-time setup**

1. In the repository, go to **Settings > Pages > Build and deployment** and set **Source** to **Deploy from a branch**, then choose `main` and `/docs`.
2. Before the first local render, delete any old `docs/` and `_freeze/` folders in your copy, so nothing from an earlier render (on any data) gets committed. Then render the whole book once and commit the result.

The site is at `https://mikediam123.github.io/text-mining/`.

### Before making the repository public

GitHub Pages on a free account needs a public repository. Work through this list first:

- [ ] **No real data, ever, in history.** Check with `git log --all --name-only --pretty=format: | sort -u` and look for any `.xlsx` or `.csv` other than `sample-data/vcu_cares_synthetic.xlsx`. A file deleted in a later commit is still in history and would be public.
- [ ] **No real quotes in the text.** Skim the `.qmd` files and `R/00-make-synthetic.R` for any phrase copied from a real response.
- [ ] **A full local render succeeds** from the synthetic data, including chapters 4, 5, and 8.
- [ ] **Your approvals allow** describing the study design publicly (the three interview questions and the topic codes appear in Chapter 1).

If any of the first two cannot be confirmed, keep the repository private.
