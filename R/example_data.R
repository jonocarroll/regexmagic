## Create the example data to be used for testing
## This is reproducibly constructed, but should
## appear somewhat random, with at least some
## strings not matching to the given patterns.
##
## In the inital version of this, the lengths of the strings
## will determine an initial split, but this should be
## relaxed in further iterations.
set.seed(1)

make_string_1 <- function() {
  paste0("XY-", paste0(sample(0:9, 5, replace = TRUE), collapse = ""))
}

make_string_2 <- function() {
  paste0("500", paste0(sample(0:9, 8, replace = TRUE), collapse = ""), "R")
}

make_string_3 <- function() {
  paste0("AB.", paste0(sample(0:9, 3, replace = TRUE), collapse = ""), ".Z0_", sample(0:1, 1))
}

identifiers <- c(
  replicate(20, make_string_1()),
  replicate(15, make_string_2()),
  replicate(27, make_string_3()),
  "XX-00000",
  "50000000000X",
  "AX.000.Z0_0"
)

## shuffle the data
identifiers <- sample(identifiers)

