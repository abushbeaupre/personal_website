# Automated Publication Management with ORCID

This website automatically fetches your publications from ORCID using the public API.

## How It Works

The system:
1. Fetches your publication list from ORCID (ORCID ID: 0000-0001-6989-9278)
2. Filters for journal articles only
3. Gets complete author lists from CrossRef using DOIs
4. Automatically bolds your name in the author lists
5. Displays publications on your website with links to DOIs and preprints

## Files

- `process_orcid_simple.R` - Main script that fetches publications from ORCID
- `orcid_publications.rds` - Cached publication data (automatically generated)
- `publications.qmd` - Quarto file that displays publications on your website
- `orcid_raw_response.json` - Raw ORCID API response (for debugging)

## API Credentials

Your ORCID API credentials are stored in the R scripts:
- Client ID: `APP-RO85EC734G4T0RCB`
- Client Secret: `13c16fee-86de-47a7-84bc-59cccf0c5283`

**Note:** These credentials are for read-only public API access and can be safely committed to your repository.

## Updating Publications

### Automatic Update (Recommended)

To fetch the latest publications from ORCID:

```bash
cd /home/abush/working_vol/personal_website/personal_website
Rscript process_orcid_simple.R
quarto render
```

This will:
1. Fetch your current publication list from ORCID
2. Get complete author information from CrossRef
3. Update `orcid_publications.rds`
4. Re-render your website with updated publications

### Manual Update

If you need to manually add or edit publications, you can modify the fallback section in `publications.qmd` (lines 41-77). This fallback data is only used if the `orcid_publications.rds` file doesn't exist.

## bioRxiv Preprint Links

bioRxiv/preprint links are currently mapped manually in `publications.qmd` (lines 27-30). When you add a new publication to ORCID that has a preprint, add the mapping:

```r
pubs_data$biorxiv[pubs_data$doi == "10.XXXX/your.doi"] <- "10.1101/preprint.doi"
```

## Current Publications

Your website currently displays 3 journal articles:

1. **Sterile insect technique reduces cabbage maggot** (2025)
   - Journal of Economic Entomology
   - DOI: 10.1093/jee/toaf255
   - Authors: Anne-Marie Fortier, Allen Bush-Beaupré, Jade Savage

2. **Reproductive compatibility of two lines of Delia platura** (2024)
   - Entomologia Experimentalis et Applicata
   - DOI: 10.1111/eea.13468
   - Authors: Allen Bush-Beaupré, Jade Savage, Anne-Marie Fortier, François Fournier, Andrew MacDonald, Marc Bélisle

3. **The effect of sex ratio and group density on the mating success** (2023)
   - The Canadian Entomologist
   - DOI: 10.4039/tce.2023.21
   - Authors: Allen Bush-Beaupré, Marc Bélisle, Anne-Marie Fortier, François Fournier, Jade Savage

## Troubleshooting

### No publications showing
- Check that `orcid_publications.rds` exists
- Run `Rscript process_orcid_simple.R` to regenerate it
- Check that your ORCID profile has publications marked as "journal-article"

### Author names not showing correctly
- The system fetches author names from CrossRef, not ORCID
- Some journals may have incomplete metadata
- You can manually override in the fallback section of `publications.qmd`

### New publication not appearing
1. Make sure it's added to your ORCID profile
2. Make sure it's marked as a "journal-article" (not "preprint")
3. Run `Rscript process_orcid_simple.R` to fetch updates
4. Run `quarto render` to update the website

## Future Improvements

- Add abstracts automatically from CrossRef
- Add citation counts from CrossRef or OpenCitations
- Add Altmetric badges
- Automatically detect preprint/published version pairs
