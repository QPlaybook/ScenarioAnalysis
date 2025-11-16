###################################################################
# Quick Display: Prices Table with Rich/Cheap Classification  ####
###################################################################
#
# Simple script to display the analysis results in a clean table format
# Shows: Instrument, Rich/Cheap Flag, Current Price, Average, StdDev
#

require(tidyverse)

display_price_table <- function(analysis) {

  cat("\n")
  cat("╔══════════════════════════════════════════════════════════════════════════════════════════════════════╗\n")
  cat("║                    INSTRUMENT PRICES WITH RICH/CHEAP CLASSIFICATION                                ║\n")
  cat("║                         (Based on 5-Year Historical Data)                                           ║\n")
  cat("╚══════════════════════════════════════════════════════════════════════════════════════════════════════╝\n")
  cat("\n")

  # Prepare data for display
  display_data <- analysis$analysis %>%
    select(
      Instrument,
      Classification,
      Price_Current,
      Price_Mean,
      Price_StdDev,
      Distance_from_Mean
    ) %>%
    arrange(desc(Distance_from_Mean)) %>%
    mutate(
      Price_Current = round(Price_Current, 2),
      Price_Mean = round(Price_Mean, 2),
      Price_StdDev = round(Price_StdDev, 2),
      Distance_from_Mean = round(Distance_from_Mean, 2)
    )

  # Print header
  cat(sprintf("%-25s %-8s %14s %14s %12s %12s\n",
              "Instrument", "Status", "Current Price", "Average Price", "Std Dev", "Distance"))
  cat(sprintf("%-25s %-8s %14s %14s %12s %12s\n",
              strrep("-", 25), strrep("-", 8), strrep("-", 14), strrep("-", 14), strrep("-", 12), strrep("-", 12)))

  # Print each row
  for (i in seq_len(nrow(display_data))) {
    row <- display_data[i, ]

    # Create status symbol
    status <- case_when(
      row$Classification == "rich" ~ "↑ RICH",
      row$Classification == "cheap" ~ "↓ CHEAP",
      TRUE ~ "→ PAR"
    )

    # Print row
    cat(sprintf("%-25s %-8s $%13.2f $%13.2f $%11.2f %12.2f\n",
                row$Instrument,
                status,
                row$Price_Current,
                row$Price_Mean,
                row$Price_StdDev,
                row$Distance_from_Mean))
  }

  cat(sprintf("%-25s %-8s %14s %14s %12s %12s\n",
              strrep("-", 25), strrep("-", 8), strrep("-", 14), strrep("-", 14), strrep("-", 12), strrep("-", 12)))
  cat("\n")

  # Print legend
  cat("Legend:\n")
  cat("  ↑ RICH   = Current price >= Mean + 1 StdDev (expensive, consider selling)\n")
  cat("  → PAR    = Current price between Mean ± 1 StdDev (fairly valued)\n")
  cat("  ↓ CHEAP  = Current price <= Mean - 1 StdDev (inexpensive, consider buying)\n")
  cat("\n")
  cat("Distance = (Current Price - Mean) / StdDev\n")
  cat("  Positive = Above average\n")
  cat("  Negative = Below average\n")
  cat("  > 1 or < -1 = Rich or Cheap\n")
  cat("\n")

  return(display_data)
}

# Example usage when you have analysis results:
#
# source("yahoo_finance_module.R")
# source("quick_display.R")
#
# price_analysis <- get_price_analysis()
# display_price_table(price_analysis)
#

cat("✓ Quick display function loaded\n")
cat("Usage: display_price_table(price_analysis)\n")
