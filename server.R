library(shiny)
library(bslib)

# ---- Data -----------------------------------------------------------------
# Add new talks (past or upcoming) by editing sessions.csv.
# Leave doi blank for talks that don't have a published record yet;
# the archive will automatically show a "Coming soon" badge instead.
sessions <- read.csv("sessions.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")

# Build a full DOI link whether the column holds a bare DOI (10.xxxx/...)
# or an already-complete URL.
doi_link <- function(doi) {
  if (grepl("^https?://", doi, ignore.case = TRUE)) doi else paste0("https://doi.org/", doi)
}
server <- function(input, output, session) {
  
  observeEvent(input$goto_archive, {
    updateTabsetPanel(session, "main_nav", selected = "archive")
  })
  
  filtered <- reactive({
    d <- sessions
    if (!is.null(input$year_filter) && input$year_filter != "All years") {
      d <- d[d$year == as.integer(input$year_filter), ]
    }
    if (!is.null(input$topic_filter) && input$topic_filter != "All topics") {
      d <- d[d$topic == input$topic_filter, ]
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
      link <- doi_link(row$doi)
      has_doi <- !is.na(link)
      
      title_el <- if (has_doi) {
        tags$a(href = link, target = "_blank", row$title)
      } else {
        row$title
      }
      
      div(
        class = "session-card",
        h4(title_el, if (!has_doi) span(class = "badge-coming-soon", "Coming soon")),
        div(class = "session-meta", paste0(row$year, " \u00b7 ", row$speakers, " \u00b7 ", row$topic)),
        p(row$description)
      )
    })
    do.call(tagList, cards)
  })
}