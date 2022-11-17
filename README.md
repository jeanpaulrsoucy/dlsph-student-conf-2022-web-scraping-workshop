# Web scraping for public health

This interactive workshop was presented at the [Dalla Lana School of Public Health 15th Annual Student-Led Conference](https://www.dlsph.utoronto.ca/students/current-students/studentledconference/) (**What's Next for Public Health?: Looking to the Future**) on November 19, 2022.

The workshop description is below:

> The Internet contains a wealth of information relevant to pressing public health issues, but it is often not available in a convenient format such as a downloadable spreadsheet. In this interactive workshop, you will learn how to use R to unlock sources of data that would be tedious or impossible to collect manually. The principles of web scraping will be demonstrated through several examples including extracting COVID-19 data, investigating Ontario's long-term care homes and charting newspaper headlines throughout the pandemic.

The workshop slides are available in [`dlsph-student-conf-2022-web-scraping-workshop-slides.pdf`](dlsph-student-conf-2022-web-scraping-workshop-slides.pdf).

## Setup

1. First, download the required files. Click the big green "Code" button then "Download ZIP". Save the ZIP file to your desktop and extract.

2. To ensure the scripts run as expected, open the project file (`dlsph-student-conf-2022-web-scraping-workshop.Rproj`) in [RStudio](https://posit.co/downloads/).

3. Install the required R packages by running the script `install-required-packages.R`.

## Projects

The interactive portion of this workshop consists of three example projects for web scraping in ascending order of complexity:

- Project 1: Canada's international COVID-19 vaccine distribution (`international-vaccine-dist.R`)
- Project 2: Who owns Ontario's long-term care homes? (`ltc-homes.R`)
- Project 3: *Toronto Star* headlines throughout the pandemic (`torstar-headlines.R`)

**For reproducibility, all data for the projects have already been downloaded and provided in this repository.** Webpages were downloaded in mid-November 2022. Additionally, sections of code related to downloading data have been commented out. If you want to re-download the data included in the projects (this may break some existing code), simply delete the directories `international-vaccine-dist`, `ltc-homes` and `torstar-headlines` and uncomment the relevant code chunks in each script.
