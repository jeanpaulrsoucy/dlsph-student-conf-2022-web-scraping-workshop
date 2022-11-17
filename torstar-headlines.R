# Project 3: Toronto Star headlines throughout the pandemic #
# Author: Jean-Paul R. Soucy (https://github.com/jeanpaulrsoucy) #

# load packages
library(jsonlite)
library(dplyr)
library(rvest)
library(ggplot2)
library(scales)

# create directories
# dir.create("torstar-headlines", showWarnings = FALSE)
# dir.create(file.path("torstar-headlines", "headlines"), showWarnings = FALSE)

# generate list of dates: noon (Toronto time) for each day of October for 2020, 2021, 2022
urls <- data.frame(
  date = paste(c(
    seq.Date(from = as.Date("2020-10-01"), to = as.Date("2020-10-31"), by = "day"),
    seq.Date(from = as.Date("2021-10-01"), to = as.Date("2021-10-31"), by = "day"),
    seq.Date(from = as.Date("2022-10-01"), to = as.Date("2022-10-31"), by = "day")
  ), "12:00")
)
urls$date <- as.POSIXct(urls$date, tz = "America/Toronto", format = "%Y-%m-%d %H:%M") # add time zone
urls$date <- strftime(urls$date, "%Y%m%d%H%M", tz = "UTC") # convert to format expected by Internet Archive API

# query Internet Archive API for snapshots closest to our vector of dates
# we are interested in the front page of The Toronto Star (thestar.com)
# https://web.archive.org/web/20220000000000*/thestar.com
# however, most of these snapshots are redirects which don't appear on the API
# so instead, we will query the redirect page (thestar.com/?redirect=true)
# https://web.archive.org/web/20220000000000*/thestar.com/?redirect=true
# there is still at least one snapshot for almost every single day
# for (i in 1:nrow(urls)) {
#   # query Wayback Machine API
#   query <- fromJSON(paste0(
#     "https://archive.org/wayback/available?url=thestar.com/?redirect=true&timestamp=", urls[i, "date"]))
#   # check if query succeeded
#   # the Wayback Machine API is finicky - if failed, try to add 'http://' to query
#   if (length(query$archived_snapshots) == 0) {
#     query <- fromJSON(paste0(
#       "https://archive.org/wayback/available?url=http://thestar.com/?redirect=true&timestamp=", urls[i, "date"]))
#   }
#   # extract URL
#   urls[i, "url"] <- query$archived_snapshots$closest$url
#   # print timestamp to signal successful query
#   print(urls[i, "date"])
# }

# download archived webpages
# for (i in 1:nrow(urls)) {
#   download.file(urls[i, "url"], file.path("torstar-headlines", "headlines", paste0(i, ".html")), quiet = TRUE)
# }

# extract 'front page' headlines (editor's picks)
headlines <- lapply(1:nrow(urls), function(i) {
  # read HTML
  d <- read_html(file.path("torstar-headlines", "headlines", paste0(i, ".html")))
  # extract headlines from editor's picks
  d <- html_element(d, "[data-lpos=editors-picks]")
  d <- html_text2(rvest::html_elements(d, ".c-mediacard__heading"))
  # format output
  data.frame(
    date = as.Date(urls[i, "date"], "%Y%m%d%H%M"),
    year = as.integer(substr(urls[i, "date"], 1, 4)),
    headline = d
  )
})
headlines <- bind_rows(headlines)

# check for duplicated headlines
headlines[duplicated(headlines$headline), ]

# remove duplicate headlines (keep first occurance of headline)
headlines <- headlines[!duplicated(headlines$headline), ]

# write headlines to CSV
write.csv(headlines, file.path("torstar-headlines", "headlines.csv"))

# generate variable: is headline probably pandemic-related
# first, define list of terms that are probably pandemic-related
# this list will miss some headlines and result in some false positives
terms <- c(
  "COVID", "virus", "pandemic",
  "lockdown", "mask", "wave",
  "cases", "infections", "restrictions",
  "vaccine", "vaccination", "vaccinated",
  "hospitalization", "hybrid", "essential")
terms <- paste(terms, collapse = "|") # collapse to regex string
headlines$pandemic <- grepl(
  terms,
  headlines$headline,
  ignore.case = TRUE)

# aggregate headline data by year and plot
headlines_agg <- count(headlines, year, pandemic)
ggplot(data = headlines_agg, aes(x = year, y = n, fill = pandemic)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_y_continuous(labels = label_percent()) +
  theme_classic() +
  theme(legend.position = "bottom") +
  labs(
    x = "Year",
    y = "Percent of front-page headlines (%)",
    fill = "Pandemic-related?",
    title = "Pandemic-related Toronto Star headlines in October, 2020–2022")

# what if we add some general health care-related terms?
# many of these stories will be indirectly related to COVID
# but higher probability of false positives
terms2 <- c(
  "health care", "ICU", "intensive care",
  "hospital", "ambulance", "bed",
  "doctor", "phyisician", "nurse",
  "nursing", "surgery", "LTC",
  "long-term-care"
)
terms2 <- paste(c(terms, terms2), collapse = "|") # collapse to regex string
headlines$pandemic2 <- grepl(
  terms2,
  headlines$headline,
  ignore.case = TRUE)

# aggregate headline data by year and plot
headlines_agg2 <- count(headlines, year, pandemic, pandemic2)
headlines_agg2 <- mutate(headlines_agg2, category = case_when(
  !pandemic & !pandemic2 ~ "Other",
  pandemic & pandemic2 ~ "Pandemic",
  !pandemic & pandemic2 ~ "Healthcare"))
headlines_agg2$category <- factor(headlines_agg2$category,
                                  levels = c("Other", "Healthcare", "Pandemic"))
ggplot(data = headlines_agg2, aes(x = year, y = n, fill = category)) +
  geom_bar(stat = "identity", position = "fill") +
  scale_y_continuous(labels = label_percent()) +
  theme_classic() +
  theme(legend.position = "bottom") +
  labs(
    x = "Year",
    y = "Percent of front-page headlines (%)",
    fill = "Category",
    title = "Toronto Star headlines in October, 2020–2022")
