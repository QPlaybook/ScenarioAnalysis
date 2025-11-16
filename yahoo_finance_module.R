###################################################################
# Yahoo Finance Price Fetching and Rich/Cheap Analysis Module #####
###################################################################
#
# This module fetches 5-year historical price data from Yahoo Finance
# and classifies instruments as rich/cheap/par based on:
# - Current price vs. historical mean
# - 1 standard deviation threshold
#
# Functions:
#   - load_ticker_mapping(): Load the CSV mapping file
#   - fetch_yahoo_prices(): Fetch historical data for tickers
#   - classify_rich_cheap(): Classify instruments based on statistics
#   - get_price_analysis(): Main function combining all steps
#

require(tidyverse)
require(quantmod)  # For getSymbols()
require(lubridate) # For date handling

###################################################################
# Load Ticker Mapping
###################################################################

load_ticker_mapping <- function(mapping_file = "yahoo_finance_mapping.csv") {

  cat("Loading ticker mapping from:", mapping_file, "\n")

  if (!file.exists(mapping_file)) {
    stop("Mapping file not found:", mapping_file)
  }

  mapping <- read_csv(mapping_file, show_col_types = FALSE) %>%
    as_tibble()

  cat("Loaded", nrow(mapping), "instruments\n")
  return(mapping)
}

###################################################################
# Fetch Historical Prices from Yahoo Finance
###################################################################

fetch_yahoo_prices <- function(tickers_with_fallback, start_date = NULL, end_date = Sys.Date()) {

  # Default: 5 years ago
  if (is.null(start_date)) {
    start_date <- Sys.Date() - years(5)
  }

  cat("Fetching prices from", format(start_date, "%Y-%m-%d"),
      "to", format(end_date, "%Y-%m-%d"), "\n\n")

  results <- list()
  failed_tickers <- c()
  fallback_used <- c()

  for (i in seq_len(nrow(tickers_with_fallback))) {
    row <- tickers_with_fallback[i, ]
    primary_ticker <- row$Ticker
    fallback_ticker <- row$Fallback_Ticker
    instrument <- row$Instrument

    cat(sprintf("  %-20s [%s]... ", instrument, primary_ticker))

    # Try primary ticker first
    data <- NULL
    used_ticker <- primary_ticker

    data <- tryCatch({
      suppressMessages(
        suppressWarnings({
          getSymbols(primary_ticker,
                    from = start_date,
                    to = end_date,
                    auto.assign = FALSE,
                    periodicity = "daily")
        })
      )
    }, error = function(e) NULL)

    # If primary failed, try fallback
    if (is.null(data) || nrow(data) == 0) {
      if (!is.na(fallback_ticker)) {
        cat(sprintf("(primary failed, trying fallback %s)... ", fallback_ticker))

        data <- tryCatch({
          suppressMessages(
            suppressWarnings({
              getSymbols(fallback_ticker,
                        from = start_date,
                        to = end_date,
                        auto.assign = FALSE,
                        periodicity = "daily")
            })
          )
        }, error = function(e) NULL)

        if (!is.null(data) && nrow(data) > 0) {
          used_ticker <- fallback_ticker
          fallback_used <- c(fallback_used, paste0(primary_ticker, " -> ", fallback_ticker))
        }
      }
    }

    # Process fetched data
    if (!is.null(data) && nrow(data) > 0) {
      close_col <- grep("Close", colnames(data), ignore.case = TRUE)[1]

      if (!is.na(close_col)) {
        # Validate data integrity
        prices_raw <- data[, close_col]
        prices_numeric <- as.numeric(prices_raw)

        # Check for reasonable price values
        valid_data <- !is.na(prices_numeric) & prices_numeric > 0

        if (sum(valid_data) < 5) {
          cat("FAILED (insufficient valid data)\n")
          failed_tickers <- c(failed_tickers, primary_ticker)
        } else {
          prices <- data[, close_col] %>%
            as_tibble(rownames = "Date") %>%
            rename(Price = 2) %>%
            mutate(Date = as.Date(Date),
                   Ticker = used_ticker,
                   Instrument = instrument) %>%
            filter(!is.na(Price) & Price > 0) %>%
            select(Date, Ticker, Instrument, Price)

          results[[primary_ticker]] <- prices
          cat(sprintf("OK (%d days)\n", nrow(prices)))
        }
      } else {
        cat("FAILED (no Close price column)\n")
        failed_tickers <- c(failed_tickers, primary_ticker)
      }
    } else {
      cat("FAILED (no data returned)\n")
      failed_tickers <- c(failed_tickers, primary_ticker)
    }
  }

  # Combine all results
  if (length(results) > 0) {
    all_prices <- bind_rows(results)
  } else {
    all_prices <- tibble()
  }

  cat("\n")

  if (length(fallback_used) > 0) {
    cat("Tickers using fallback:\n")
    for (f in fallback_used) {
      cat(sprintf("  %s\n", f))
    }
    cat("\n")
  }

  if (length(failed_tickers) > 0) {
    cat("Failed to fetch", length(failed_tickers), "tickers:\n")
    for (f in failed_tickers) {
      cat(sprintf("  %s\n", f))
    }
    cat("\n")
  }

  return(list(
    prices = all_prices,
    failed = failed_tickers,
    fallback_used = fallback_used
  ))
}

