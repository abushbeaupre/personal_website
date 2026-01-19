#!/usr/bin/env Rscript
# Simple publication fetcher using ORCID data we already saved

library(httr)
library(jsonlite)

# Load the raw ORCID response we already fetched
if (!file.exists("orcid_raw_response.json")) {
  stop("Please run debug_orcid.R first to get the ORCID data")
}

works_data <- readLines("orcid_raw_response.json")
works_json <- jsonlite::fromJSON(works_data, flatten = TRUE)

cat("========================================\n")
cat("Processing ORCID Publications\n")
cat("========================================\n\n")

publications <- list()

# The groups are in a dataframe
for (i in seq_len(nrow(works_json$group))) {
  # Get the work summary (first one in each group)
  summaries <- works_json$group$`work-summary`[[i]]
  
  if (is.data.frame(summaries) && nrow(summaries) > 0) {
    work <- summaries[1, ]
    
    # Only process journal articles  
    if (work$type == "journal-article") {
      # Extract title
      title <- work$title.title.value
      
      # Extract year
      year <- work$`publication-date.year.value`
      
      # Extract journal
      journal <- work$`journal-title.value`
      
      # Extract DOI
      doi <- NULL
      ext_ids <- work$`external-ids.external-id`[[1]]
      if (is.data.frame(ext_ids) && nrow(ext_ids) > 0) {
        doi_idx <- which(ext_ids$`external-id-type` == "doi")
        if (length(doi_idx) > 0) {
          doi <- ext_ids$`external-id-value`[doi_idx[1]]
        }
      }
      
      if (!is.null(doi)) {
        cat(paste0("• ", title, "\n"))
        cat(paste0("  Year: ", year, "\n"))
        cat(paste0("  Journal: ", journal, "\n"))
        cat(paste0("  DOI: ", doi, "\n"))
        
        # Fetch authors from CrossRef
        Sys.sleep(0.5)
        crossref_response <- httr::GET(
          url = paste0("https://api.crossref.org/works/", doi),
          httr::add_headers(`Accept` = "application/json")
        )
        
        authors_text <- "Bush-Beaupré A, et al."
        if (httr::status_code(crossref_response) == 200) {
          crossref_data <- httr::content(crossref_response, as = "text", encoding = "UTF-8")
          crossref_json <- jsonlite::fromJSON(crossref_data, flatten = TRUE)
          
          if (!is.null(crossref_json$message$author)) {
            authors_df <- crossref_json$message$author
            author_names <- sapply(seq_len(nrow(authors_df)), function(idx) {
              family <- ifelse("family" %in% names(authors_df) && !is.na(authors_df$family[idx]), 
                             authors_df$family[idx], "")
              given <- ifelse("given" %in% names(authors_df) && !is.na(authors_df$given[idx]), 
                            authors_df$given[idx], "")
              
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
        }
        
        cat(paste0("  Authors: ", authors_text, "\n\n"))
        
        publications[[length(publications) + 1]] <- list(
          title = title,
          authors = authors_text,
          year = year,
          journal = journal,
          doi = doi
        )
      }
    }
  }
}

cat(paste0("✓ Processed ", length(publications), " journal articles\n\n"))

# Save publications
saveRDS(publications, "orcid_publications.rds")
cat("✓ Publications saved to orcid_publications.rds\n\n")

# Print summary
cat("========================================\n")
cat("Publication List\n")
cat("========================================\n\n")
for (i in seq_along(publications)) {
  pub <- publications[[i]]
  cat(paste0(i, ". ", pub$title, "\n"))
  cat(paste0("   ", pub$authors, "\n"))
  cat(paste0("   ", pub$journal, " (", pub$year, ")\n"))
  cat(paste0("   DOI: ", pub$doi, "\n\n"))
}
