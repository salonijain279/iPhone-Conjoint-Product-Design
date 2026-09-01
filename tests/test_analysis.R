script_arg <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", script_arg[grep("^--file=", script_arg)])
repo_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
source(file.path(repo_dir, "R", "rank_profiles.R"))

part_worths <- read_part_worths(file.path(repo_dir, "data", "aggregate_part_worths.csv"))
profiles <- rank_product_profiles(part_worths)

stopifnot(nrow(profiles) == 8)
stopifnot(profiles$price[1] == "$799")
stopifnot(profiles$storage[1] == "256 GB")
stopifnot(profiles$color[1] == "Black")
stopifnot(abs(profiles$predicted_preference[1] - 8.06) < 1e-10)
stopifnot(all(diff(profiles$predicted_preference) <= 0))

run_analysis(repo_dir)
stopifnot(file.exists(file.path(repo_dir, "outputs", "ranked_product_profiles.csv")))
stopifnot(file.exists(file.path(repo_dir, "outputs", "profile_preference.png")))

message("All conjoint product-design checks passed.")
