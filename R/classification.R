# Functions for predicting the interviewers' topic codes from text.
#
# These are the same functions Chapter 7 builds up step by step, saved here so that
# Chapter 8 can reuse them and start from exactly the same train/test split.
# Chapter 7 itself still writes them out in full, because explaining them is its job.
#
# Use:  source("R/helpers.R"); source("R/classification.R")

suppressPackageStartupMessages({
  library(tidytext)
  library(glmnet)
  library(Matrix)
})

snowball_stops <- stop_words |> filter(lexicon == "snowball")

# Answers that carry at least one interviewer topic code, with the codes split into a list
make_labeled <- function(vcu) {
  vcu |>
    filter(!is.na(topics)) |>
    mutate(text_id = row_number(),
           topics  = str_split(topics, ";\\s*"))
}

# Hold back 20% of STUDENTS (not answers) for testing, as in Chapter 7
split_by_student <- function(labeled, seed = 664, prop = 0.2) {
  set.seed(seed)
  students      <- unique(labeled$resp_id)
  test_students <- sample(students, size = round(prop * length(students)))
  list(train = labeled |> filter(!resp_id %in% test_students),
       test  = labeled |> filter( resp_id %in% test_students))
}

# Is this topic one of the answer's codes? Returns TRUE/FALSE for every answer
has_topic <- function(d, topic) map_lgl(d$topics, \(t) topic %in% t)

# ---- TF-IDF features, with the vocabulary and idf taken from the training answers only ----
tokenize_answers <- function(d) {
  d |>
    select(text_id, text) |>
    unnest_tokens(word, text) |>
    anti_join(snowball_stops, by = "word") |>
    filter(!str_detect(word, "^\\d+$"))
}

tfidf_features <- function(train, test, min_df = 5) {
  vocab_df <- tokenize_answers(train) |>
    distinct(text_id, word) |>
    count(word, name = "df") |>
    filter(df >= min_df) |>
    mutate(idf = log(nrow(train) / df))

  featurize <- function(d) {
    tok <- tokenize_answers(d) |>
      count(text_id, word) |>
      inner_join(vocab_df, by = "word") |>
      group_by(text_id) |>
      mutate(tf = n / sum(n)) |>
      ungroup()
    sparseMatrix(i = match(tok$text_id, d$text_id),
                 j = match(tok$word, vocab_df$word),
                 x = tok$tf * tok$idf,
                 dims = c(nrow(d), nrow(vocab_df)),
                 dimnames = list(NULL, vocab_df$word))
  }
  list(x_train = featurize(train), x_test = featurize(test))
}

# ---- Scoring ----
# Area under the ROC curve: the chance a random positive outranks a random negative
auc <- function(truth, p) {
  r <- rank(p)
  n1 <- sum(truth); n0 <- sum(!truth)
  (sum(r[truth]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

metrics <- function(truth, p, threshold = 0.5) {
  pred <- p >= threshold
  tp <- sum(pred & truth); fp <- sum(pred & !truth)
  fn <- sum(!pred & truth); tn <- sum(!pred & !truth)
  precision <- if (tp + fp > 0) tp / (tp + fp) else NA_real_
  recall    <- tp / (tp + fn)
  tibble(tp, fp, fn, tn,
         accuracy  = (tp + tn) / length(truth),
         precision, recall,
         f1 = 2 * precision * recall / (precision + recall))
}

# Fit a lasso logistic regression on training answers and return test-set probabilities.
# (cv.glmnet may warn that it switched the penalty-selection score when there are
# very few training answers; that is expected and harmless here.)
# Extra arguments (...) go straight to cv.glmnet(); Chapter 8 uses them to shorten the
# penalty path for dense embedding features.
lasso_probs <- function(x_train, y_train, x_test, seed = 664, ...) {
  set.seed(seed)
  f <- cv.glmnet(x_train, y_train, family = "binomial", alpha = 1, type.measure = "auc", ...)
  as.numeric(predict(f, x_test, s = "lambda.1se", type = "response"))
}
