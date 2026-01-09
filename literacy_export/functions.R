# functions.R
library(dplyr)
library(readr)
library(purrr)
library(stringr)

get_df_list <- function(pattern) {
  file_list <-
    list.files("data", pattern = pattern, full.names = TRUE)
  
  # grab the beginning of the year and school class
  list_dfs <-
    purrr::map(
      file_list,
      \(x) read_csv(x) %>% dplyr::mutate(
        year = str_extract(x, pattern = "(?<=data/).*(?=-)"),
        group = str_extract(x, pattern = "(?<=CIR).*(?=Survey)") %>% trimws()
      )
    )
  
  return(list_dfs)
}

nations_report_card <- function(url) {
  response <- httr::GET(
    url
  )
  
  data <- rawToChar(response$content) %>%
    jsonlite::fromJSON()
  
  if (data$status == 200) {
    print("Success")
  }
  
  return(data$result)
}

align_names <- function(x) {
  
  case_match(x,
             "Latitude" ~ "lat",
             "Longitude" ~ "lon",
             "Country" ~ "country",
             "City" ~ "city",
             "State/Region" ~ "state",
             "Postal" ~ "zip",
             c("Select your state and school from the drop-down menu below",
               "Select your school from the drop-down menu below. ",
               "Please select your school and state from the drop-down menu below",
               "Please select your school and state from the drop-down menu below",
               "Please select your state and school from the drop-down menu.", 
               "Please select your state and school from the drop-down menu below.",
               "Please select your state and school from the drop-down menu below.",
               "Please select your technology center and state from the drop-down menu below",
               "Please select your state and technology center from the drop-down menu below.",
               "Please select your technology center and state from the drop-down menu below",
               "Select your center from the drop-down menu below. "
             ) ~ "school",
             .default = x
  )
}

# make it possible to combine years
align_years <- function(..., question) {
  
  # not all used
  keep_cols <-
    c("lat",
      "lon",
      "country",
      "city",
      "state",
      "school",
      "year",
      "group")
  
  # using the naming fun
  rename_with(..., align_names) %>%
    
    # remove other cols
    dplyr::select(any_of(keep_cols), 
                  ends_with(question),
                  race = dplyr::contains("race"),
                  gender = dplyr::contains("gender?"),
                  language = dplyr::contains("best language"),
                  mother_ed = dplyr::contains("mother")) %>%
    
    # remove row if all NAs
    dplyr::filter(if_any(ends_with(question), ~ !is.na(.x))) %>%
    
    # words to numeric, scaled 1 to 4?
    dplyr::mutate(across(all_of(ends_with(question)), ~ case_match(
      .,
      c("Never") ~ 1,
      c("Sometimes", "Some of the time", "Some of the Time") ~ 2,
      c("Often", "Most of the time", "Most of the Time") ~ 3,
      c("Always", "All of the time", "All of the Time") ~ 4
    ))) %>%
    
    # grouping for calculations and to keep some vars
    group_by(group, year, school) %>%

    # get mean across row and then for each group
    dplyr::mutate(score = rowMeans(pick(all_of(
      ends_with(question)
    )), na.rm = TRUE)) %>%
    
    rename_with(.cols = all_of(ends_with(question)), 
                \(x) str_extract(x, ".*?(?=(\\.?:.*|$))"))
      # dplyr::select(group, year, school, score)
    # 
    # summarise(mean_score = mean(score, na.rm = TRUE),
    #           n = n()) # also get n
}

# t test from summary statistics
t.test2 <- function(m1,m2,s1,s2,n1,n2,m0=0,equal.variance=FALSE)
{
  if( equal.variance==FALSE ) 
  {
    se <- sqrt( (s1^2/n1) + (s2^2/n2) )
    # welch-satterthwaite df
    df <- ( (s1^2/n1 + s2^2/n2)^2 )/( (s1^2/n1)^2/(n1-1) + (s2^2/n2)^2/(n2-1) )
  } else
  {
    # pooled standard deviation, scaled by the sample sizes
    se <- sqrt( (1/n1 + 1/n2) * ((n1-1)*s1^2 + (n2-1)*s2^2)/(n1+n2-2) ) 
    df <- n1+n2-2
  }      
  t <- (m1-m2-m0)/se 
  dat <- list(m1-m2, se, t, 2*pt(-abs(t), df), df)    
  names(dat) <- c("diff", "stde", "t", "pval", "df")
  return(dat) 
}
