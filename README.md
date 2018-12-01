
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
#>  [1] "XY-51363"     "XY-31619"     "XY-89737"     "XY-09937"    
#>  [5] "XY-77443"     "XY-68456"     "XY-13409"     "XY-88903"    
#>  [9] "XY-51870"     "XY-49025"     "XY-62439"     "XY-10943"    
#> [13] "XY-10659"     "XY-60140"     "XY-42971"     "XY-46497"    
#> [17] "XY-31284"     "XY-46718"     "XY-95510"     "XY-81092"    
#> [21] "50013445805R" "50066649487R" "50058407716R" "50053687313R"
#> [25] "50098799603R" "50021033163R" "50096311935R" "50078509730R"
#> [29] "50008861379R" "50062629142R" "50008564873R" "50096054059R"
#> [33] "50075276864R" "50043489179R" "50093391935R" "AB.574.Z0_0" 
#> [37] "AB.360.Z0_1"  "AB.251.Z0_0"  "AB.626.Z0_0"  "AB.983.Z0_0" 
#> [41] "AB.843.Z0_0"  "AB.066.Z0_1"  "AB.392.Z0_1"  "AB.208.Z0_1" 
#> [45] "AB.968.Z0_0"  "AB.350.Z0_0"  "AB.578.Z0_0"  "AB.706.Z0_0" 
#> [49] "AB.591.Z0_0"  "AB.675.Z0_1"  "AB.554.Z0_0"  "AB.122.Z0_1" 
#> [53] "AB.715.Z0_1"  "AB.534.Z0_0"  "AB.905.Z0_1"  "AB.545.Z0_1" 
#> [57] "AB.194.Z0_1"  "AB.976.Z0_1"  "AB.045.Z0_1"  "AB.774.Z0_0" 
#> [61] "AB.744.Z0_0"  "AB.147.Z0_0"  "XX-00000"     "50000000000X"
#> [65] "AX.000.Z0_0"
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
#>  [1,] "XY-51363"
#>  [2,] "XY-31619"
#>  [3,] "XY-89737"
#>  [4,] "XY-09937"
#>  [5,] "XY-77443"
#>  [6,] "XY-68456"
#>  [7,] "XY-13409"
#>  [8,] "XY-88903"
#>  [9,] "XY-51870"
#> [10,] "XY-49025"
#> [11,] "XY-62439"
#> [12,] "XY-10943"
#> [13,] "XY-10659"
#> [14,] "XY-60140"
#> [15,] "XY-42971"
#> [16,] "XY-46497"
#> [17,] "XY-31284"
#> [18,] "XY-46718"
#> [19,] "XY-95510"
#> [20,] "XY-81092"
#> [21,] NA        
#> 
#> $`AB\\.[0-9][0-9][0-9]\\.Z0_[0-9]`
#>       [,1]         
#>  [1,] "AB.574.Z0_0"
#>  [2,] "AB.360.Z0_1"
#>  [3,] "AB.251.Z0_0"
#>  [4,] "AB.626.Z0_0"
#>  [5,] "AB.983.Z0_0"
#>  [6,] "AB.843.Z0_0"
#>  [7,] "AB.066.Z0_1"
#>  [8,] "AB.392.Z0_1"
#>  [9,] "AB.208.Z0_1"
#> [10,] "AB.968.Z0_0"
#> [11,] "AB.350.Z0_0"
#> [12,] "AB.578.Z0_0"
#> [13,] "AB.706.Z0_0"
#> [14,] "AB.591.Z0_0"
#> [15,] "AB.675.Z0_1"
#> [16,] "AB.554.Z0_0"
#> [17,] "AB.122.Z0_1"
#> [18,] "AB.715.Z0_1"
#> [19,] "AB.534.Z0_0"
#> [20,] "AB.905.Z0_1"
#> [21,] "AB.545.Z0_1"
#> [22,] "AB.194.Z0_1"
#> [23,] "AB.976.Z0_1"
#> [24,] "AB.045.Z0_1"
#> [25,] "AB.774.Z0_0"
#> [26,] "AB.744.Z0_0"
#> [27,] "AB.147.Z0_0"
#> [28,] NA           
#> 
#> $`500[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]R`
#>       [,1]          
#>  [1,] "50013445805R"
#>  [2,] "50066649487R"
#>  [3,] "50058407716R"
#>  [4,] "50053687313R"
#>  [5,] "50098799603R"
#>  [6,] "50021033163R"
#>  [7,] "50096311935R"
#>  [8,] "50078509730R"
#>  [9,] "50008861379R"
#> [10,] "50062629142R"
#> [11,] "50008564873R"
#> [12,] "50096054059R"
#> [13,] "50075276864R"
#> [14,] "50043489179R"
#> [15,] "50093391935R"
#> [16,] NA
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
#> example: XY-51363
#>   regex: XY-[0-9][0-9][0-9][0-9][0-9]
#>   match: 20 / 21 ( 95.2% )
#>   nchar: 11
#> example: AB.574.Z0_0
#>   regex: AB\.[0-9][0-9][0-9]\.Z0_[0-9]
#>   match: 27 / 28 ( 96.4% )
#>   nchar: 12
#> example: 50013445805R
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
#>  [1] "XY-51363" "XY-31619" "XY-89737" "XY-09937" "XY-77443" "XY-68456"
#>  [7] "XY-13409" "XY-88903" "XY-51870" "XY-49025" "XY-62439" "XY-10943"
#> [13] "XY-10659" "XY-60140" "XY-42971" "XY-46497" "XY-31284" "XY-46718"
#> [19] "XY-95510" "XY-81092"
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
#>  [1] "AB.574.Z0_0" "AB.360.Z0_1" "AB.251.Z0_0" "AB.626.Z0_0" "AB.983.Z0_0"
#>  [6] "AB.843.Z0_0" "AB.066.Z0_1" "AB.392.Z0_1" "AB.208.Z0_1" "AB.968.Z0_0"
#> [11] "AB.350.Z0_0" "AB.578.Z0_0" "AB.706.Z0_0" "AB.591.Z0_0" "AB.675.Z0_1"
#> [16] "AB.554.Z0_0" "AB.122.Z0_1" "AB.715.Z0_1" "AB.534.Z0_0" "AB.905.Z0_1"
#> [21] "AB.545.Z0_1" "AB.194.Z0_1" "AB.976.Z0_1" "AB.045.Z0_1" "AB.774.Z0_0"
#> [26] "AB.744.Z0_0" "AB.147.Z0_0"
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
#>  [1] "50013445805R" "50066649487R" "50058407716R" "50053687313R"
#>  [5] "50098799603R" "50021033163R" "50096311935R" "50078509730R"
#>  [9] "50008861379R" "50062629142R" "50008564873R" "50096054059R"
#> [13] "50075276864R" "50043489179R" "50093391935R"
#> 
#> $`12`$nonmatches
#> [1] "50000000000X"
```

## Yet To Do

  - variable-length identifiers
  - multiple identifiers with a given length
  - most testing
  - documentation
