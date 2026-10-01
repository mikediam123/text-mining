# Generate a SYNTHETIC stand-in for the VCU CARES workbook.
#
# Output: sample-data/vcu_cares_synthetic.xlsx
#
# What is real and what is not
#   - Structure is copied from the real workbook: three sheets, the same
#     column headers (including the swapped Date/Event headers and the
#     non-breaking spaces), the same row counts (1,021 / 79 / 141), the same
#     messy student-level labels and placeholder answers.
#   - Aggregate rates (how often each topic code is ticked, how many codes per
#     answer, answer lengths, level mix, placeholder rates) were tuned to
#     match the real data.
#   - Every word of text is invented here from the phrase banks below. No real
#     student response, name, ID, or interviewer appears. Topic codes are
#     generated together with the text, so they genuinely match it.
#
# What it is NOT: a substitute for the real data when you want findings. It has
# far less variety, no real nuance, and conclusions drawn from it mean nothing
# about VCU students. Chapter numbers and prose will not match exactly.
#
# Run from the project root:  Rscript R/00-make-synthetic.R

library(tidyverse)
library(writexl)

set.seed(664)

# ---- Topic codes and their language ------------------------------------------
# Subjects are bare noun phrases that read naturally after "the" or standing alone.
bank <- list(
  "Advising" = c("advising appointments", "my academic advisor", "degree planning help",
                 "course registration", "advisors who answer emails", "major declaration process",
                 "graduation checks", "schedule planning"),
  "Classroom/faculty" = c("professors", "small class sizes", "faculty office hours",
                          "instructors who care", "lecture halls", "teaching assistants",
                          "classroom technology", "faculty feedback on assignments"),
  "Curriculum/course design" = c("required general education courses", "course sequencing",
                                 "elective choices", "capstone project", "course workload",
                                 "online course options", "syllabus expectations", "curriculum updates"),
  "Dining" = c("dining hall options", "meal plan", "late-night food", "vegetarian choices",
               "food prices on campus", "meal swipes", "campus cafe hours", "fresh food options"),
  "Faculty development" = c("faculty training on inclusive teaching", "support for new instructors",
                            "professor mentoring programs", "teaching workshops"),
  "Financial aid" = c("financial aid office", "scholarship opportunities", "FAFSA help",
                      "aid refund timing", "work-study positions", "grant funding",
                      "financial aid paperwork", "emergency aid"),
  "Having a sense of belonging" = c("sense of community", "feeling welcome on campus",
                                    "making friends", "diversity of the student body",
                                    "cultural student groups", "feeling like I belong",
                                    "inclusion efforts", "peer connections"),
  "Health support (mental/physical)" = c("counseling services", "mental health resources",
                                         "the student health clinic", "wait times for therapy",
                                         "the recreation center", "wellness programs",
                                         "after-hours health support", "disability accommodations"),
  "Housing/building improvements/Maintenance" = c("dorm conditions", "housing costs",
                                                  "off-campus housing options", "building maintenance",
                                                  "laundry rooms", "air conditioning in the dorms",
                                                  "study space renovations", "residence hall repairs"),
  "Safety" = c("campus safety", "lighting at night", "campus police presence",
               "pedestrian crossings", "safe ride options", "emergency alerts",
               "crime near campus", "security in the buildings"),
  "Staff development" = c("staff training", "front desk staff knowledge",
                          "consistency between offices", "staff turnover"),
  "Student professional development" = c("career fairs", "internship opportunities",
                                         "resume workshops", "networking events",
                                         "job placement help", "alumni mentoring",
                                         "research opportunities", "professional skills programs"),
  "Student activities" = c("student organizations", "campus events", "club fair",
                           "social events", "intramural sports", "weekend activities",
                           "school spirit events", "concerts and performances"),
  "Student support services" = c("career services", "the registrar's office",
                                 "tutoring center", "the writing center", "academic coaching",
                                 "TRIO program", "first-generation student support",
                                 "the library staff"),
  "Student voice" = c("student government", "chances to give feedback", "listening to student concerns",
                      "student input on decisions", "student surveys", "administration communication"),
  "Technology" = c("the student portal", "campus wifi", "course website", "online registration system",
                   "laptop loan program", "software access", "email system", "tech support"),
  "Tuition" = c("tuition costs", "tuition increases", "cost of attendance",
                "payment plans", "fees on the bill", "textbook costs"),
  "Other" = c("parking", "transportation to campus", "the city of Richmond",
              "campus layout", "bus passes", "weather on campus walks",
              "campus map signs", "commuter options")
)
bank[["General"]] <- c("the resources available", "support for students", "the opportunities here",
                       "how things are run", "the overall experience", "the people", "the campus in general",
                       "communication", "the system", "getting help when needed")
