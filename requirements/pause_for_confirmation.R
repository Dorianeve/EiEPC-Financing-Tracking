# ---- Hard pause helper that works in Source(), Jobs, headless, etc. ----
pause_for_confirmation <- function(msg = "Action required", sentinel = "CONTINUE") {
  # 1) RStudio modal (blocks even when Source() kills stdin)
  if (requireNamespace("rstudioapi", quietly = TRUE) && rstudioapi::isAvailable()) {
    ok <- rstudioapi::showQuestion("ACTION REQUIRED", paste0(msg, "\n\nContinue?"))
    if (!isTRUE(ok)) stop("Stopped by user.")
    return(invisible())
  }
  # 2) Tk dialog (cross-platform if tcltk is available)
  if (requireNamespace("tcltk", quietly = TRUE)) {
    btn <- tcltk::tkmessageBox(type = "okcancel", icon = "info",
                               title = "ACTION REQUIRED",
                               message = paste0(msg, "\n\nClick OK to continue."))
    if (as.character(btn) != "ok") stop("Stopped by user.")
    return(invisible())
  }
  # 3) TTY fallback (only if a real terminal exists)
  if (interactive() && isatty(stdin())) {
    readline(paste0(msg, "\n\nPress Enter to continue..."))
    return(invisible())
  }
  # 4) Headless fallback: sentinel file
  cat(
    msg, "\n\nHeadless mode detected.\n",
    "Create an empty file named '", sentinel, "' in the working directory to proceed,\n",
    "or press Ctrl+C to abort.\n", sep = ""
  )
  repeat {
    if (file.exists(sentinel)) { unlink(sentinel); break }
    Sys.sleep(1)
  }
  invisible()
}