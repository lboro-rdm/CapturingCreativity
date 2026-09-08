# ==============================================================================
# fetch_figshare_metadata.R
#
# Pulls metadata from the Figshare API (v2) for a list of item IDs and writes
# a clean CSV that the Capturing Creativity Shiny app can read directly.
#
# Input:  capturingcreativity_itemIDs.csv  (columns: item_ID, year)
# Output: capturingcreativity_recordings.csv
#
# Figshare API docs: https://docs.figshare.com/
# Rate limit: Figshare asks for no more than ~1 request/second.
# ==============================================================================

library(httr)
library(jsonlite)
library(tidyverse)

# ---- config ---------------------------------------------------------------
input_csv   <- "capturingcreativity_itemIDs.csv"
output_csv  <- "capturingcreativity_recordings.csv"
api_base    <- "https://api.figshare.com/v2/articles"
sleep_secs  <- 1  # be polite to the API

# If any of your items are private, generate a personal token at
# https://figshare.com/account/applications and uncomment below.
# figshare_token <- "YOUR_TOKEN_HERE"
figshare_token <- Sys.getenv("APIkey")

# ---- read input -------------------------------------------------------------
ids_df <- read_csv(input_csv, show_col_types = FALSE) %>%
  select(item_ID, year) %>%
  filter(!is.na(item_ID))

# small helper since base R doesn't have %||% by default
`%||%` <- function(a, b) if (is.null(a)) b else a

# ---- helper: fetch a single article's metadata -------------------------------
get_figshare_article <- function(article_id) {
  message("Fetching item ", article_id, " ...")
  
  headers <- if (!is.null(figshare_token)) {
    add_headers(Authorization = paste("token", figshare_token))
  } else {
    add_headers()
  }
  
  resp <- tryCatch(
    GET(paste0(api_base, "/", article_id), headers, timeout(15)),
    error = function(e) NULL
  )
  
  if (is.null(resp) || status_code(resp) != 200) {
    warning("Failed to fetch item ", article_id,
            if (!is.null(resp)) paste0(" (HTTP ", status_code(resp), ")") else "")
    return(tibble(
      item_ID       = article_id,
      title         = NA_character_,
      authors       = NA_character_,
      description   = NA_character_,
      doi           = NA_character_,
      published_date = NA_character_,
      url            = NA_character_,
      embed_url      = NA_character_
    ))
  }
  
  dat <- content(resp, as = "parsed", type = "application/json")
  
  authors_str <- if (!is.null(dat$authors) && length(dat$authors) > 0) {
    paste(map_chr(dat$authors, ~ .x$full_name %||% NA_character_), collapse = "; ")
  } else {
    NA_character_
  }
  
  # Strip any HTML tags Figshare sometimes leaves in the description
  description_clean <- if (!is.null(dat$description)) {
    str_squish(str_remove_all(dat$description, "<[^>]+>"))
  } else {
    NA_character_
  }
  
  tibble(
    item_ID        = article_id,
    title          = dat$title %||% NA_character_,
    authors        = authors_str,
    description    = description_clean,
    doi            = dat$doi %||% NA_character_,
    published_date = dat$published_date %||% NA_character_,
    url            = dat$url_public_html %||% NA_character_,
    embed_url      = paste0("https://widgets.figshare.com/articles/", article_id, "/embed")
  )
}

# ---- fetch all items, one at a time (rate-limited) ---------------------------
results <- map(ids_df$item_ID, function(id) {
  out <- get_figshare_article(id)
  Sys.sleep(sleep_secs)
  out
}) %>%
  bind_rows()

# ---- join back to year and save ----------------------------------------------
final_df <- ids_df %>%
  left_join(results, by = "item_ID") %>%
  arrange(year, item_ID)

write_csv(final_df, output_csv)