tags <- setdiff(names(bank), "General")

# Tick rates per question for the 19 checkbox slots (the real file's rates;
# "None" is never ticked). Order matches the real checkbox order, with None
# between Tuition and Other.
slot_names <- c("Advising", "Classroom/faculty", "Curriculum/course design", "Dining",
                "Faculty development", "Financial aid", "Having a sense of belonging",
                "Health support (mental/physical)",
                "Housing/building improvements/Maintenance", "Safety", "Staff development",
                "Student professional development", "Student activities",
                "Student support services", "Student voice", "Technology", "Tuition",
                "None", "Other")
rate_strength <- c(.185,.204,.133,.025,.020,.038,.238,.067,.019,.039,.011,.143,.283,.273,.044,.021,.007,0,.119)
rate_concern  <- c(.083,.086,.083,.038,.009,.082,.060,.048,.162,.092,.006,.059,.090,.094,.069,.011,.050,0,.177)
names(rate_strength) <- names(rate_concern) <- slot_names

# How many codes an answer carries (1 is most common)
n_codes_strength <- c(`1`=.514, `2`=.266, `3`=.129, `4`=.045, `5`=.03)
n_codes_concern  <- c(`1`=.606, `2`=.183, `3`=.069, `4`=.03,  `5`=.01)

# ---- Sentence frames ------------------------------------------------------------
frames <- list(
  strength = c("I appreciate the {x}", "Really happy with the {x}", "{X} - very helpful",
               "Love the {x}", "The {x} made a big difference for me", "Good {x}",
               "Positive experience with the {x}", "Helpful {x}",
               "{X}, which made my first year easier", "Great {x}", "The {x} here are strong",
               "I'd say the {x} stands out", "Thankful for the {x}", "{X} is one of the best things about VCU",
               "Enjoyed the {x}", "I was surprised how good the {x} were", "VCU does well with the {x}",
               "Grateful for the {x}", "{X} - they really try", "Solid {x}",
               "The {x} helped me get started", "Easy to use: the {x}", "I rely on the {x}",
               "{X} has improved since I got here", "Nothing but good things to say about the {x}",
               "The {x} felt welcoming", "Impressed by the {x}", "Compared to other schools, the {x} are ahead",
               "The {x} kept me on track", "My favorite part is the {x}"),
  concern  = c("Problems with the {x}", "Not enough {x}", "Worried about the {x}",
               "Frustrated with the {x}", "{X} - hard to get information",
               "The {x} could be a lot better", "Long waits for {x}",
               "Confusing {x}", "Hard to get help with {x}", "I don't feel the {x} work for everyone",
               "{X} doesn't meet student needs", "Concerned about {x}",
               "Need better {x}", "I wish there were more helpful {x}", "More support with {x} would help",
               "A better {x} would be good", "Would be great to have more {x}",
               "{X} is inconsistent from one semester to the next", "I can never get a straight answer about {x}",
               "The {x} feel understaffed", "Too expensive: the {x}", "{X} is out of date",
               "No one told me about the {x}", "Disappointed by the {x}", "{X} keeps getting worse",
               "Struggling with the {x}", "The {x} are hard to find", "Feels like nobody is in charge of the {x}",
               "The {x} are not accessible to everyone", "{X} - needs attention",
               "Unclear who to ask about the {x}", "Barriers around {x}"),
  idea     = c("More {x}", "Improve the {x}", "Better {x}", "Expand {x}",
               "Make {x} easier to find", "Add more {x}", "Fund the {x}",
               "Lower the cost of {x}", "Simplify the {x}", "More communication about {x}",
               "Hire more people for the {x}", "Extend hours for the {x}", "Make {x} free",
               "Promote the {x} more", "Survey students about the {x}", "Train staff on the {x}",
               "Modernize the {x}", "Create a single place to learn about {x}", "Open up more {x}",
               "Give students a say in the {x}", "Put the {x} online", "Offer {x} on weekends",
               "Reduce the wait for {x}", "Rethink the {x}")
)
frames_note <- list(   # interviewer-paraphrase style used on the paper forms
  strength = c("Likes the {x}", "Appreciates the {x}", "Positive about {x}", "Says {x} was helpful",
               "Mentioned that the {x} helped", "Speaks well of the {x}", "Thinks the {x} are strong"),
  concern  = c("Doesn't like {x}", "Frustrated by the {x}", "Concerned about {x}", "Says {x} is hard to deal with",
               "Wants the {x} to change", "Feels the {x} is lacking", "Had trouble with the {x}"),
  idea     = c("Wants more {x}", "Suggests improving {x}", "Would like better {x}", "Asks for {x}",
               "Recommends expanding {x}", "Thinks the {x} should be cheaper", "Proposes changes to the {x}")
)
elaborations <- c(
  "It took me weeks to figure out who to contact.", "My friends have said the same thing.",
  "That is what I hear from other students too.", "It was different from what I expected before I enrolled.",
  "I only found out about it by accident.", "I wish someone had told me earlier.",
  "That would help a lot of students.", "It matters more than people realize.",
  "This has been true since my first semester.", "I commute, so it affects me a lot.",
  "I work part time, so timing is hard for me.", "As a transfer student I had to figure it out alone.",
  "My roommate had the opposite experience.", "I have raised this before and nothing changed.",
  "It depends a lot on which department you are in.", "I'm a first-generation student, so I notice this.",
  "I did not know where to look.", "It is better than it was last year.",
  "Other schools I looked at seemed to handle this better.", "I'd gladly help if someone asked.",
  "A friend of mine left because of this.", "My advisor mentioned the same issue.",
  "Most of my classmates feel the same.", "It really shapes how I feel about being here.",
  "Honestly it surprised me.", "Maybe it is just my program.", "I notice it most near the end of the term.",
  "It would be an easy fix.", "Online students get left out of this.", "I live off campus, so I rarely hear about it.",
  "Grad students seem to be forgotten here.", "It was the first thing I noticed.",
  "People tell me it was worse before.", "I think new students would benefit most.",
  "The information is out there but scattered.", "It seems to depend on who you talk to."
)
placeholders <- c("None", "none", "N/A", "n/a", "NA", "nothing", "Nothing", "No concerns",
                  "no concerns", "none!", "Not sure", "No answer", "I don't know", "test",
                  "Testing form", "Did not respond", "none right now", "nothing yet")
