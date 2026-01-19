# ORCID API Setup Script
# This script gets your ORCID access token and saves it to .Renviron

library(httr)
library(usethis)

# Your ORCID credentials
orcid_client_id <- "APP-RO85EC734G4T0RCB"
orcid_client_secret <- "13c16fee-86de-47a7-84bc-59cccf0c5283"

# Get access token
cat("Requesting ORCID access token...\n")
orcid_request <- POST(
  url = "https://orcid.org/oauth/token",
  config = add_headers(
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

# Extract token
orcid_response <- content(orcid_request)

if (!is.null(orcid_response$access_token)) {
  cat("\n✓ Access token received successfully!\n")
  cat("Token:", orcid_response$access_token, "\n\n")
  
  # Save to .Renviron
  cat("Now, please run this command to save the token:\n")
  cat("usethis::edit_r_environ()\n\n")
  cat("Then add this line to the file that opens:\n")
  cat(paste0('ORCID_TOKEN="', orcid_response$access_token, '"\n\n'))
  cat("Save the file, restart R, and you're all set!\n")
  
  # Store token temporarily for this session
  Sys.setenv(ORCID_TOKEN = orcid_response$access_token)
  
} else {
  cat("\n✗ Error getting token\n")
  print(orcid_response)
}
