missing_char <- "#"

#' @export
known_patterns <- c(
  "[0-9]",
  "[A-Z]",
  "[[:punct:]]"
)

#' Split a vector by character count
#'
#' @md
#' @param s vector of strings
#'
#' @return `list` of strings grouped by length
#' @export
split_by_length <- function(s) {
  split(s, nchar(s))
}

#' @export
find_common_substrings <- function(s, tolerance = 0.95) {
  ## split by character
  ## assumes already split by character length
  chardf <- t(as.data.frame(purrr::map(s, ~strsplit(.x, NULL)[[1]])))
  most_matching <- apply(chardf, 2, function(x) names(which.max(table(x))))
  prop_matching <- sapply(seq_len(ncol(chardf)), function(x) sum(chardf[,x] == most_matching[x])/nrow(chardf))
  exact_matches <- prop_matching >= tolerance
  common_pattern <- paste0(ifelse(exact_matches, most_matching, missing_char), collapse = "")
  return(common_pattern)
}

#' @export
detect_pattern <- function(s, ...) {

  charvec <- strsplit(find_common_substrings(s, ...), NULL)[[1]]
  unknown_symbols <- which(charvec == missing_char)
  best_pat <- unknown_symbols[NA]
  for (symbol in unknown_symbols) {
    s_char <- purrr::map_chr(strsplit(s, NULL), symbol)
    pat <- known_patterns[NA]
    pat <- sapply(known_patterns, function(kp) sum(!is.na(purrr::map_chr(s_char, ~stringr::str_match(.x, kp)))))
    best_pat[symbol] <- known_patterns[which.max(pat)]
  }

  detected_pattern <- escape_regex(paste0(ifelse(charvec == missing_char, best_pat, charvec), collapse = ""))
  return(detected_pattern)

}

#' @export
categorise_regex <- function(strings, tolerance = 0.95) {
  string_list <- split_by_length(strings)
  guess <- purrr::map(string_list, detect_pattern, tolerance = tolerance)
  matches <- purrr::map2(string_list, guess, ~stringr::str_match(.x, .y))
  ## remove non-matches
  matches <- purrr::map(matches, ~.x[!is.na(.x)])
  nonmatches <- purrr::map2(string_list, matches, ~.x[! .x %in% .y])

  result <- purrr::pmap(list(guess, matches, nonmatches),
                           ~list(regex = ..1, matches = ..2, nonmatches = ..3))

  message("   ** CATEGORISATION SUMMARY **")



  message("   ** Detected ", length(result), " categories and matched\n    ",
          length(unlist(purrr::map(result, "matches"))) ," / ", (
            length(unlist(purrr::map(result, "nonmatches"))) + length(unlist(purrr::map(result, "matches")))),
          " ( ",
          format(length(unlist(purrr::map(result, "matches"))) / (
            length(unlist(purrr::map(result, "nonmatches"))) + length(unlist(purrr::map(result, "matches")))), digits = 3),
          "% ) strings **\n")
  purrr::walk2(result, names(result), ~{
    n_match <- length(.x$matches)
    n_nonmatch <- length(.x$nonmatch)
    n_results <- n_match + n_nonmatch
    message("  nchar: ", .y,
            "\nexample: ", .x$matches[[1]],
            "\n  regex: ", .x$regex,
            "\n  match: ", n_match, " / ", n_results,
            " ( ", format(100 * n_match / n_results, digits = 3), "% )\n")
  })

  return(invisible(result))
}

#' @export
escape_regex <- function(s) {
    gsub(".", "\\.", s, fixed = TRUE)
}