###################################################################
# Calculate Rich/Cheap Classification
###################################################################

classify_rich_cheap <- function(price_data) {

  cat("\nCalculating price statistics...\n")

  # Group by Instrument (not Ticker, since Ticker might be a fallback value)
  stats <- price_data %>%
    group_by(Instrument) %>%
    summarise(
      Ticker = first(Ticker, na_rm = TRUE),  # Get the actual ticker used (might be fallback)
      Date_Min = min(Date, na.rm = TRUE),
      Date_Max = max(Date, na.rm = TRUE),
      Price_Min = min(Price, na.rm = TRUE),
      Price_Max = max(Price, na.rm = TRUE),
      Price_Mean = mean(Price, na.rm = TRUE),
      Price_StdDev = sd(Price, na.rm = TRUE),
      Price_Current = last(Price, na.rm = TRUE),
      N_Days = n(),
      .groups = 'drop'
    ) %>%
    mutate(
      # Rich/Cheap boundaries (1 standard deviation)
      Price_Lower_Bound = Price_Mean - Price_StdDev,
      Price_Upper_Bound = Price_Mean + Price_StdDev,

      # Classification logic
      Classification = case_when(
        Price_Current >= Price_Upper_Bound ~ "rich",
        Price_Current <= Price_Lower_Bound ~ "cheap",
        TRUE ~ "par"
      ),

      # Distance from mean (as % of std dev)
      Distance_from_Mean = (Price_Current - Price_Mean) / Price_StdDev,

      # Percentile within bounds (0 = cheap boundary, 1 = rich boundary)
      Percentile_Position = ifelse(
        Price_StdDev > 0,
        (Price_Current - Price_Lower_Bound) / (2 * Price_StdDev),
        0.5
      )
    )

  return(stats)
}

###################################################################
# Main: Get Complete Price Analysis
###################################################################

