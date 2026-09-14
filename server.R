library(shiny)
library(bslib)
library(DT)

# ---- Data -----------------------------------------------------------------
# Add new talks (past or upcoming) by editing sessions.csv.
# Leave doi blank for talks that don't have a published record yet;
# the archive will automatically show a "Coming soon" badge instead.
sessions <- read.csv("sessions.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
program <- read.csv("program.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")

# Build a full DOI link whether the column holds a bare DOI (10.xxxx/...)
# or an already-complete URL. Returns NA if there's no DOI yet.
doi_link <- function(doi) {
  if (!nzchar(doi)) return(NA_character_)
  if (grepl("^https?://", doi, ignore.case = TRUE)) doi else paste0("https://doi.org/", doi)
}

server <- function(input, output, session) {
  
  # helper for Open button - embed link -------------------------------------
  
  observeEvent(input$open_embed, {
    showModal(modalDialog(
      title = input$open_embed$title,
      tags$iframe(
        src = input$open_embed$url,
        width = "100%",
        height = "500px",
        frameborder = "0",
        allowfullscreen = NA
      ),
      size = "l",
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })
  
  # -------------------------------------------------------------------------
  
  output$program_table <- renderDT({
    d <- program
    
    # turn the link column into a clickable "Sign up" link, or an em dash if blank
    d$sign.up.link <- ifelse(
      nzchar(d$sign.up.link),
      paste0('<a href="', d$sign.up.link, '" target="_blank">Sign up</a>'),
      "—"
    )
    
    names(d) <- c("Date", "Time", "Title", "Speakers", "Sign-up link")
    
    datatable(
      d,
      escape = FALSE,        # needed so the <a> tag in sign-up link renders as HTML, not text
      rownames = FALSE,
      options = list(
        pageLength = 20,
        dom = "t",            # "t" = just the table, no search box/pagination controls
        columnDefs = list(
          list(width = "12%", targets = 0),  # Date
          list(width = "18%", targets = 1),  # Time
          list(width = "35%", targets = 2),  # Title
          list(width = "20%", targets = 3),  # Speakers
          list(width = "15%", targets = 4)   # Sign-up link
        )
      )
    )
  })
  
  observeEvent(input$goto_archive, {
    updateTabsetPanel(session, "main_nav", selected = "archive")
  })
  
  filtered <- reactive({
    d <- sessions
    
    if (!is.null(input$year_filter) && input$year_filter != "All years") {
      d <- d[d$year == as.integer(input$year_filter), ]
    }
    
    # Topics can be multi-valued per row (semicolon-separated), so match
    # against the split set rather than the raw string.
    if (!is.null(input$topic_filter) && input$topic_filter != "All topics") {
      d <- d[sapply(strsplit(d$topic, ";"), function(t) {
        input$topic_filter %in% trimws(t)
      }), ]
    }
    
    if (nzchar(input$search_filter)) {
      q <- tolower(input$search_filter)
      d <- d[grepl(q, tolower(d$title)) | grepl(q, tolower(d$speakers)), ]
    }
    
    d
  })
  
  output$session_list <- renderUI({
    d <- filtered()
    if (nrow(d) == 0) return(p("No talks match your filters."))
    
    cards <- lapply(seq_len(nrow(d)), function(i) {
      row <- d[i, ]
      has_doi <- nzchar(row$doi)
      link <- if (has_doi) doi_link(row$doi) else NA
      
      title_el <- if (has_doi) {
        tags$a(href = link, target = "_blank", row$title)
      } else {
        row$title
      }
      
      topics <- trimws(strsplit(row$topic, ";")[[1]])
      topic_tags <- lapply(topics, function(t) span(class = "topic-tag", t))
      
      has_embed <- !is.null(row$embed_url) && nzchar(row$embed_url)
      
      div(
        class = "session-card",
        h4(title_el, if (!has_doi) span(class = "badge-coming-soon", "Coming soon")),
        div(class = "session-meta", paste0(row$year, " \u00b7 ", row$speakers, " \u00b7 ", row$topic)),
        div(class = "topic-tags", topic_tags),
        p(row$description),
        if (has_embed) {
          tags$button(
            class = "btn btn-sm btn-outline-primary",
            `data-embed` = row$embed_url,
            `data-title` = row$title,
            onclick = "Shiny.setInputValue('open_embed', {url: this.dataset.embed, title: this.dataset.title}, {priority: 'event'})",
            "Open"
          )
        }
      )
    })
    do.call(tagList, cards)
  })
}