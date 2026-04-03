# Session Handover: Gemini Image Generation Fix

## Date: 2026-04-03 03:11 AEDT

## Problem Summary

The `hong_kong_travel.Rmd` vignette needs to generate 5 images via the Gemini 3.1 Flash Image API. The images are not being generated because the R process crashes during the HTTP response handling.

## Root Cause Analysis

We have identified **three distinct failure layers**:

### Layer 1: Invalid API Schema (FIXED ✅)
- **What**: `imageGenerationConfig` was an invalid field for the `generateContent` endpoint.
- **Fix**: Removed `imageGenerationConfig`, using `generationConfig.responseModalities = ["IMAGE"]` instead.
- **File**: `R/drivers_api.R`, lines ~307-320.

### Layer 2: httr2 Crashes R Process (IDENTIFIED, NOT FIXED ❌)
- **What**: `httr2::req_perform()` successfully sends the request and receives HTTP 200, but the R process **crashes at the C level** (not an R error) when parsing the ~1.3MB JSON response containing base64-encoded image data. `tryCatch` cannot catch this.
- **Evidence**: Debug output shows `req_perform returned, status: 200` followed immediately by `Execution halted` with no R error message. No macOS crash reports are generated, ruling out a segfault — it appears to be R's own memory handling failing.
- **Confirmed**: The API works correctly — a standalone `curl` command successfully retrieves the 1.3MB response and we can parse it with `jsonlite::fromJSON()` and decode the base64 image.

### Layer 3: system2("curl") Hangs in R6 Context (IDENTIFIED, NOT FIXED ❌)
- **What**: We attempted to bypass httr2 by using `system2("curl", ...)`. This works from **standalone R scripts** but **hangs indefinitely** when called from within the `GeminiImageDriver$call()` R6 method (which runs inside `withr::with_dir()`).
- **Likely cause**: `system2()` with `stdout=TRUE` blocks waiting for the child process, and something about the R6/withr context prevents the curl subprocess from completing.

## Current State of `R/drivers_api.R`

The file currently has the **broken system2("curl") implementation** at lines 329-410. This needs to be replaced.

## Recommended Fix: Use `curl::curl_fetch_disk()`

The `curl` R package (already installed as a dependency of `httr2`) provides `curl_fetch_disk()` which:
1. Makes the HTTP request at the C level (like httr2)
2. BUT writes the response body **directly to a file on disk** instead of loading it into R memory
3. Returns only metadata (status code, headers) to R
4. This avoids the crash because R never needs to hold the 1.3MB payload in memory during the HTTP transaction

### Implementation (replace lines 329-358 in `R/drivers_api.R`):

```r
# Use curl::curl_fetch_disk to avoid httr2 crash on large responses
req_body_json <- jsonlite::toJSON(request_body, auto_unbox = TRUE)
resp_file <- tempfile(pattern = "gemini_resp_", fileext = ".json")
call_url <- sprintf("%s?key=%s", url, api_key)

h <- curl::new_handle()
curl::handle_setopt(h,
  customrequest = "POST",
  postfields = as.character(req_body_json),
  timeout = 120
)
curl::handle_setheaders(h, "Content-Type" = "application/json")

if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") {
  message("DEBUG: [", self$id, "] curl_fetch_disk to ", resp_file, "...")
}
result <- curl::curl_fetch_disk(call_url, path = resp_file, handle = h)
status <- result$status_code

if (status != 200) {
  err_body <- if (file.exists(resp_file)) paste(readLines(resp_file, warn = FALSE), collapse = "\n") else "Unknown"
  stop(sprintf("[%s] Gemini API failed: HTTP %s. Body: %s", self$id, status, err_body))
}

if (Sys.getenv("HYDRAR_DEBUG") == "TRUE") {
  message("DEBUG: [", self$id, "] Response saved (", file.size(resp_file), " bytes). Parsing JSON...")
}
cont <- jsonlite::fromJSON(resp_file, simplifyVector = FALSE)
unlink(resp_file)
```

The rest of the code (base64 extraction, file saving) remains unchanged.

## Other Changes Made This Session

### `vignettes/hong_kong_travel.yml` (lines ~131-149)
- Changed `purrr::map` to `purrr::imap` with `Sys.sleep(3)` rate-limit guard between API calls
- Removed `aspectRatio` from `cli_opts` (unsupported by generateContent)
- Updated prompt to include "wide landscape format"

## Files to Modify

| File | What to Do |
|------|-----------|
| `R/drivers_api.R` | Replace lines 329-358 (system2 curl code) with `curl::curl_fetch_disk()` implementation above |
| `vignettes/hong_kong_travel.yml` | Already updated ✅ |

## Verification Steps

1. **Smoke test**: Run standalone image generation:
   ```r
   devtools::load_all(".")
   drv <- GeminiImageDriver$new(id="test", model="gemini-3.1-flash-image-preview", output_dir="/tmp")
   path <- drv$call("A blue circle", cli_opts = list(filename = "test.jpg"))
   # Should return "/tmp/test.jpg" without crashing
   ```

2. **DAG test**: Run the workflow directly:
   ```r
   devtools::load_all(".")
   wf <- load_workflow("vignettes/hong_kong_travel.yml")
   dag <- spawn_dag(wf, auto_node_factory())
   dag$run(initial_state = append(wf$initial_state, list(force_regenerate_images = TRUE)), max_steps = 15)
   ```

3. **Vignette render**:
   ```r
   rmarkdown::render("vignettes/hong_kong_travel.Rmd")
   ```

4. Check `vignettes/images/` has: `victoria_peak.jpg`, `man_mo_temple.jpg`, `tsim_sha_tsui.jpg`, `temple_street.jpg`, `star_ferry.jpg`

## Environment Notes
- `HYDRAR_DEBUG=TRUE` enables detailed logging
- `FORCE_REGENERATE_IMAGES=TRUE` forces image regeneration even if files exist
- API key is in `.Renviron` as `GOOGLE_API_KEY`
- There may be a stale Rscript process still running — kill with `pkill -9 -f Rscript` before starting

## Known Cycle Warning
The DAG compiler warns about cycles in `hong_kong_travel.yml` — this is expected due to the Planner→Validator→Planner retry loop and doesn't affect execution as long as `max_steps` is set.

---
<!-- APAF Bioinformatics | HydraR | Session Handover | 2026-04-03 -->