get_price_analysis <- function(mapping_file = "yahoo_finance_mapping.csv",
                                start_date = NULL,
                                end_date = Sys.Date(),
                                ask_confirmation = TRUE) {

  cat("\n")
  cat("=============================================================\n")
  cat("Yahoo Finance Price Analysis Module                         \n")
  cat("=============================================================\n")

  # Step 1: Load mapping
  mapping <- load_ticker_mapping(mapping_file)

  # Step 2: Show what will be fetched
  cat("\nInstruments to fetch:\n")
  print(
    mapping %>%
      select(Instrument, Ticker, Asset_Class) %>%
      arrange(Asset_Class, Instrument)
  )

  # Step 3: Ask for confirmation
  if (ask_confirmation) {
    cat("\n")
    response <- readline(prompt = "Proceed with downloading 5-year price history from Yahoo Finance? (yes/no): ")

    if (tolower(trimws(response)) != "yes") {
      cat("Download cancelled.\n")
      return(NULL)
    }
  }

  cat("\n")

  # Step 4: Fetch prices (with fallback support)
  price_result <- fetch_yahoo_prices(
    tickers_with_fallback = mapping %>% select(Instrument, Ticker, Fallback_Ticker),
    start_date = start_date,
    end_date = end_date
  )

  if (nrow(price_result$prices) == 0) {
    stop("No price data was successfully fetched!")
  }

  # Step 5: Classify
  stats <- classify_rich_cheap(price_result$prices)

  # Step 6: Add Asset_Class from mapping
  # stats already has Instrument and Ticker from classify_rich_cheap
  mapping_summary <- mapping %>%
    select(Instrument, Asset_Class) %>%
    distinct()

  analysis <- stats %>%
    left_join(
      mapping_summary,
      by = "Instrument"
    ) %>%
    select(
      Instrument, Ticker, Asset_Class,
      Date_Min, Date_Max, N_Days,
      Price_Current, Price_Mean, Price_StdDev,
      Price_Lower_Bound, Price_Upper_Bound,
      Classification, Distance_from_Mean, Percentile_Position
    ) %>%
    arrange(Asset_Class, Instrument)

  cat("\n")
  cat("=============================================================\n")
  cat("Price Analysis Results (5-Year History)                     \n")
  cat("=============================================================\n")
  cat("Classification based on 1 standard deviation threshold\n")
  cat("  rich  : Price >= Mean + 1 StdDev\n")
  cat("  cheap : Price <= Mean - 1 StdDev\n")
  cat("  par   : Mean - 1 StdDev < Price < Mean + 1 StdDev\n\n")

  print(analysis)

  cat("\n")
  cat("=============================================================\n")
  cat("Summary by Classification:\n")
  cat("=============================================================\n")

  summary_table <- analysis %>%
    group_by(Classification) %>%
    summarise(
      Count = n(),
      Instruments = paste(Instrument, collapse = ", "),
      .groups = 'drop'
    )

  print(summary_table)

  # Return both raw stats and mapping info
  return(list(
    analysis = analysis,
    mapping = mapping,
    price_data = price_result$prices,
    failed_tickers = price_result$failed
  ))
}

###################################################################
# Export to Values Sheet Format
###################################################################

export_classifications_to_csv <- function(analysis, output_file = "values_classification_updated.csv") {

  cat("\nExporting classifications to:", output_file, "\n")

  export_data <- analysis$analysis %>%
    select(Instrument, Ticker, Classification, Price_Current, Price_Mean) %>%
    rename(
      Rich_cheap = Classification,
      Current_Price = Price_Current,
      Historical_Mean = Price_Mean
    ) %>%
    arrange(Instrument)

  write_csv(export_data, output_file)

  cat("Exported", nrow(export_data), "instruments\n")
  cat("File saved to:", output_file, "\n")

  return(export_data)
}

###################################################################
# Create Visual Summary
###################################################################

plot_rich_cheap_distribution <- function(analysis) {

  cat("\nCreating price distribution visualization...\n")

  plot_data <- analysis$analysis %>%
    select(Instrument, Price_Current, Price_Mean, Price_Lower_Bound,
           Price_Upper_Bound, Classification) %>%
    arrange(desc(Distance_from_Mean))

  # Create a simple text-based visualization
  cat("\n")
  cat("Price Position Relative to Historical Mean (1 StdDev Bands)\n")
  cat("Sorted by distance from mean\n")
  cat(strrep("=", 80), "\n")

  for (i in seq_len(nrow(plot_data))) {
    row <- plot_data[i, ]
    instrument <- row$Instrument
    classification <- row$Classification
    percentile <- (row$Percentile_Position * 100) %>% round(1)

    # Create bar representation
    bar_length <- 40
    position <- round(percentile / 100 * bar_length)
    position <- max(1, min(bar_length, position))  # Clamp to range

    bar <- paste0(
      "[",
      strrep("-", position - 1),
      "●",
      strrep("-", bar_length - position),
      "]"
    )

    cat(sprintf("%-20s %s %5.1f%% (%s)\n",
                instrument, bar, percentile, classification))
  }

  cat(strrep("=", 80), "\n")
  cat("Left edge = Cheap bound (Mean - 1 StdDev)\n")
  cat("Right edge = Rich bound (Mean + 1 StdDev)\n")
  cat("Middle = Historical Mean\n")
}

###################################################################
# End of Module
###################################################################

cat("\n✓ Yahoo Finance module loaded successfully\n")
cat("  Available functions:\n")
cat("    - get_price_analysis()         : Main analysis function\n")
cat("    - export_classifications_to_csv() : Export results\n")
cat("    - plot_rich_cheap_distribution() : Visualize results\n")
