#!/usr/bin/env Rscript
# Debug ORCID API Response

library(httr)
library(jsonlite)

# ORCID credentials
orcid_client_id <- "APP-RO85EC734G4T0RCB"
orcid_client_secret <- "13c16fee-86de-47a7-84bc-59cccf0c5283"
your_orcid <- "0000-0001-6989-9278"

# Get access token
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

# Fetch works from ORCID
works_response <- httr::GET(
  url = paste0("https://pub.orcid.org/v3.0/", your_orcid, "/works"),
  httr::add_headers(
    `Accept` = "application/json",
    `Authorization` = paste("Bearer", access_token)
  )
)

works_data <- httr::content(works_response, as = "text", encoding = "UTF-8")

# Save raw JSON for inspection
writeLines(works_data, "orcid_raw_response.json")
cat("Raw ORCID response saved to orcid_raw_response.json\n")

# Parse and inspect structure
works_json <- jsonlite::fromJSON(works_data, flatten = FALSE)

cat("\nStructure of works_json:\n")
cat("========================\n")
str(works_json, max.level = 3)

cat("\n\nNumber of groups:", length(works_json$group), "\n")

if (length(works_json$group) > 0) {
  cat("\nFirst group structure:\n")
  str(works_json$group[[1]], max.level = 2)
}