placeholder_w <- c(14,40,12,12,10,12,5,6,5,4,4,3,3,5,2,2,2,2)

# ---- Text builders --------------------------------------------------------------
cap <- function(s) paste0(toupper(substr(s, 1, 1)), substring(s, 2))

fragment <- function(tag, kind, note = FALSE) {
  x <- sample(bank[[tag]], 1)
  f <- sample((if (note) frames_note else frames)[[kind]], 1)
  # Frames with a bare "{x}" (no "the" before it) read badly with a subject that
  # already starts with an article ("Add more the campus layout")
  if (!str_detect(f, fixed("the {x}")) && str_detect(f, fixed("{x}"))) x <- str_remove(x, "^(the|my) ")
  f <- str_replace(f, fixed("{X}"), cap(x))
  f <- str_replace(f, fixed("{x}"), x)
  str_replace_all(f, "\\b(the|The) (the|my) ", "\\1 ") |>   # avoid "the the library" / "the my advisor"
    str_replace_all("\\b[Tt]he (the|my) ", "\\1 ") |>
    str_replace("^(.)he (the|my) ", "\\1\\2 ")
}

roughen <- function(s) {
  if (runif(1) < 0.30) s <- paste0(tolower(substr(s, 1, 1)), substring(s, 2))
  if (runif(1) < 0.35) s <- paste0(s, ".")
  if (runif(1) < 0.55) s <- str_replace_all(s, "'", "’")      # curly apostrophes, as in the real file
  if (nchar(s) > 8 && runif(1) < 0.04) {                           # a typo: swap two adjacent letters
    i <- sample(2:(nchar(s) - 2), 1)
    s <- paste0(substr(s, 1, i - 1), substr(s, i + 1, i + 1), substr(s, i, i), substring(s, i + 2))
  }
  s
}

