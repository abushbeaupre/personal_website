#!/usr/bin/env Rscript
# Automated ORCID Publications Fetcher
# Fetches publications from ORCID and creates formatted publication list

# Install packages if needed
packages <- c("httr", "jsonlite", "dplyr", "stringr")
for (pkg in packages) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    install.packages(pkg, repos = "https://cloud.r-project.org/")
    library(pkg, character.only = TRUE)
  }
}

# ORCID credentials
orcid_client_id <- "APP-RO85EC734G4T0RCB"
orcid_client_secret <- "13c16fee-86de-47a7-84bc-59cccf0c5283"
your_orcid <- "0000-0001-6989-9278"

# Get access token
cat("Getting ORCID access token...\n")
token_response <- httr::POST(
  url = "https://orcid.org/oauth/token",
  httr::add_headers(
    `Accept` = "application/json",
    `Content-Type` = "application/x-www-form-urlencoded"
  ),
  body = list(
    grant_type = "client_credentials",
    scope = "/read-public",
    client_id = orcid_client_id,
    client_secret = orcid_client_secret
  ),
  encode = "form"
)

token_content <- httr::content(token_response)
access_token <- token_content$access_token

if (is.null(access_token)) {
  stop("Failed to get access token")
}

cat("✓ Token received\n")

# Fetch works from ORCID
cat("Fetching publications from ORCID...\n")
works_response <- httr::GET(
  url = paste0("https://pub.orcid.org/v3.0/", your_orcid, "/works"),
  httr::add_headers(
    `Accept` = "application/json",
    `Authorization` = paste("Bearer", access_token)
  )
)

works_data <- httr::content(works_response, as = "text", encoding = "UTF-8")
works_json <- jsonlite::fromJSON(works_data, flatten = FALSE)

cat(paste0("✓ Found ", nrow(works_json$group), " publication groups\n"))

# Extract publication details
publications <- list()

for (i in seq_len(nrow(works_json$group))) {
  # Get the first work summary from this group
  work_summaries <- works_json$group$`work-summary`[[i]]
  if (nrow(work_summaries) == 0) next
  work <- work_summaries[1, ]
  
  # Get title
  title <- work$title$title$value
  if (is.null(title)) next
  
  # Get year
  year <- work$`publication-date`$year$value
  if (is.null(year)) year <- NA
  
  # Get journal
  journal <- work$`journal-title`$value
  if (is.null(journal)) journal <- ""
  
  # Get DOI
  doi <- NULL
  if (!is.null(work$`external-ids`)) {
    ext_ids <- work$`external-ids`[[1]]
    if (!is.null(ext_ids$`external-id`)) {
      doi_entries <- ext_ids$`external-id`[[1]]
      if (is.data.frame(doi_entries) && nrow(doi_entries) > 0) {
        for (j in seq_len(nrow(doi_entries))) {
          if (doi_entries$`external-id-type`[j] == "doi") {
            doi <- doi_entries$`external-id-value`[j]
            break
          }
        }
      }
    }
  }
  
  # Get work type
  work_type <- work$type
  
  # Debug: print work type
  cat(paste0("  Work type: ", work_type, " - Title: ", substr(title, 1, 50), "...\n"))
  
  # Only include journal articles
  if (!is.null(work_type) && work_type == "journal-article") {
    # Fetch detailed work info to get authors
    put_code <- work$`put-code`
    
    cat(paste0("  Fetching details for: ", title, "...\n"))
    
    detail_response <- httr::GET(
      url = paste0("https://pub.orcid.org/v3.0/", your_orcid, "/work/", put_code),
      httr::add_headers(
        `Accept` = "application/json",
        `Authorization` = paste("Bearer", access_token)
      )
    )
    
    detail_data <- httr::content(detail_response, as = "text", encoding = "UTF-8")
    detail_json <- jsonlite::fromJSON(detail_data, flatten = FALSE)
    
    # Extract contributors (authors)
    authors <- "Bush-Beaupré A, et al."
    if (!is.null(detail_json$contributors$contributor)) {
      contributors <- detail_json$contributors$contributor
      if (is.data.frame(contributors) && nrow(contributors) > 0) {
        author_names <- sapply(seq_len(nrow(contributors)), function(idx) {
          # Try credit-name first
          credit_name <- contributors$`credit-name`[[idx]]
          if (!is.null(credit_name)) {
            if (is.list(credit_name) && !is.null(credit_name$value)) {
              return(credit_name$value)
            } else if (is.character(credit_name)) {
              return(credit_name)
            }
          }
          return(NA)
        })
        author_names <- author_names[!is.na(author_names)]
        if (length(author_names) > 0) {
          authors <- paste(author_names, collapse = ", ")
        }
      }
    }
    
    publications[[length(publications) + 1]] <- list(
      title = title,
      authors = authors,
      year = year,
      journal = journal,
      doi = doi,
      type = work_type
    )
  }
}

cat(paste0("\n✓ Processed ", length(publications), " journal articles\n\n"))

# Print results
cat("Publications found:\n")
cat("==================\n\n")
for (pub in publications) {
  cat(paste0("Title: ", pub$title, "\n"))
  cat(paste0("Authors: ", pub$authors, "\n"))
  cat(paste0("Year: ", pub$year, "\n"))
  cat(paste0("Journal: ", pub$journal, "\n"))
  cat(paste0("DOI: ", ifelse(is.null(pub$doi), "N/A", pub$doi), "\n"))
  cat("\n")
}

# Save to RDS file for use in Quarto
saveRDS(publications, "orcid_publications.rds")
cat("✓ Publications saved to orcid_publications.rds\n")
