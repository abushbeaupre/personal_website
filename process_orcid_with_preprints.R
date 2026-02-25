#!/usr/bin/env Rscript
# Process publications including preprints from ORCID data

library(httr)
library(jsonlite)

# Load the raw ORCID response
if (!file.exists("orcid_raw_response.json")) {
  stop("Please run debug_orcid.R first to get the ORCID data")
}

works_data <- readLines("orcid_raw_response.json")
works_json <- jsonlite::fromJSON(works_data, flatten = TRUE)

cat("========================================\n")
cat("Processing ORCID Publications\n")
cat("========================================\n\n")

published_articles <- list()
preprints <- list()

# The groups are in a dataframe
for (i in seq_len(nrow(works_json$group))) {
  # Get the work summary (first one in each group)
  summaries <- works_json$group$`work-summary`[[i]]

  if (is.data.frame(summaries) && nrow(summaries) > 0) {
    work <- summaries[1, ]

    # Extract title
    title <- work$title.title.value

    # Extract year
    year <- work$`publication-date.year.value`

    # Extract journal/venue
    journal <- ifelse(!is.null(work$`journal-title.value`) && !is.na(work$`journal-title.value`),
      work$`journal-title.value`,
      ""
    )

    # Extract DOI
    doi <- NULL
    ext_ids <- work$`external-ids.external-id`[[1]]
    if (is.data.frame(ext_ids) && nrow(ext_ids) > 0) {
      doi_idx <- which(ext_ids$`external-id-type` == "doi")
      if (length(doi_idx) > 0) {
        doi <- ext_ids$`external-id-value`[doi_idx[1]]
      }
    }

    # Only process items with DOIs
    if (!is.null(doi)) {
      cat(paste0("• [", work$type, "] ", title, "\n"))
      cat(paste0("  Year: ", year, "\n"))
      if (journal != "") cat(paste0("  Venue: ", journal, "\n"))
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
              authors_df$family[idx], ""
            )
            given <- ifelse("given" %in% names(authors_df) && !is.na(authors_df$given[idx]),
              authors_df$given[idx], ""
            )

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

      pub_entry <- list(
        title = title,
        authors = authors_text,
        year = year,
        journal = journal,
        doi = doi,
        type = work$type
      )

      # Categorize as published article or preprint
      if (work$type == "journal-article") {
        published_articles[[length(published_articles) + 1]] <- pub_entry
      } else if (work$type == "preprint") {
        # Check if this preprint has a corresponding published version
        is_later_published <- FALSE
        for (pub in published_articles) {
          # Simple check: if titles are very similar and preprint year <= published year
          if (grepl(gsub("[^a-zA-Z0-9]", "", substr(title, 1, 30)),
            gsub("[^a-zA-Z0-9]", "", pub$title),
            ignore.case = TRUE
          )) {
            is_later_published <- TRUE
            break
          }
        }

        # Only add to preprints if not later published
        if (!is_later_published) {
          preprints[[length(preprints) + 1]] <- pub_entry
        }
      }
    }
  }
}

cat(paste0("✓ Processed ", length(published_articles), " published articles\n"))
cat(paste0("✓ Processed ", length(preprints), " preprints (unpublished)\n\n"))

# Save publications
all_pubs <- list(
  published = published_articles,
  preprints = preprints
)
saveRDS(all_pubs, "orcid_publications_full.rds")
cat("✓ Publications saved to orcid_publications_full.rds\n\n")

# Also save just published for backward compatibility
saveRDS(published_articles, "orcid_publications.rds")
cat("✓ Published articles saved to orcid_publications.rds\n\n")

# Print summary
cat("========================================\n")
cat("Published Articles\n")
cat("========================================\n\n")
for (i in seq_along(published_articles)) {
  pub <- published_articles[[i]]
  cat(paste0(i, ". ", pub$title, "\n"))
  cat(paste0("   ", pub$authors, "\n"))
  cat(paste0("   ", pub$journal, " (", pub$year, ")\n"))
  cat(paste0("   DOI: ", pub$doi, "\n\n"))
}

if (length(preprints) > 0) {
  cat("========================================\n")
  cat("Preprints (Not Yet Published)\n")
  cat("========================================\n\n")
  for (i in seq_along(preprints)) {
    pub <- preprints[[i]]
    cat(paste0(i, ". ", pub$title, "\n"))
    cat(paste0("   ", pub$authors, "\n"))
    if (pub$journal != "") cat(paste0("   ", pub$journal, " (", pub$year, ")\n"))
    cat(paste0("   DOI: ", pub$doi, "\n\n"))
  }
}
