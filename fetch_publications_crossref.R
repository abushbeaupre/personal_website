#!/usr/bin/env Rscript
# Fetch publications from ORCID with full author lists
# Uses ORCID API to get DOIs, then CrossRef to get complete metadata

library(httr)
library(jsonlite)

# ORCID credentials
orcid_client_id <- "APP-RO85EC734G4T0RCB"
orcid_client_secret <- "13c16fee-86de-47a7-84bc-59cccf0c5283"
your_orcid <- "0000-0001-6989-9278"

cat("========================================\n")
cat("Fetching Publications from ORCID\n")
cat("========================================\n\n")

# Get access token
cat("Step 1: Getting ORCID access token...\n")
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
cat("✓ Token received\n\n")

# Fetch works from ORCID
cat("Step 2: Fetching works list from ORCID...\n")
works_response <- httr::GET(
  url = paste0("https://pub.orcid.org/v3.0/", your_orcid, "/works"),
  httr::add_headers(
    `Accept` = "application/json",
    `Authorization` = paste("Bearer", access_token)
  )
)

works_data <- httr::content(works_response, as = "text", encoding = "UTF-8")
works_json <- jsonlite::fromJSON(works_data, flatten = FALSE)

cat(paste0("✓ Found ", nrow(works_json$group), " works\n\n"))

# Extract journal articles with DOIs
cat("Step 3: Filtering journal articles and extracting metadata...\n")
publications <- list()

for (i in seq_len(nrow(works_json$group))) {
  work_summaries <- works_json$group$`work-summary`[[i]]
  if (nrow(work_summaries) == 0) next
  work <- work_summaries[1, ]
  
  cat(paste0("Work #", i, " - Type: ", work$type, "\n"))
  
  # Only process journal articles
  if (!is.null(work$type) && work$type == "journal-article") {
    title_obj <- work$title[[1]]
    if (is.data.frame(title_obj) && !is.null(title_obj$title)) {
      title_nested <- title_obj$title[[1]]
      if (is.list(title_nested) && !is.null(title_nested$value)) {
        title <- title_nested$value
      } else {
        next
      }
    } else {
      next
    }
    
    year_obj <- work$`publication-date`[[1]]
    year <- if (!is.null(year_obj$year)) year_obj$year[[1]]$value else NA
    
    journal <- if (!is.null(work$`journal-title`)) {
      work$`journal-title`[[1]]$value
    } else {
      ""
    }
    
    # Get DOI
    doi <- NULL
    if (!is.null(work$`external-ids`)) {
      ext_ids <- work$`external-ids`[[1]]
      if (!is.null(ext_ids$`external-id`)) {
        ext_id_list <- ext_ids$`external-id`[[1]]
        if (is.data.frame(ext_id_list) && nrow(ext_id_list) > 0) {
          doi_row <- which(ext_id_list$`external-id-type` == "doi")
          if (length(doi_row) > 0) {
            doi <- ext_id_list$`external-id-value`[doi_row[1]]
          }
        }
      }
    }
    
    if (!is.null(doi)) {
      cat(paste0("  • ", title, "\n"))
      cat(paste0("    DOI: ", doi, "\n"))
      
      # Fetch complete metadata from CrossRef
      Sys.sleep(0.5)  # Be polite to CrossRef API
      crossref_response <- httr::GET(
        url = paste0("https://api.crossref.org/works/", doi),
        httr::add_headers(`Accept` = "application/json")
      )
      
      if (httr::status_code(crossref_response) == 200) {
        crossref_data <- httr::content(crossref_response, as = "text", encoding = "UTF-8")
        crossref_json <- jsonlite::fromJSON(crossref_data, flatten = TRUE)
        
        # Extract authors from CrossRef
        authors_text <- "Bush-Beaupré A, et al."
        if (!is.null(crossref_json$message$author)) {
          authors_df <- crossref_json$message$author
          author_names <- sapply(seq_len(nrow(authors_df)), function(idx) {
            family <- ifelse(!is.null(authors_df$family[idx]), authors_df$family[idx], "")
            given <- ifelse(!is.null(authors_df$given[idx]), authors_df$given[idx], "")
            if (family != "" && given != "") {
              paste(given, family)
            } else if (family != "") {
              family
            } else {
              given
            }
          })
          authors_text <- paste(author_names, collapse = ", ")
        }
        
        cat(paste0("    Authors: ", authors_text, "\n\n"))
        
        publications[[length(publications) + 1]] <- list(
          title = title,
          authors = authors_text,
          year = year,
          journal = journal,
          doi = doi
        )
      } else {
        cat(paste0("    ⚠ Could not fetch metadata from CrossRef\n\n"))
      }
    }
  }
}

cat(paste0("\n✓ Successfully processed ", length(publications), " journal articles\n\n"))

# Save to RDS file
saveRDS(publications, "orcid_publications.rds")
cat("✓ Publications saved to orcid_publications.rds\n\n")

# Print summary
cat("========================================\n")
cat("Publication Summary\n")
cat("========================================\n\n")
for (i in seq_along(publications)) {
  pub <- publications[[i]]
  cat(paste0(i, ". ", pub$title, "\n"))
  cat(paste0("   ", pub$authors, "\n"))
  cat(paste0("   ", pub$journal, " (", pub$year, ")\n"))
  cat(paste0("   DOI: ", pub$doi, "\n\n"))
}
