library(shiny)
library(bslib)
library(DT)

# ---- Data (used here just to build the Year filter choices) --------------
sessions <- read.csv("sessions.csv", stringsAsFactors = FALSE, fileEncoding = "UTF-8")
years <- sort(unique(sessions$year), decreasing = TRUE)

conference_name <- "Capturing Creativity"
conference_tagline <- "Organised and hosted by Bath Spa University and Loughborough University"
conference_dates <- "October/November, 2026"
conference_location <- "Online, UK timezone"
all_topics <- sort(unique(trimws(unlist(strsplit(sessions$topic, ";")))))

site_footer <- tags$div(
  class = "footer",
  fluidRow(
    column(12,
           tags$a(href = "https://doi.org/10.17028/rd.lboro.28525481",
                  "Accessibility Statement")
    )
  )
)

# ---- Tabs ------------------------------------------------------------------
home_tab <- tabPanel(
  "Home",
  div(
    class = "hero",
    h1(conference_name),
    p(conference_tagline),
    p(strong(conference_dates), " \u00b7 ", conference_location)
  ),
  fluidRow(
    column(4,
           h4("What is it?"),
           p("A seminar series promoting best practice around capturing and showcasing creative practice research via university research repositories, and the submission of this research to the REF.")
    ),
    column(4,
           h4("Who should attend?"),
           p("Librarians, REF support staff, and practice researchers in the UK and beyond.")
    ),
    column(4,
           h4("Browse past talks"),
           p("Slides and recordings from 2023 onwards. Browse by year, speaker or topic."),
           actionButton("goto_archive", "Go to Archive", class = "btn-sm")
    )
  ),
  fluidRow(
    column(2),
    column(4,
           h4("Keep the conversation going"),
           p(tags$a(href = "https://www.jiscmail.ac.uk/cgi-bin/webadmin?A0=ARTS-PRACTICE-LED-RESEARCH",
                    target = "_blank", "Sign up to the JISC Mailing List")),
           p(tags$a(href = "https://www.zotero.org/groups/4944237/arts-practice-led-research/library",
                    target = "_blank", "Explore the Zotero Library"))
    ),
    column(4,
           h4("Tell us what you think"),
           p("Placeholder for MS Forms")
    ),
    column(2)
  ),
  site_footer
)

program_tab <- tabPanel(
  "Program",
  value = "program",
  h2("This Year's Program", class = "section-title"),
  fluidRow(
    column(12,
           DTOutput("program_table")
    )
  ),
  fluidRow(
    column(12,
           site_footer
    )
  )
)

archive_tab <- tabPanel(
  "Archive",
  value = "archive",
  h2("Recordings Archive", class = "section-title"),
  sidebarLayout(
    sidebarPanel(
      width = 3,
      selectInput("year_filter", "Year", choices = c("All years", years)),
      textInput("search_filter", "Search title or speaker", placeholder = "e.g. Shiny, Jane Doe"),
      selectInput("topic_filter", "Topic", choices = c("All topics", all_topics)),
    ),
    mainPanel(
      width = 9,
      uiOutput("session_list")
    )
  ),
  site_footer
)

about_tab <- tabPanel(
  "About",
  h2("About Capturing Creativity", class = "section-title"),
  p("Capturing Creativity was conceptualised by Claire Drake (Bath Spa University), who saw the need for reporting more robustly on Arts creative practice research outputs. Together with Gareth Cole (who was a Loughborough University at the time, now at Exeter University), they hosted the first seminar series in 2023."),
  p("The success of the first year led to a repeat in 2024 and 2025, with Lara Skelly (Loughborough Univeristy) taking over from Cole in 2025. Katie Fraser (Loughborough University) joins the team in 2026."),
  h4("Contact"),
  p("Claire Drake via <repositories at bathspa.ac.uk>"),
  site_footer
)

# ---- Page --------------------------------------------------------------

ui <- page_navbar(
  theme = bs_theme(version = 5, base_font = font_google("Inter")),
  id = "main_nav",
  
  header = tagList(
    tags$head(tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")),
    tags$img(src = "banner.png", class = "banner-img", alt = "Conference banner")
  ),
  
  home_tab,
  program_tab,
  archive_tab,
  about_tab,

)

