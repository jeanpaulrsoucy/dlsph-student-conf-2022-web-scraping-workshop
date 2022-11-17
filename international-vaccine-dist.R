# Project 1: Canada's international COVID-19 vaccine distribution #
# Author: Jean-Paul R. Soucy (https://github.com/jeanpaulrsoucy) #

# load packages
library(rvest)
library(countrycode)
library(ggplot2)
library(scales)

# create directories
# dir.create("international-vaccine-dist", showWarnings = FALSE)

# download and read webpage with international vaccine distribution data
# download.file("https://www.canada.ca/en/public-health/services/diseases/coronavirus-disease-covid-19/vaccines/supply-donation.html",
#               file.path("international-vaccine-dist", "international-vaccine-dist.html"))
vax <- read_html(file.path("international-vaccine-dist", "international-vaccine-dist.html"))

# extract HTML tables
vax <- html_table(vax)
vax <- vax[[1]] # subset first (and only) table

# convert dose number column to integers
vax$doses <- as.integer(gsub(",", "", vax$`Number of doses shipped`))

# add 'continent' variable for easier plotting
vax$continent <- countrycode(vax$Country, origin = "country.name", destination = "continent")

# add 'year' variable
vax$year <- factor(substr(vax$`Date delivered`, 1, 4), levels = c("2021", "2022"))

# in 'mechanism' column, fix inconsistent spelling of 'bilateral agreement'
vax$Mechanism <- sub("Bi-lateral agreement", "Bilateral agreement", vax$Mechanism)

# bar plot: number of doses by continent
ggplot(data = vax, aes(x = continent, y = doses)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(
    expand = c(0, NA),
    labels = label_number(scale = 1e-6, suffix = " M")) +
  theme_classic() +
  labs(x = "Continent", y = "Millions of doses sent")

# stacked bar plot: number of doses by continent and vaccine manufacturer
ggplot(data = vax, aes(x = continent, y = doses, fill = `Vaccine manufacturer`)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(
    expand = c(0, NA),
    labels = label_number(scale = 1e-6, suffix = " M")) +
  theme_classic() +
  theme(legend.position = "bottom") +
  guides(fill = guide_legend(title.position = "top", title.hjust = 0.5)) +
  labs(x = "Continent", y = "Millions of doses sent", fill = "Manufacturer")

# stacked bar plot: number of doses by continent and mechanism
ggplot(data = vax, aes(x = continent, y = doses, fill = Mechanism)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(
    expand = c(0, NA),
    labels = label_number(scale = 1e-6, suffix = " M")) +
  theme_classic() +
  theme(legend.position = "bottom") +
  guides(fill = guide_legend(title.position = "top", title.hjust = 0.5)) +
  labs(x = "Continent", y = "Millions of doses sent", fill = "Mechanism")

# stacked bar plot: number of doses by year and continent
ggplot(data = vax, aes(x = year, y = doses, fill = continent)) +
  geom_bar(stat = "identity") +
  scale_y_continuous(
    expand = c(0, NA),
    labels = label_number(scale = 1e-6, suffix = " M")) +
  theme_classic() +
  theme(legend.position = "bottom") +
  guides(fill = guide_legend(title.position = "top", title.hjust = 0.5)) +
  labs(x = "Year", y = "Millions of doses sent", fill = "Continent")
