# Publications Page - How to Update

## Adding New Publications

To add a new publication to your website, edit `/home/abush/working_vol/personal_website/personal_website/publications.qmd`:

1. Find the `pubs_data` section (around line 30-50)
2. Add a new entry using this template:

```r
  list(
    title = "Full Article Title",
    authors = "Author1 Last F, Author2 Last F, Bush-Beaupré A, Author3 Last F",
    year = "2025",
    journal = "Journal Name",
    doi = "10.1234/example",  # Just the DOI number, not full URL
    biorxiv = "10.1101/2024.01.01.123456",  # Optional: only if you have a bioRxiv preprint
    abstract = "Brief description of your findings (optional)"
  ),
```

## Features Implemented

✅ **Automatic Name Bolding**: Your name "Bush-Beaupré" is automatically bolded in the author list

✅ **bioRxiv Links**: Add preprint DOIs and they'll automatically link to bioRxiv

✅ **Bilingual Support**: Publications appear in both English and French sections

✅ **Clean Formatting**: Professional layout with proper styling

✅ **Multiple Links**: Each publication shows:
  - Published version (DOI link)
  - bioRxiv preprint (if available)
  - Add to Zotero button

✅ **Journal Articles Only**: Filtered to show only peer-reviewed journal articles

✅ **Automatic Sorting**: Publications are automatically sorted by year (most recent first)

## Future Enhancement: Automatic ORCID Integration

The ORCID public API requires complex parsing. For now, manually adding publications gives you full control over:
- Author order and formatting
- Which version (preprint vs published) to highlight
- Abstract text
- Links to code repositories (can be added to the template)

## Rebuilding the Site

After updating publications, rebuild with:

```bash
cd /home/abush/working_vol/personal_website/personal_website
quarto render publications.qmd
# Or render the entire site:
quarto render
```

## Example Entry

Here's a complete example with all optional fields:

```r
  list(
    title = "Impact of climate change on insect phenology in agricultural systems",
    authors = "Smith J, Johnson K, Bush-Beaupré A, Williams R",
    year = "2026",
    journal = "Ecological Applications",
    doi = "10.1002/eap.2024",
    biorxiv = "10.1101/2025.12.15.648234",
    abstract = "We examined how climate warming affects the timing of pest insect emergence in temperate agricultural systems, finding significant shifts in phenology that could impact crop yields."
  ),
```
