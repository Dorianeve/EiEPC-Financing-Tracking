# --- CONFIG ---
source("config/extraction_config.yml", local = TRUE)  # plain R config file
source("config/flags_list.yml", local = TRUE)  # plain R config file
source("requirements/pause_for_confirmation.R")     # the pause utility

# --- STOP FUNCTION ---
CHECK <- function(msg = "Action required", sentinel = "CONTINUE") {
  # 1) RStudio modal dialog (safe even when stdin is unavailable)
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    ok <- rstudioapi::showQuestion("ACTION REQUIRED", paste0(msg, "\n\nContinue?"))
    if (!isTRUE(ok)) stop("Stopped by user.")
    return(invisible())
  }
  
  # 2) Tk dialog (fallback GUI on other platforms)
  if (requireNamespace("tcltk", quietly = TRUE)) {
    btn <- tcltk::tkmessageBox(type = "okcancel", icon = "info",
                               title = "ACTION REQUIRED",
                               message = paste0(msg, "\n\nClick OK to continue."))
    if (as.character(btn) != "ok") stop("Stopped by user.")
    return(invisible())
  }
  
  # 3) Debugger pause (works anywhere; user types c + Enter)
  cat("\n", msg, "\nType c then Enter to continue, or Q to abort.\n", sep = "")
  browser()
  invisible()
}

# --- RUN SCRIPT HELPER ---
run_stage <- function(path, ...) {
  cat("\n\n▶ Running:", path, "\n")
  env <- new.env(parent = globalenv())   # each script runs isolated
  # Inject config vars explicitly:
  env$fts_date          <- fts_date
  env$fts_years         <- fts_years
  env$fts_location_ids  <- fts_location_ids
  env$fts_EduGlobalClusterId <- fts_EduGlobalClusterId
  env$fts_MLTSGlobalClusterId <- fts_MLTSGlobalClusterId
  env$fts_list_countries <- fts_list_countries
  env$iati_date          <- iati_date
  env$iati_start_range   <- iati_start_range
  env$iati_end_range     <- iati_end_range
  env$iati_countries     <- iati_countries
  env$iati_sectorcodes   <- iati_sectorcodes
  env$iati_fs_sectorcode <- iati_fs_sectorcode
  env$countries          <- countries
  sys.source(path, envir = env, keep.source = TRUE)
  invisible(env)
}