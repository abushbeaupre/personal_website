#!/usr/bin/env Rscript
# Inspect detailed work record

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

# Fetch first work detail (put-code 191092687 from the JSON)
detail_response <- httr::GET(
  url = paste0("https://pub.orcid.org/v3.0/", your_orcid, "/work/191092687"),
  httr::add_headers(
    `Accept` = "application/json",
    `Authorization` = paste("Bearer", access_token)
  )
)

detail_data <- httr::content(detail_response, as = "text", encoding = "UTF-8")
writeLines(detail_data, "work_detail.json")

cat("Detailed work record saved to work_detail.json\n")

# Parse and show structure
detail_json <- jsonlite::fromJSON(detail_data, flatten = FALSE)

cat("\nStructure:\n")
str(detail_json, max.level = 2)
