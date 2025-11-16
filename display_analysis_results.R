###################################################################
# Display Analysis Results                                   ######
###################################################################
#
# This script displays the Yahoo Finance analysis results
# in various formatted views suitable for review and export.
#

require(tidyverse)
require(knitr)

###################################################################
# Display Summary Table (Main Results)
###################################################################

display_main_results <- function(analysis) {

  cat("\n")
  cat("╔════════════════════════════════════════════════════════════════════════════════════════════════╗\n")
  cat("║  YAHOO FINANCE PRICE ANALYSIS - INSTRUMENT CLASSIFICATION SUMMARY                            ║\n")
  cat("╚════════════════════════════════════════════════════════════════════════════════════════════════╝\n")

  results_table <- analysis$analysis %>%
    select(
      Instrument,
      Ticker,
      Classification,
      Price_Current,
      Price_Mean,
      Price_StdDev,
      Distance_from_Mean,
      Date_Min,
      Date_Max
    ) %>%
    arrange(desc(Distance_from_Mean)) %>%
    mutate(
      Price_Current = round(Price_Current, 2),
      Price_Mean = round(Price_Mean, 2),
      Price_StdDev = round(Price_StdDev, 2),
      Distance_from_Mean = round(Distance_from_Mean, 2),
      Classification = toupper(Classification)
    )

  # Print as formatted table
  cat("\n")
  cat(sprintf("%-25s %-10s %-8s %12s %12s %12s %10s\n",
              "Instrument", "Ticker", "Status", "Current", "Average", "StdDev", "Distance"))
  cat(sprintf("%-25s %-10s %-8s %12s %12s %12s %10s\n",
              strrep("-", 25), strrep("-", 10), strrep("-", 8),
              strrep("-", 12), strrep("-", 12), strrep("-", 12), strrep("-", 10)))

  for (i in seq_len(nrow(results_table))) {
    row <- results_table[i, ]

    # Color coding for status
    status_symbol <- case_when(
      row$Classification == "RICH" ~ "↑ RICH",
      row$Classification == "CHEAP" ~ "↓ CHEAP",
      TRUE ~ "→ PAR"
    )

    cat(sprintf("%-25s %-10s %-8s $%11.2f $%11.2f $%11.2f %10.2f\n",
                row$Instrument,
                row$Ticker,
                status_symbol,
                row$Price_Current,
                row$Price_Mean,
                row$Price_StdDev,
                row$Distance_from_Mean))
  }

  cat(sprintf("%-25s %-10s %-8s %12s %12s %12s %10s\n",
              strrep("-", 25), strrep("-", 10), strrep("-", 8),
              strrep("-", 12), strrep("-", 12), strrep("-", 12), strrep("-", 10)))
  cat("\n")

  return(results_table)
}

###################################################################
# Display Summary by Classification
###################################################################

display_classification_summary <- function(analysis) {

  cat("\n")
  cat("═════════════════════════════════════════════════════════════\n")
  cat("SUMMARY BY CLASSIFICATION\n")
  cat("═════════════════════════════════════════════════════════════\n\n")

  summary <- analysis$analysis %>%
    group_by(Classification) %>%
    summarise(
      Count = n(),
      Avg_Price = mean(Price_Current, na.rm = TRUE),
      Avg_Distance = mean(Distance_from_Mean, na.rm = TRUE),
      Instruments = paste(Instrument, collapse = ", "),
      .groups = 'drop'
    ) %>%
    mutate(
      Avg_Price = round(Avg_Price, 2),
      Avg_Distance = round(Avg_Distance, 2),
      Classification = toupper(Classification)
    ) %>%
    arrange(desc(Avg_Distance))

  cat(sprintf("%-10s %8s %15s %15s\n",
              "Status", "Count", "Avg Price", "Avg Distance"))
  cat(sprintf("%-10s %8s %15s %15s\n",
              strrep("-", 10), strrep("-", 8), strrep("-", 15), strrep("-", 15)))

  for (i in seq_len(nrow(summary))) {
    row <- summary[i, ]

    status_symbol <- case_when(
      row$Classification == "RICH" ~ "↑ RICH",
      row$Classification == "CHEAP" ~ "↓ CHEAP",
      TRUE ~ "→ PAR"
    )

    cat(sprintf("%-10s %8d $%13.2f %15.2f\n",
                status_symbol,
                row$Count,
                row$Avg_Price,
                row$Avg_Distance))
  }

  cat(sprintf("%-10s %8s %15s %15s\n",
              strrep("-", 10), strrep("-", 8), strrep("-", 15), strrep("-", 15)))

  cat("\n")
  for (i in seq_len(nrow(summary))) {
    row <- summary[i, ]
    status <- case_when(
      row$Classification == "RICH" ~ "↑ RICH",
      row$Classification == "CHEAP" ~ "↓ CHEAP",
      TRUE ~ "→ PAR"
    )
    cat(sprintf("%s (%d): %s\n", status, row$Count, row$Instruments))
  }

  cat("\n")
  return(summary)
}