make_text <- function(tag_set, kind, note = FALSE) {
  r <- runif(1)
  topical <- setdiff(tag_set, "General")                # vague phrases make poor stand-alone answers
  if (r < 0.10 && !note && length(topical)) {           # bare keyword answers ("Housing")
    t <- if (length(topical) == 1) topical else sample(topical, 1)
    return(roughen(sample(bank[[t]], 1)) |> str_remove("\\.$"))
  }
  if (kind == "idea" && r > 0.88 && !note) {            # numbered lists, as students were asked for three things
    ts <- sample(tag_set, 3, replace = TRUE)
    parts <- map_chr(ts, \(t) fragment(t, "idea") |> str_replace("^(.)", \(m) tolower(m)))
    return(paste0("1. ", parts[1], " 2. ", parts[2], " 3. ", parts[3]))
  }
  parts <- map_chr(tag_set, \(t) fragment(t, kind, note))
  if (runif(1) < 0.07) {                                # a few long, multi-point answers (the real data have a long tail)
    extra <- map_chr(sample(tag_set, sample(2:4, 1), replace = TRUE), \(t) fragment(t, kind, note))
    return(paste(c(roughen(paste(c(parts, extra), collapse = ". ")),
                   sample(elaborations, sample(3:5, 1))), collapse = " "))
  }
  if (length(parts) > 1) {
    s <- parts[1]
    for (p in parts[-1]) s <- paste0(s, sample(c(", ", " and ", "; ", ". "), 1, prob = c(.4, .25, .1, .25)),
                                     if (runif(1) < 0.5) tolower(substr(p, 1, 1)) else substr(p, 1, 1),
                                     substring(p, 2))
  } else s <- parts
  s <- roughen(s)
  if (runif(1) < (if (kind == "strength") 0.30 else 0.38)) s <- paste(s, sample(elaborations, 1))
  if (runif(1) < 0.04) s <- paste(s, sample(elaborations, 1))
  s
}

draw_tags <- function(rates, n_dist) {
  n <- as.integer(sample(names(n_dist), 1, prob = n_dist))
  pool <- setdiff(slot_names, "None")
  sample(pool, min(n, length(pool)), prob = rates[pool] + 1e-6)
}

answer_cell <- function(kind, rates, n_dist, p_missing, p_placeholder, note = FALSE, tagged = TRUE) {
  # Returns list(text, tags)
  u <- runif(1)
  if (u < p_missing) return(list(text = NA_character_, tags = character(0)))
  if (u < p_missing + p_placeholder) {
    return(list(text = sample(placeholders, 1, prob = placeholder_w), tags = character(0)))
  }
  tg <- draw_tags(rates, n_dist)
  # Real coding is noisy: interviewers tick topics the text only hints at, and answers
  # drift to unrelated subjects. So not every coded topic is mentioned, some answers are
  # vague, and some mention a topic that was never coded.
  said <- ifelse(runif(length(tg)) < 0.62, tg, "General")
  if (runif(1) < 0.22) said <- c(said, sample(setdiff(tags, tg), 1))
  list(text = make_text(said, kind, note), tags = if (tagged) tg else character(0))
}

# ---- Sheet 1: Original Form (1,021 rows, 47 columns) ---------------------------
n1 <- 1021
pre <- "Interviewer select the topic(s) discussed in the previous question. - "
q1_labels <- c(slot_names[1:13], "Student support services (ex:  career services and registrar's office)",
               "Student voice ", "Technology", "Tuition ", "None", "Other")
