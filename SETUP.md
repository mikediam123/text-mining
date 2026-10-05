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

## Step 1: Build the analysis file

The book runs on a **synthetic** dataset that ships with the repository (`sample-data/vcu_cares_synthetic.xlsx`). It has the same structure and size as the real VCU CARES workbook, but every word of text is invented. See `sample-data/README.md` for what it can and cannot be used for.

From the project root, in the Terminal tab:

```bash
Rscript R/01-prep-data.R
```

This stacks the workbook's three sheets into one long table, `data/vcu_cares_long.csv`, with one row per answer. It should report about 3,600 answers from about 1,240 respondents. If a chapter stops with "Can't find data/vcu_cares_long.csv", you skipped this step.

### Using the real data (approved users only)

If you have approved access to the real workbook, keep it **outside** the repository folder or inside `data/` (which is gitignored), and point the same script at it:

```bash
Rscript R/01-prep-data.R data/raw/vcu_cares.xlsx
```

The script drops demographics (major, GPA, gender, race/ethnicity) because no chapter uses them. Never commit the real workbook or anything derived from it, and never publish a site rendered from it. The prose in the book was written against the synthetic data, so real results will differ.

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

The site is built and published by GitHub Actions (`.github/workflows/publish.yml`), always from the synthetic data. The build also installs Python and runs `py/embed.py`, so Chapter 8 renders on the site. Rendered output (`docs/`, `_freeze/`) is gitignored on purpose, so a local render can never leak real data into the repository.

**One-time setup**

1. Merge your work to `main`.
2. In the repository, go to **Settings > Pages** and set **Source** to **GitHub Actions**.
3. Push to `main` (or run the workflow from the **Actions** tab). The site appears at `https://<owner>.github.io/text-mining/`.

Every pull request also runs the build without deploying, which catches a chapter that stops rendering before it reaches the site.

### Before making the repository public

GitHub Pages on a free account needs a public repository. Work through this list first:

- [ ] **No real data, ever, in history.** Check with `git log --all --name-only --pretty=format: | sort -u` and look for any `.xlsx` or `.csv` other than `sample-data/vcu_cares_synthetic.xlsx`. A file deleted in a later commit is still in history and would be public.
- [ ] **No real quotes in the text.** Skim the `.qmd` files and `R/00-make-synthetic.R` for any phrase copied from a real response.
- [ ] **The Actions build is green** on `main`, including chapters 4 and 5.
- [ ] **Your approvals allow** describing the study design publicly (the three interview questions and the topic codes appear in Chapter 1).

If any of the first two cannot be confirmed, keep the repository private.