###################################################################
# Display by Asset Class
###################################################################

display_by_asset_class <- function(analysis) {

  cat("\n")
  cat("═════════════════════════════════════════════════════════════\n")
  cat("RESULTS BY ASSET CLASS\n")
  cat("═════════════════════════════════════════════════════════════\n\n")

  by_class <- analysis$analysis %>%
    select(Asset_Class, Instrument, Classification, Price_Current, Price_Mean, Price_StdDev) %>%
    arrange(Asset_Class, desc(Price_Current)) %>%
    mutate(
      Price_Current = round(Price_Current, 2),
      Price_Mean = round(Price_Mean, 2),
      Price_StdDev = round(Price_StdDev, 2),
      Classification = toupper(Classification)
    )

  current_class <- ""

  for (i in seq_len(nrow(by_class))) {
    row <- by_class[i, ]

    # Print class header when it changes
    if (row$Asset_Class != current_class) {
      current_class <- row$Asset_Class
      cat(sprintf("\n%s\n", current_class))
      cat(sprintf("%-25s %-8s %12s %12s %12s\n",
                  "Instrument", "Status", "Current", "Average", "StdDev"))
      cat(sprintf("%-25s %-8s %12s %12s %12s\n",
                  strrep("-", 25), strrep("-", 8), strrep("-", 12), strrep("-", 12), strrep("-", 12)))
    }

    status_symbol <- case_when(
      row$Classification == "RICH" ~ "↑ RICH",
      row$Classification == "CHEAP" ~ "↓ CHEAP",
      TRUE ~ "→ PAR"
    )

    cat(sprintf("  %-23s %-8s $%11.2f $%11.2f $%11.2f\n",
                row$Instrument,
                status_symbol,
                row$Price_Current,
                row$Price_Mean,
                row$Price_StdDev))
  }

  cat("\n")
  return(by_class)
}

###################################################################
# Simple Compact View
###################################################################

display_compact <- function(analysis) {

  cat("\n")
  cat("COMPACT VIEW\n")
  cat("════════════════════════════════════════════════════════════════════\n\n")

  compact <- analysis$analysis %>%
    select(Instrument, Classification, Price_Current, Price_Mean, Price_StdDev) %>%
    mutate(
      Classification = substr(toupper(Classification), 1, 1),  # R/C/P
      Price_Current = round(Price_Current, 2),
      Price_Mean = round(Price_Mean, 2),
      Price_StdDev = round(Price_StdDev, 2)
    ) %>%
    arrange(Classification, Instrument)

  print(compact, n = Inf)

  cat("\nKey: R = Rich, C = Cheap, P = Par\n\n")
  return(compact)
}

###################################################################
# Export to CSV with Full Details
###################################################################

export_full_results <- function(analysis, output_file = "analysis_results_full.csv") {

  cat("\nExporting full results to:", output_file, "\n")

  export_data <- analysis$analysis %>%
    select(
      Instrument,
      Ticker,
      Asset_Class,
      Classification,
      Price_Current,
      Price_Mean,
      Price_StdDev,
      Price_Lower_Bound,
      Price_Upper_Bound,
      Distance_from_Mean,
      Percentile_Position,
      Date_Min,
      Date_Max,
      N_Days
    ) %>%
    mutate(
      Price_Current = round(Price_Current, 4),
      Price_Mean = round(Price_Mean, 4),
      Price_StdDev = round(Price_StdDev, 4),
      Price_Lower_Bound = round(Price_Lower_Bound, 4),
      Price_Upper_Bound = round(Price_Upper_Bound, 4),
      Distance_from_Mean = round(Distance_from_Mean, 4),
      Percentile_Position = round(Percentile_Position, 4)
    )

  write_csv(export_data, output_file)
  cat("✓ Exported", nrow(export_data), "instruments\n\n")

  return(export_data)
}

###################################################################
# Main Display Function
###################################################################

display_analysis <- function(analysis, view = "full") {

  if (is.null(analysis)) {
    cat("No analysis data provided\n")
    return(NULL)
  }

  switch(view,
    "full" = {
      results <- display_main_results(analysis)
      display_classification_summary(analysis)
      display_by_asset_class(analysis)
      export_full_results(analysis)
      return(results)
    },
    "summary" = {
      results <- display_main_results(analysis)
      display_classification_summary(analysis)
      return(results)
    },
    "compact" = {
      return(display_compact(analysis))
    },
    "by_class" = {
      return(display_by_asset_class(analysis))
    },
    {
      cat("Unknown view:", view, "\n")
      cat("Available views: full, summary, compact, by_class\n")
      return(NULL)
    }
  )
}

###################################################################
# End of Display Functions
###################################################################

cat("✓ Display functions loaded\n")
cat("Usage: display_analysis(price_analysis, view = 'full')\n")
cat("Views: 'full', 'summary', 'compact', 'by_class'\n")