q2_labels <- c(slot_names[1:13], "Student support services (ex: career services and registrar's office)",
               "Student voice ", "Technology", "Tuition ", "None", "Other")
tick_names <- c(slot_names[1:13], "Student support services", "Student voice",
                "Technology", "Tuition", "None", "Other")

level <- sample(c("Undergraduate", "Graduate", "First Professional"), n1, TRUE, c(.830, .155, .015))

a1 <- map(seq_len(n1), \(i) answer_cell("strength", rate_strength, n_codes_strength, .005, .007))
a2 <- map(seq_len(n1), \(i) answer_cell("concern",  rate_concern,  n_codes_concern,  .048, .095))
a3 <- map(seq_len(n1), \(i) answer_cell("idea",     rate_concern,  n_codes_concern,  .034, .043, tagged = FALSE))

# A few keyboard-mashing answers, as in the real data
junk_rows <- sample(n1, 4)
a3[[junk_rows[1]]]$text <- "asdfasdf"; a3[[junk_rows[2]]]$text <- "fsadf"
a3[[junk_rows[3]]]$text <- "asdfsdaf"; a3[[junk_rows[4]]]$text <- "npne"

tick_matrix <- function(a) {
  t(vapply(a, \(z) ifelse(slot_names %in% z$tags, TRUE, NA), logical(length(slot_names))))
}
t1 <- tick_matrix(a1); t2 <- tick_matrix(a2)

# Demographics are filled in for 689 of the 1,021 students, as in the real file
have_demo <- seq_len(n1) %in% sample(n1, 689)
majors <- c("Psychology", "Biology", "Nursing", "Business", "Computer Science", "Mechanical Engineering",
            "Graphic Design", "Social Work", "Criminal Justice", "Mass Communications", "Pre-Medical Lab Sciences",
            "Marketing", "Information Systems", "Chemistry", "Political Science", "Public Health",
            "Kinesiology", "Painting and Printmaking", "Health Administration", "English", "Sociology",
            "Education", "Finance", "Accounting", "Mathematics", "Physics", "Dance", "Music",
            "Fashion Design", "Pharmacy")
demo_gender <- sample(c("FEMALE", "MALE", "OTHER"), n1, TRUE, c(588, 76, 25) / 689)
demo_race   <- sample(c("White", "Black/African American", "Asian", "Hispanic/Latino",
                        "Two or More Races", "International", "Unknown"), n1, TRUE,
                      c(.40, .26, .12, .09, .06, .04, .03))

orig <- tibble(.rows = n1)
orig[["What is your student level?"]] <- level
orig[["What has VCU done really well that has helped you and other students?"]] <- map_chr(a1, "text")
for (j in seq_along(q1_labels)) orig[[paste0(pre, q1_labels[j], "\r", j)]] <- ifelse(t1[, j], tick_names[j], NA_character_)
orig[["What is the biggest concern you have regarding how VCU supports students?"]] <- map_chr(a2, "text")
for (j in seq_along(q2_labels)) orig[[paste0(pre, q2_labels[j], "\r", j, ".1")]] <- ifelse(t2[, j], tick_names[j], NA_character_)
orig[["What are the top three things that VCU can do today to make your experience be the best it can be?"]] <- map_chr(a3, "text")
orig[["Unique ID"]]          <- ifelse(have_demo, NA_real_, NA_real_)
orig[["Unique ID"]][have_demo] <- sample(1:814, sum(have_demo))
orig[["Major"]]              <- ifelse(have_demo, sample(majors, n1, TRUE), NA_character_)
orig[["GPA"]]                <- ifelse(have_demo, round(pmin(4, pmax(0, rnorm(n1, 3.3, .5))), 2), NA_real_)
orig[["Gender"]]             <- ifelse(have_demo, demo_gender, NA_character_)
orig[["Race or Ethnicity"]]  <- ifelse(have_demo, demo_race, NA_character_)

# Restore the real header names: drop the "\r<j>" markers used only to keep column names unique
names(orig) <- str_remove(names(orig), "\r\\d+(\\.1)?$")

