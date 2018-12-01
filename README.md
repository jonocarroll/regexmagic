
<!-- README.md is generated from README.Rmd. Please edit that file -->

# regexmagic

The goal of regexmagic is to provide an automated method for classifying
a vector of strings into groupings based on regex matches. This differs
from finding matches to a known regex within a vector, rather this helps
determine commonalities between strings.

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("jonocarroll/regexmagic")
```

## Example

Given the vector of strings in the (provided) example data, this package
will determine the groupings by regex

``` r
data(identifiers)
print(identifiers)
#>  [1] "XY-27121"     "AB.312.Z0_0"  "XX-00000"     "XY-20687"    
#>  [5] "50006955595R" "50000000000X" "XY-92612"     "50095973410R"
#>  [9] "50066227417R" "XY-86755"     "50018372252R" "AB.122.Z0_0" 
#> [13] "AB.935.Z0_1"  "XY-70476"     "50050222847R" "XY-74486"    
#> [17] "50015512791R" "XY-92436"     "50071469441R" "XY-67174"    
#> [21] "XY-47337"     "50095731925R" "50063296214R" "XY-21637"    
#> [25] "AB.010.Z0_1"  "AB.243.Z0_1"  "AB.363.Z0_1"  "XY-48420"    
#> [29] "AB.464.Z0_0"  "AB.424.Z0_0"  "AB.952.Z0_0"  "AB.654.Z0_0" 
#> [33] "XY-47937"     "AB.483.Z0_0"  "AB.391.Z0_1"  "AB.604.Z0_0" 
#> [37] "AX.000.Z0_0"  "50074522550R" "XY-89660"     "AB.898.Z0_1" 
#> [41] "50084037368R" "XY-03564"     "50079836993R" "AB.610.Z0_0" 
#> [45] "AB.214.Z0_1"  "AB.872.Z0_0"  "AB.497.Z0_1"  "AB.532.Z0_1" 
#> [49] "XY-30383"     "XY-24708"     "AB.213.Z0_1"  "XY-45418"    
#> [53] "AB.039.Z0_1"  "XY-88379"     "AB.634.Z0_1"  "AB.013.Z0_0" 
#> [57] "XY-38334"     "50018653451R" "AB.041.Z0_0"  "50021858177R"
#> [61] "XY-23592"     "AB.359.Z0_0"  "AB.058.Z0_0"  "50083386769R"
#> [65] "AB.710.Z0_1"
```

Within this example data there are 3 distinct patterns, along with 3
identifers which do not match exactly these patterns (confounders). The
goal is to produce a package which can detect the common patterns and
sort the identifiers into the correct groups.

## Methodology

First, common substrings are identified. These are allowed some
tolerance by which the identifiers may deviate. By default this is 95%
of samples should match the pattern.

With the example data, we can detect the common substrings

``` r
purrr::map(split_by_length(identifiers), find_common_substrings)
#> $`8`
#> [1] "XY-#####"
#> 
#> $`11`
#> [1] "AB.###.Z0_#"
#> 
#> $`12`
#> [1] "500#########"
```

This has become confused by the confounder in each group which destroys
the perfect relationship. We can improve this by lowering the
tolerance

``` r
(guess <- purrr::map(split_by_length(identifiers), find_common_substrings, tolerance = 0.9))
#> $`8`
#> [1] "XY-#####"
#> 
#> $`11`
#> [1] "AB.###.Z0_#"
#> 
#> $`12`
#> [1] "500########R"
```

This successfully identifies the common substrings, but leaves the
pattern determining the missing parts unknown. Next we need to determine
common patterns for these. We can search some given patterns to see if
each character matches this enought times. The pre-defined patterns are

``` r
known_patterns
#> [1] "[0-9]"       "[A-Z]"       "[[:punct:]]"
```

Appying these, one character at a time, and seeing which pattern matches
the most number of characters at a position, we can determine which
pattern best fits at that
position

``` r
(guess <- purrr::map(split_by_length(identifiers), detect_pattern, tolerance = 0.9))
#> $`8`
#> [1] "XY-[0-9][0-9][0-9][0-9][0-9]"
#> 
#> $`11`
#> [1] "AB\\.[0-9][0-9][0-9]\\.Z0_[0-9]"
#> 
#> $`12`
#> [1] "500[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]R"
```

How many identifiers match these
patterns?

``` r
matches <- purrr::map2(split_by_length(identifiers), guess, ~stringr::str_match(.x, .y))
names(matches) <- guess
matches
#> $`XY-[0-9][0-9][0-9][0-9][0-9]`
#>       [,1]      
#>  [1,] "XY-27121"
#>  [2,] NA        
#>  [3,] "XY-20687"
#>  [4,] "XY-92612"
#>  [5,] "XY-86755"
#>  [6,] "XY-70476"
#>  [7,] "XY-74486"
#>  [8,] "XY-92436"
#>  [9,] "XY-67174"
#> [10,] "XY-47337"
#> [11,] "XY-21637"
#> [12,] "XY-48420"
#> [13,] "XY-47937"
#> [14,] "XY-89660"
#> [15,] "XY-03564"
#> [16,] "XY-30383"
#> [17,] "XY-24708"
#> [18,] "XY-45418"
#> [19,] "XY-88379"
#> [20,] "XY-38334"
#> [21,] "XY-23592"
#> 
#> $`AB\\.[0-9][0-9][0-9]\\.Z0_[0-9]`
#>       [,1]         
#>  [1,] "AB.312.Z0_0"
#>  [2,] "AB.122.Z0_0"
#>  [3,] "AB.935.Z0_1"
#>  [4,] "AB.010.Z0_1"
#>  [5,] "AB.243.Z0_1"
#>  [6,] "AB.363.Z0_1"
#>  [7,] "AB.464.Z0_0"
#>  [8,] "AB.424.Z0_0"
#>  [9,] "AB.952.Z0_0"
#> [10,] "AB.654.Z0_0"
#> [11,] "AB.483.Z0_0"
#> [12,] "AB.391.Z0_1"
#> [13,] "AB.604.Z0_0"
#> [14,] NA           
#> [15,] "AB.898.Z0_1"
#> [16,] "AB.610.Z0_0"
#> [17,] "AB.214.Z0_1"
#> [18,] "AB.872.Z0_0"
#> [19,] "AB.497.Z0_1"
#> [20,] "AB.532.Z0_1"
#> [21,] "AB.213.Z0_1"
#> [22,] "AB.039.Z0_1"
#> [23,] "AB.634.Z0_1"
#> [24,] "AB.013.Z0_0"
#> [25,] "AB.041.Z0_0"
#> [26,] "AB.359.Z0_0"
#> [27,] "AB.058.Z0_0"
#> [28,] "AB.710.Z0_1"
#> 
#> $`500[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]R`
#>       [,1]          
#>  [1,] "50006955595R"
#>  [2,] NA            
#>  [3,] "50095973410R"
#>  [4,] "50066227417R"
#>  [5,] "50018372252R"
#>  [6,] "50050222847R"
#>  [7,] "50015512791R"
#>  [8,] "50071469441R"
#>  [9,] "50095731925R"
#> [10,] "50063296214R"
#> [11,] "50074522550R"
#> [12,] "50084037368R"
#> [13,] "50079836993R"
#> [14,] "50018653451R"
#> [15,] "50021858177R"
#> [16,] "50083386769R"
```

## Working Prototype

Now that the pieces seem to work, we can apply the categorisations in a
function, returning (invisibly) a list of matches and non-matches, and
printing a summary to the screen

``` r
results <- categorise_regex(identifiers, tolerance = 0.9)
#>    ** CATEGORISATION SUMMARY **
#>    ** Detected 3 categories and matched
#>     62 / 65 ( 0.954% ) strings **
#>   nchar: 8
#> example: XY-27121
#>   regex: XY-[0-9][0-9][0-9][0-9][0-9]
#>   match: 20 / 21 ( 95.2% )
#>   nchar: 11
#> example: AB.312.Z0_0
#>   regex: AB\.[0-9][0-9][0-9]\.Z0_[0-9]
#>   match: 27 / 28 ( 96.4% )
#>   nchar: 12
#> example: 50006955595R
#>   regex: 500[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]R
#>   match: 15 / 16 ( 93.8% )
```

where we see the single confounder in each case is not matched.

The actual categorisations are also available

``` r
results
#> $`8`
#> $`8`$regex
#> [1] "XY-[0-9][0-9][0-9][0-9][0-9]"
#> 
#> $`8`$matches
#>  [1] "XY-27121" "XY-20687" "XY-92612" "XY-86755" "XY-70476" "XY-74486"
#>  [7] "XY-92436" "XY-67174" "XY-47337" "XY-21637" "XY-48420" "XY-47937"
#> [13] "XY-89660" "XY-03564" "XY-30383" "XY-24708" "XY-45418" "XY-88379"
#> [19] "XY-38334" "XY-23592"
#> 
#> $`8`$nonmatches
#> [1] "XX-00000"
#> 
#> 
#> $`11`
#> $`11`$regex
#> [1] "AB\\.[0-9][0-9][0-9]\\.Z0_[0-9]"
#> 
#> $`11`$matches
#>  [1] "AB.312.Z0_0" "AB.122.Z0_0" "AB.935.Z0_1" "AB.010.Z0_1" "AB.243.Z0_1"
#>  [6] "AB.363.Z0_1" "AB.464.Z0_0" "AB.424.Z0_0" "AB.952.Z0_0" "AB.654.Z0_0"
#> [11] "AB.483.Z0_0" "AB.391.Z0_1" "AB.604.Z0_0" "AB.898.Z0_1" "AB.610.Z0_0"
#> [16] "AB.214.Z0_1" "AB.872.Z0_0" "AB.497.Z0_1" "AB.532.Z0_1" "AB.213.Z0_1"
#> [21] "AB.039.Z0_1" "AB.634.Z0_1" "AB.013.Z0_0" "AB.041.Z0_0" "AB.359.Z0_0"
#> [26] "AB.058.Z0_0" "AB.710.Z0_1"
#> 
#> $`11`$nonmatches
#> [1] "AX.000.Z0_0"
#> 
#> 
#> $`12`
#> $`12`$regex
#> [1] "500[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]R"
#> 
#> $`12`$matches
#>  [1] "50006955595R" "50095973410R" "50066227417R" "50018372252R"
#>  [5] "50050222847R" "50015512791R" "50071469441R" "50095731925R"
#>  [9] "50063296214R" "50074522550R" "50084037368R" "50079836993R"
#> [13] "50018653451R" "50021858177R" "50083386769R"
#> 
#> $`12`$nonmatches
#> [1] "50000000000X"
```

## Yet To Do

  - reduce ‘runs’ of patterns, e.g. `[0-9][0-9]` to `[0-9]{2}`
  - find shortest regex which matches, e.g. `[AB]` vs `[A-Z]`
  - variable-length identifiers
  - multiple identifiers with a given length
  - most testing
  - documentation
