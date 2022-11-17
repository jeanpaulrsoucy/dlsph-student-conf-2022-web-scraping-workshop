# Project 2: Who owns Ontario's long-term care homes? #
# Author: Jean-Paul R. Soucy (https://github.com/jeanpaulrsoucy) #

# load packages
library(dplyr)
library(readr)
library(rvest)
library(ggplot2)

# create directories
# dir.create("ltc-homes", showWarnings = FALSE)
# dir.create(file.path("ltc-homes", "homes"), showWarnings = FALSE)
# dir.create(file.path("ltc-homes", "inspections"), showWarnings = FALSE)

# download and read webpage with list of homes
# download.file("http://publicreporting.ltchomes.net/en-ca/Search_Selection.aspx", file.path("ltc-homes", "home-list.html"))
homes <- read_html(file.path("ltc-homes", "home-list.html"))

# extract links to pages for individual homes
homes <- html_element(homes, "#ctl00_ContentPlaceHolder1_rsResults")
homes <- html_elements(homes, "a")
homes <- data.frame(
  home_name = html_text2(homes),
  url = paste0("http://publicreporting.ltchomes.net/en-ca/", html_attr(homes, "href"))
)

# remove homes with no info
# http://publicreporting.ltchomes.net/en-ca/homeprofile.aspx?Home=7089
# http://publicreporting.ltchomes.net/en-ca/homeprofile.aspx?Home=C604
homes <- homes[!homes$home_name %in% c(
  "LENNOX AND ADDINGTON COUNTY GENERAL HOSPITAL",
  "ST. JOSEPH'S MOTHER HOUSE (MARTHA WING)"), ]

# download webpages - home information
# for (i in 1:nrow(homes)) {
#   download.file(homes[i, "url"], file.path("ltc-homes", "homes", paste0(i, ".html")), quiet = TRUE)
# }

# download webpages - home inspections
# for (i in 1:nrow(homes)) {
#   download.file(paste0(homes[i, "url"], "&tab=1"), file.path("ltc-homes", "inspections", paste0(i, ".html")), quiet = TRUE)
# }

# extract data from home information and inspection webpages
for (i in 1:nrow(homes)) {
  # read webpage - home information
  home_info <- read_html(file.path("ltc-homes", "homes", paste0(i, ".html")))
  # extract licensee
  homes[i, "licensee"] <- html_text2(html_elements(home_info, ".Profilerow_col2")[4])
  # extract home type
  homes[i, "home_type"] <- html_text2(html_elements(home_info, ".Profilerow_col2")[6])
  # extract number of beds
  homes[i, "beds"] <- parse_number(html_text2(html_elements(home_info, ".Profilerow_col2")[7]))
  # extract additional information (contains info on home closures and mergers)
  homes[i, "additional_information"] <- html_text2(html_elements(home_info, ".Profilerow_col2")[13])
  # indicate if home is closed or open
  homes[i, "status"] <- ifelse(grepl("closed|merged", homes[i, "additional_information"], ignore.case = TRUE), "Closed", "Open")
  # read webpage - home inspections
  home_inspection <- read_html(file.path("ltc-homes", "inspections", paste0(i, ".html")))
  # extract number of inspections of type "Complaints Inspection", "Critical Incident Inspection", "Follow-Up Inspection"
  inspections <- html_text2(html_elements(home_inspection, ".divInspectionTypeDataCol"))
  inspections <- inspections[grep("Complaints Inspection|Critical Incident Inspection|Follow-Up Inspection", inspections)]
  homes[i, "inspections"] <- length(inspections)
  # print home name to signal completion
  print(homes[i, "home_name"])
}

# write results to CSV
write.csv(homes, file.path("ltc-homes", "homes.csv"), row.names = FALSE)

# filter out closed homes
homes <- homes[homes$status == "Open", ]

# a small number of homes are missing data on home_type
homes[homes$home_type == "", ]

# fix missing home_type value
homes[homes$home_name == "ALGOMA MANOR NURSING HOME", "home_type"] <- "Non-Profit"
homes[homes$home_name == "MALDEN PARK CONTINUING CARE CENTRE", "home_type"] <- "Non-Profit"

# aggregate home data by licensee
homes_agg <- group_by(homes, licensee, home_type)
homes_agg <- summarize(homes_agg, count = n(), beds = sum(beds), inspections = sum(inspections), .groups = "drop")

# a few licensees seem to own homes of different types
# we will ignore this for now and treat them as separate
homes_agg[homes_agg$licensee %in% names(table(homes_agg$licensee)[table(homes_agg$licensee) > 1]), c("licensee", "home_type", "count")]

# how many unique licensees?
nrow(homes_agg)

# histogram of number of homes owned by licensee
hist(homes_agg$count, breaks = 1:max(homes_agg$count), freq = FALSE)

# top 20 licensees by number of homes owned (use bed counts to break ties)
top_20_count <- head(arrange(homes_agg, desc(count), desc(beds)), 20)
top_20_count

# what percentage of homes are owned by the top 20 licensees?
sum(top_20_count$count) / sum(homes_agg$count) * 100

# top 20 licensees by number of beds operated
top_20_beds <- head(arrange(homes_agg, desc(beds)), 20)
top_20_beds

# how many licensees are in the top 20 home owners but NOT the top 20 bed operators?
top_20_count[!top_20_count$licensee %in% top_20_beds$licensee, ]

# which licensees have the most inspections (complaints, critical incident, follow-up) per home?
homes_agg$inspections_per_home <- homes_agg$inspections / homes_agg$count
top_20_inspections <- head(arrange(homes_agg, desc(inspections_per_home)), 20)
top_20_inspections[, c("licensee", "home_type", "count", "inspections_per_home")] # top 20

# which licensees have the least inspections?
bottom_20_inspections <- tail(arrange(homes_agg, desc(inspections_per_home)), 20)
bottom_20_inspections[, c("licensee", "home_type", "count", "inspections_per_home")] # bottom 20

# plot rate of inspections by home type
inspections_by_home_type <- group_by(homes, home_type)
inspections_by_home_type <- summarize(inspections_by_home_type, inspections = mean(inspections), .groups = "drop")
ggplot(data = inspections_by_home_type, aes(x = home_type, y = inspections)) +
  geom_bar(stat = "identity") +
  theme_classic() +
  labs(x = "Home type", y = "Average number of inspections", title = "Average number of inspections by home type")

# plot number of beds by home type
beds_by_home_type <- group_by(homes, home_type)
beds_by_home_type <- summarize(beds_by_home_type, beds = mean(beds), .groups = "drop")
ggplot(data = beds_by_home_type, aes(x = home_type, y = beds)) +
  geom_bar(stat = "identity") +
  theme_classic() +
  labs(x = "Home type", y = "Average number of beds", title = "Average number of beds by home type")