# ---- Sheets 2 and 3: event forms --------------------------------------------------
event_answers <- function(n, note, p_miss = c(0.00, 0.04, 0.05)) {
  tibble(
    pos  = map_chr(seq_len(n), \(i) answer_cell("strength", rate_strength, n_codes_strength, p_miss[1], .01, note, FALSE)$text),
    neg  = map_chr(seq_len(n), \(i) answer_cell("concern",  rate_concern,  n_codes_concern,  p_miss[2], .04, note, FALSE)$text),
    idea = map_chr(seq_len(n), \(i) answer_cell("idea",     rate_concern,  n_codes_concern,  p_miss[3], .04, note, FALSE)$text)
  )
}

n2 <- 79
ev2 <- rep(c("Career Expo", "Spring Picnic", "Graduation Fair", "Honors Convocation"), c(16, 21, 32, 10))
ev2_date <- as.POSIXct(c("2026-04-15", "2026-04-22", "2026-05-02", "2026-05-06"), tz = "UTC")
a <- event_answers(n2, note = FALSE, p_miss = c(0, .04, .05))
second <- tibble(
  Date = ev2,
  Event = ev2_date[match(ev2, c("Career Expo", "Spring Picnic", "Graduation Fair", "Honors Convocation"))],
  Status = sample(c("Undergraduate", "Graduate"), n2, TRUE, c(69, 10) / 79),
  `VCU: Positive Experience` = a$pos,
  `VCU: Negative Experience` = a$neg,
  `Ideas/Changes` = a$idea,
  Interviewer = sample(paste("Interviewer", LETTERS[1:8]), n2, TRUE),
  `Student Number` = as.numeric(sample(153:865, n2)),
  Major = sample(majors, n2, TRUE),
  GPA = round(pmin(4, pmax(2, rnorm(n2, 3.3, .45))), 2),
  Gender = sample(c("FEMALE", "MALE", "OTHER", NA), n2, TRUE, c(35, 9, 1, 34) / 79),
  `Race or Ethnicity` = sample(c("Black/African American", "White", "Asian", "Hispanic/Latino",
                                 "Two or More Races", "Unknown", "International", NA), n2, TRUE,
                               c(14, 12, 9, 5, 3, 2, 1, 33) / 79)
)
second$Major[is.na(second$Gender)] <- NA_character_
second$GPA[is.na(second$Gender)] <- NA_real_
second$`Race or Ethnicity`[is.na(second$Gender)] <- NA_character_

n3 <- 141
ev3_names <- c("Welcome Week Cookout", "Graduate Fair Spring", "Autumn Career Expo",
               "Business School Mixer", "Social Work Commencement", "Honors Breakfast",
               "Residence Hall Open House")
a <- event_answers(n3, note = TRUE, p_miss = c(.02, .04, .12))
paper <- tibble(
  Date = NA_real_,
  Event = sample(ev3_names, n3, TRUE, c(.20, .13, .13, .17, .12, .13, .12)),
  `Email (If provided)` = NA_real_,
  Status = sample(c("Undergrad", "grad", "Grad", "professional student", NA), n3, TRUE,
                  c(108, 17, 5, 1, 10) / 141),
  `VCU: Positive Experience` = a$pos,
  `VCU: Negative Experience` = a$neg,
  `Ideas/Changes` = a$idea,
  `Student Number` = NA_real_,
  Major = NA_real_, GPA = NA_real_, Gender = NA_real_, `Race or Ethnicity` = NA_real_
)
paper$`Student Number`[sample(n3, 28)] <- sample(1:200, 28)

# ---- Write --------------------------------------------------------------------------
dir.create("sample-data", showWarnings = FALSE)
write_xlsx(list(`Original Form` = orig, `Second Process` = second, `Found Paper Forms` = paper),
           "sample-data/vcu_cares_synthetic.xlsx")
message("Wrote sample-data/vcu_cares_synthetic.xlsx  (",
        nrow(orig), " / ", nrow(second), " / ", nrow(paper), " rows)")
