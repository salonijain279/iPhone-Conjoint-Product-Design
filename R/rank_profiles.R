read_part_worths <- function(path) {
  part_worths <- read.csv(path, check.names = FALSE, stringsAsFactors = FALSE)
  required_columns <- c("attribute", "level", "utility_delta")
  if (!all(required_columns %in% names(part_worths))) {
    stop("Part-worth input is missing required columns")
  }
  if (anyDuplicated(paste(part_worths$attribute, part_worths$level))) {
    stop("Each attribute-level combination must be unique")
  }
  part_worths
}


rank_product_profiles <- function(part_worths) {
  lookup <- setNames(
    part_worths$utility_delta,
    paste(part_worths$attribute, part_worths$level, sep = "::")
  )
  required_terms <- c(
    "baseline::$799 + 128 GB + Black",
    "price::$999",
    "storage::256 GB",
    "color::White"
  )
  if (!all(required_terms %in% names(lookup))) {
    stop("Part-worth input does not contain the expected design terms")
  }

  profiles <- expand.grid(
    price = c("$799", "$999"),
    storage = c("128 GB", "256 GB"),
    color = c("Black", "White"),
    stringsAsFactors = FALSE
  )
  profiles$predicted_preference <- lookup[[required_terms[1]]] +
    ifelse(profiles$price == "$999", lookup[["price::$999"]], 0) +
    ifelse(profiles$storage == "256 GB", lookup[["storage::256 GB"]], 0) +
    ifelse(profiles$color == "White", lookup[["color::White"]], 0)
  profiles$profile <- paste(profiles$price, profiles$storage, profiles$color, sep = " · ")
  profiles$rank <- rank(-profiles$predicted_preference, ties.method = "min")
  profiles[order(profiles$rank), c("rank", "profile", "price", "storage", "color", "predicted_preference")]
}


plot_profile_ranking <- function(profiles, path) {
  ordered <- profiles[order(profiles$predicted_preference), ]
  png(path, width = 1500, height = 950, res = 160)
  par(mar = c(5, 14, 4, 2) + 0.1)
  bars <- barplot(
    ordered$predicted_preference,
    names.arg = ordered$profile,
    horiz = TRUE,
    las = 1,
    col = ifelse(ordered$rank == 1, "#2563eb", "#93c5fd"),
    border = NA,
    xlim = c(0, max(ordered$predicted_preference) * 1.15),
    xlab = "Predicted preference score",
    main = "Conjoint Scenario Ranking"
  )
  text(
    ordered$predicted_preference,
    bars,
    labels = sprintf("%.2f", ordered$predicted_preference),
    pos = 4,
    cex = 0.9
  )
  dev.off()
}


run_analysis <- function(repo_dir) {
  part_worths <- read_part_worths(file.path(repo_dir, "data", "aggregate_part_worths.csv"))
  profiles <- rank_product_profiles(part_worths)
  output_dir <- file.path(repo_dir, "outputs")
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  write.csv(profiles, file.path(output_dir, "ranked_product_profiles.csv"), row.names = FALSE)
  plot_profile_ranking(profiles, file.path(output_dir, "profile_preference.png"))
  invisible(profiles)
}


if (sys.nframe() == 0) {
  script_arg <- commandArgs(trailingOnly = FALSE)
  script_path <- sub("^--file=", "", script_arg[grep("^--file=", script_arg)])
  repo_dir <- normalizePath(file.path(dirname(script_path), ".."), mustWork = TRUE)
  profiles <- run_analysis(repo_dir)
  message(
    "Conjoint scenario analysis completed. Highest-scoring profile: ",
    profiles$profile[1],
    " (", profiles$predicted_preference[1], ")"
  )
}
