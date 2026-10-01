# Text Mining in R

A lab guide to text mining, built as a [Quarto](https://quarto.org) book in the same style as the [EDUS 664 multilevel modeling companion](https://github.com/mikediam123/mlm-textbook). Every chapter works through the R code for one technique, using the VCU CARES student interviews as the running example.

## Contents

| Chapter | Topic | Main packages |
|---|---|---|
| 1 | The data: structure, cleaning, what counts as a document | `tidyverse` |
| 2 | Tokens, word counts, stop words, bigrams | `tidytext`, `ggraph` |
| 3 | Term frequency and TF-IDF | `tidytext` |
| 4 | Topic models I: LDA | `topicmodels` |
| 5 | Topic models II: structural topic models | `stm` |
| 6 | Sentiment analysis (lexicon-based) | `tidytext` |
| 7 | Supervised learning: predicting the interviewers' topic codes | `glmnet` |
| 8 | Wrapping up: choosing methods, reporting honestly | none |

The arc runs from descriptive methods (counts, TF-IDF) through structure-finding methods (topic models, sentiment) to supervised learning.

## The data are not in this repository

The VCU CARES responses are real student statements. **They must never be committed.** `.gitignore` excludes the whole `data/` folder, and `docs/` and `_freeze/` (which contain verbatim quotes in rendered output) are ignored too until a publishing decision is made. See `SETUP.md`.

## Synthetic sample data

Lab members without access to the real responses can run everything on `sample-data/vcu_cares_synthetic.xlsx`, a generated dataset with the same structure and size. The text is invented, so it is for learning the methods, not for findings. See `sample-data/README.md`.

## Project layout

```
index.qmd, 01-...08-*.qmd   book chapters
_quarto.yml                 book configuration
styles.scss                 theme (same palette as the MLM book)
R/00-make-synthetic.R       generates the synthetic sample workbook
R/01-prep-data.R            builds data/vcu_cares_long.csv from the raw (or synthetic) workbook
R/helpers.R                 shared setup: data loading, cleaning rules, plot theme
sample-data/                synthetic workbook (safe to commit)
data/                       NOT COMMITTED: raw workbook and derived files
```

Every chapter begins with `source("R/helpers.R")`, so the cleaning rules (placeholder answers, apostrophe handling) live in exactly one place.

## Status

| Chapter | Rendered and checked | Notes |
|---|---|---|
| 1, 2, 3, 6, 7 | Yes | Run end to end against the real data; prose checked against actual output |
| 4 (LDA) | Partly | Everything except the `LDA()` fit itself was run, using a stand-in model. Needs a first real run |
| 5 (STM) | No | Written against the `stm` documentation but never executed. Expect to proofread it on first render |
| 8 | n/a | No code |

Chapters 4 and 5 need `topicmodels` and `stm`, which could not be installed in the environment where this was drafted. Render them on your machine before presenting, and revise the prose to describe the topics you actually get.
