# TEMPORARY diagnostic (manual workflow runs only): why does default LDA collapse?
suppressPackageStartupMessages({ source("R/helpers.R"); library(tidytext); library(topicmodels) })
vcu <- load_vcu()
stops <- stop_words |> filter(lexicon == "snowball")
custom_stops <- tibble(word = c("vcu","student","students","like","get","just","really","also","can","e","g","lot"))
tokens <- vcu |> unnest_tokens(word, text) |> anti_join(stops, by = "word") |>
  anti_join(custom_stops, by = "word") |> filter(!str_detect(word, "^\\d+$"))
vocab <- tokens |> distinct(resp_id, word) |> count(word) |> filter(n >= 5) |> pull(word)
keep <- tokens |> filter(word %in% vocab) |> count(resp_id, word) |>
  group_by(resp_id) |> filter(sum(n) >= 5) |> ungroup()
dtm <- keep |> cast_dtm(document = resp_id, term = word, value = n)
cat("DTM:", dim(dtm), " mean words/doc:", round(mean(slam::row_sums(dtm)), 1), "\n")

report <- function(name, m) {
  g <- posterior(m)$topics
  cat("\n=== ", name, " | K =", m@k, " | alpha =", round(m@alpha, 3),
      " | mean max gamma =", round(mean(apply(g, 1, max)), 3),
      " | sd of topic prevalence =", round(sd(colMeans(g)), 3), "\n")
  print(terms(m, 6))
}
t0 <- Sys.time()
report("VEM default",            LDA(dtm, 6, control = list(seed = 664)))
report("VEM alpha=0.1 fixed",    LDA(dtm, 6, control = list(seed = 664, alpha = 0.1, estimate.alpha = FALSE)))
report("VEM alpha=0.5 fixed",    LDA(dtm, 6, control = list(seed = 664, alpha = 0.5, estimate.alpha = FALSE)))
report("Gibbs alpha=0.1",        LDA(dtm, 6, method = "Gibbs", control = list(seed = 664, alpha = 0.1, burnin = 200, iter = 600)))
report("Gibbs default alpha",    LDA(dtm, 6, method = "Gibbs", control = list(seed = 664, burnin = 200, iter = 600)))
report("Gibbs alpha=0.1 K=10",   LDA(dtm, 10, method = "Gibbs", control = list(seed = 664, alpha = 0.1, burnin = 200, iter = 600)))
report("Gibbs alpha=0.1 K=18",   LDA(dtm, 18, method = "Gibbs", control = list(seed = 664, alpha = 0.1, burnin = 200, iter = 600)))
cat("\nelapsed:", round(difftime(Sys.time(), t0, units = "secs")), "s\n")
