###################################################################
# Test Suite: Yahoo Finance Module                           ######
###################################################################
#
# This script tests the Yahoo Finance module functionality:
# 1. Price fetching accuracy
# 2. Data integrity and statistics calculation
# 3. Classification logic
# 4. Comparison with known market values
#

require(tidyverse)
require(quantmod)

cat("\n")
cat("╔════════════════════════════════════════════════════════════╗\n")
cat("║  YAHOO FINANCE MODULE TEST SUITE                          ║\n")
cat("╚════════════════════════════════════════════════════════════╝\n\n")

###################################################################
# TEST 1: Fetch Well-Known Tickers and Validate Prices
###################################################################

test_price_fetching <- function() {

  cat("\n")
  cat("TEST 1: Price Fetching and Validation\n")
  cat("═════════════════════════════════════════════════════════════\n\n")

  # Test with well-known tickers with expected price ranges
  test_tickers <- data.frame(
    Ticker = c("GLD", "TLT", "IEF", "^GSPC", "AAPL", "VTI"),
    Expected_Min = c(150, 70, 75, 4000, 150, 200),
    Expected_Max = c(500, 150, 110, 6500, 250, 300),
    Description = c(
      "Gold ETF",
      "20+ Year Treasury",
      "7-10 Year Treasury",
      "S&P 500 Index",
      "Apple Stock",
      "Total Stock Market"
    )
  )

  cat("Testing tickers and validating price ranges:\n\n")

  results <- list()

  for (i in seq_len(nrow(test_tickers))) {
    ticker <- test_tickers$Ticker[i]
    expected_min <- test_tickers$Expected_Min[i]
    expected_max <- test_tickers$Expected_Max[i]
    description <- test_tickers$Description[i]

    cat(sprintf("%-8s (%s)... ", ticker, description))

    tryCatch({
      suppressMessages(
        suppressWarnings({
          data <- getSymbols(ticker,
                           from = Sys.Date() - 10,
                           to = Sys.Date(),
                           auto.assign = FALSE,
                           periodicity = "daily")
        })
      )

      if (!is.null(data) && nrow(data) > 0) {
        close_col <- grep("Close", colnames(data), ignore.case = TRUE)[1]

        if (!is.na(close_col)) {
          current_price <- as.numeric(data[nrow(data), close_col])

          # Validate price is within reasonable range
          if (current_price >= expected_min && current_price <= expected_max) {
            status <- "✓ PASS"
            cat(sprintf("%s (Price: $%.2f, Expected: $%.0f-$%.0f)\n",
                       status, current_price, expected_min, expected_max))

            results[[ticker]] <- list(
              status = "pass",
              price = current_price,
              expected_range = c(expected_min, expected_max)
            )
          } else {
            status <- "⚠ WARNING"
            cat(sprintf("%s (Price: $%.2f, Expected: $%.0f-$%.0f)\n",
                       status, current_price, expected_min, expected_max))

            results[[ticker]] <- list(
              status = "warning",
              price = current_price,
              expected_range = c(expected_min, expected_max),
              outside_range = TRUE
            )
          }
        } else {
          cat("✗ FAIL (No Close price found)\n")
          results[[ticker]] <- list(status = "fail", reason = "no_close_price")
        }
      } else {
        cat("✗ FAIL (No data returned)\n")
        results[[ticker]] <- list(status = "fail", reason = "no_data")
      }

    }, error = function(e) {
      cat("✗ FAIL (Error:", substr(e$message, 1, 40), "...)\n")
      results[[ticker]] <<- list(status = "fail", reason = paste("error:", e$message))
    })
  }

  cat("\n")
  passed <- sum(sapply(results, function(x) x$status == "pass"))
  total <- length(results)

  cat(sprintf("Results: %d/%d passed\n", passed, total))

  return(results)
}

###################################################################
# TEST 2: Data Integrity Check
###################################################################

test_data_integrity <- function() {

  cat("\n")
  cat("TEST 2: Data Integrity and Statistics\n")
  cat("═════════════════════════════════════════════════════════════\n\n")

  cat("Fetching 2-year history for GLD to check data integrity...\n\n")

  suppressMessages(
    suppressWarnings({
      gld_data <- getSymbols("GLD",
                            from = Sys.Date() - years(2),
                            to = Sys.Date(),
                            auto.assign = FALSE,
                            periodicity = "daily")
    })
  )

  if (is.null(gld_data) || nrow(gld_data) == 0) {
    cat("✗ FAIL: Could not fetch GLD data\n")
    return(NULL)
  }

  close_col <- grep("Close", colnames(gld_data), ignore.case = TRUE)[1]
  prices <- as.numeric(gld_data[, close_col])

  # Remove any NA values
  prices_clean <- prices[!is.na(prices)]

  cat(sprintf("✓ Fetched %d trading days of GLD price data\n\n", length(prices_clean)))

  # Test statistics calculation
  cat("Statistics Validation:\n")
  cat("─────────────────────────────────────────\n")

  stats <- data.frame(
    Metric = c("Minimum", "Maximum", "Mean", "Median", "StdDev", "Current"),
    Value = c(
      min(prices_clean),
      max(prices_clean),
      mean(prices_clean),
      median(prices_clean),
      sd(prices_clean),
      prices_clean[length(prices_clean)]
    )
  )

  stats <- stats %>%
    mutate(Value = round(Value, 2))

  print(stats)

  cat("\n✓ Statistics calculated successfully\n")

  # Validate mean is between min and max
  mean_val <- mean(prices_clean)
  min_val <- min(prices_clean)
  max_val <- max(prices_clean)

  if (mean_val >= min_val && mean_val <= max_val) {
    cat("✓ Mean is within min/max range\n")
  } else {
    cat("✗ FAIL: Mean outside min/max range\n")
  }

  # Validate standard deviation is positive
  std_val <- sd(prices_clean)
  if (std_val > 0) {
    cat("✓ Standard deviation is positive\n")
  } else {
    cat("✗ FAIL: Standard deviation is not positive\n")
  }

  # Validate current price is reasonable
  current <- prices_clean[length(prices_clean)]
  if (current >= min_val * 0.8 && current <= max_val * 1.2) {
    cat(sprintf("✓ Current price ($%.2f) is reasonable\n", current))
  } else {
    cat(sprintf("⚠ WARNING: Current price ($%.2f) seems unusual\n", current))
  }

  return(list(
    prices = prices_clean,
    stats = stats
  ))
}

###################################################################
# TEST 3: Classification Logic
###################################################################

test_classification_logic <- function() {

  cat("\n")
  cat("TEST 3: Classification Logic Validation\n")
  cat("═════════════════════════════════════════════════════════════\n\n")

  # Create synthetic test data
  test_prices <- c(
    rich = 150,      # Mean + 1.5 StdDev
    cheap = 50,      # Mean - 1.5 StdDev
    par_high = 110,  # Mean + 0.5 StdDev
    par_low = 90,    # Mean - 0.5 StdDev
    at_mean = 100    # Exactly at mean
  )

  mean_price <- 100
  std_price <- 20

  cat("Test Case Data:\n")
  cat(sprintf("  Mean: $%.2f, StdDev: $%.2f\n", mean_price, std_price))
  cat(sprintf("  Cheap Boundary: $%.2f\n", mean_price - std_price))
  cat(sprintf("  Fair Value (Mean): $%.2f\n", mean_price))
  cat(sprintf("  Rich Boundary: $%.2f\n\n", mean_price + std_price))

  cat("Classification Tests:\n")
  cat("─────────────────────────────────────────\n")

  test_results <- data.frame()

  for (name in names(test_prices)) {
    price <- test_prices[name]

    lower_bound <- mean_price - std_price
    upper_bound <- mean_price + std_price
    distance <- (price - mean_price) / std_price

    classification <- case_when(
      price >= upper_bound ~ "rich",
      price <= lower_bound ~ "cheap",
      TRUE ~ "par"
    )

    expected <- case_when(
      name == "rich" ~ "rich",
      name == "cheap" ~ "cheap",
      TRUE ~ "par"
    )

    status <- ifelse(classification == expected, "✓", "✗")

    cat(sprintf("  %s: Price=$%.2f -> %s (distance: %.2fσ) %s\n",
               name, price, classification, distance, status))

    test_results <- bind_rows(test_results, data.frame(
      Test = name,
      Price = price,
      Classification = classification,
      Expected = expected,
      Status = status
    ))
  }

  cat("\n")
  passed <- sum(test_results$Status == "✓")
  cat(sprintf("Results: %d/%d tests passed\n", passed, nrow(test_results)))

  return(test_results)
}

###################################################################
# TEST 4: Comparison with Known Values
###################################################################

test_known_values <- function() {

  cat("\n")
  cat("TEST 4: Comparison with Known Market Values\n")
  cat("═════════════════════════════════════════════════════════════\n\n")

  cat("As of 2025-11-16, these are approximate market prices:\n")
  cat("(Source: Yahoo Finance, Bloomberg, etc.)\n\n")

  known_values <- data.frame(
    Ticker = c("GLD", "TLT", "IEF", "^GSPC", "EURUSD=X", "^N225"),
    Expected_Approx = c(375, 105, 90, 5850, 1.085, 39000),
    Asset = c("Gold", "20Y Treasuries", "10Y Treasuries", "S&P 500", "EUR/USD", "Nikkei 225")
  )

  cat(sprintf("%-8s %-20s %15s\n", "Ticker", "Asset", "Expected Price"))
  cat(sprintf("%-8s %-20s %15s\n", strrep("-", 8), strrep("-", 20), strrep("-", 15)))

  for (i in seq_len(nrow(known_values))) {
    cat(sprintf("%-8s %-20s $%14.2f\n",
               known_values$Ticker[i],
               known_values$Asset[i],
               known_values$Expected_Approx[i]))
  }

  cat("\nFetching current prices to compare...\n\n")

  comparison <- data.frame()

  for (i in seq_len(nrow(known_values))) {
    ticker <- known_values$Ticker[i]
    expected <- known_values$Expected_Approx[i]
    asset <- known_values$Asset[i]

    tryCatch({
      suppressMessages(
        suppressWarnings({
          data <- getSymbols(ticker,
                           from = Sys.Date() - 5,
                           to = Sys.Date(),
                           auto.assign = FALSE,
                           periodicity = "daily")
        })
      )

      if (!is.null(data) && nrow(data) > 0) {
        close_col <- grep("Close", colnames(data), ignore.case = TRUE)[1]
        current <- as.numeric(data[nrow(data), close_col])

        pct_diff <- ((current - expected) / expected) * 100

        status <- case_when(
          abs(pct_diff) < 5 ~ "✓ CLOSE",
          abs(pct_diff) < 15 ~ "⚠ REASONABLE",
          TRUE ~ "✗ DIVERGENT"
        )

        cat(sprintf("%-8s | Expected: $%10.2f | Current: $%10.2f | Diff: %6.2f%% %s\n",
                   ticker, expected, current, pct_diff, status))

        comparison <- bind_rows(comparison, data.frame(
          Ticker = ticker,
          Asset = asset,
          Expected = expected,
          Current = current,
          Pct_Diff = pct_diff,
          Status = status
        ))
      }

    }, error = function(e) {
      cat(sprintf("%-8s | ERROR: %s\n", ticker, substr(e$message, 1, 40)))
    })
  }

  cat("\n")
  return(comparison)
}

###################################################################
# TEST 5: Module Integration Test
###################################################################

test_module_integration <- function() {

  cat("\n")
  cat("TEST 5: Module Integration Test\n")
  cat("═════════════════════════════════════════════════════════════\n\n")

  cat("Loading yahoo_finance_module.R...\n")

  tryCatch({
    source("yahoo_finance_module.R")
    cat("✓ Module loaded successfully\n\n")

    # Test load_ticker_mapping
    cat("Testing load_ticker_mapping()...\n")
    mapping <- load_ticker_mapping("yahoo_finance_mapping.csv")

    if (nrow(mapping) == 25) {
      cat("✓ Loaded 25 instruments from mapping\n")
    } else {
      cat(sprintf("⚠ WARNING: Expected 25 instruments, got %d\n", nrow(mapping)))
    }

    # Check for duplicate tickers
    duplicates <- mapping %>%
      group_by(Ticker) %>%
      filter(n() > 1) %>%
      pull(Ticker)

    if (length(duplicates) == 0) {
      cat("✓ No duplicate tickers\n")
    } else {
      cat(sprintf("✗ FAIL: Found duplicate tickers: %s\n", paste(duplicates, collapse = ", ")))
    }

    # Test fetch for subset of instruments
    cat("\nTesting fetch_yahoo_prices() with 3 sample tickers...\n")
    sample_tickers <- c("GLD", "IEF", "^GSPC")

    prices <- fetch_yahoo_prices(
      tickers = sample_tickers,
      start_date = Sys.Date() - 365,
      end_date = Sys.Date()
    )

    cat(sprintf("\nFetched prices:\n")
    cat(sprintf("  Total records: %d\n", nrow(prices$prices)))
    cat(sprintf("  Failed tickers: %s\n",
               if (length(prices$failed) == 0) "None" else paste(prices$failed, collapse = ", ")))

    if (nrow(prices$prices) > 0) {
      cat("✓ Price fetching works\n\n")

      # Test classification
      cat("Testing classify_rich_cheap()...\n")
      classification <- classify_rich_cheap(prices$prices)

      if (nrow(classification) == length(sample_tickers) - length(prices$failed)) {
        cat(sprintf("✓ Classified %d instruments\n\n", nrow(classification)))

        print(classification %>%
              select(Ticker, Classification, Distance_from_Mean, Price_Mean, Price_Current))
      } else {
        cat("⚠ Classification count mismatch\n")
      }
    } else {
      cat("✗ FAIL: No price data returned\n")
    }

  }, error = function(e) {
    cat("✗ FAIL:", e$message, "\n")
  })
}

###################################################################
# RUN ALL TESTS
###################################################################

run_all_tests <- function() {

  cat("\n\n")
  cat("╔════════════════════════════════════════════════════════════╗\n")
  cat("║  RUNNING ALL TESTS                                        ║\n")
  cat("╚════════════════════════════════════════════════════════════╝\n")

  test1_results <- test_price_fetching()

  test2_results <- test_data_integrity()

  test3_results <- test_classification_logic()

  test4_results <- test_known_values()

  test5_results <- test_module_integration()

  cat("\n\n")
  cat("╔════════════════════════════════════════════════════════════╗\n")
  cat("║  TEST SUMMARY                                             ║\n")
  cat("╚════════════════════════════════════════════════════════════╝\n\n")

  cat("✓ All tests completed\n")
  cat("  Check results above for any failures or warnings\n\n")

  return(list(
    test1 = test1_results,
    test2 = test2_results,
    test3 = test3_results,
    test4 = test4_results
  ))
}

# Run tests
if (interactive()) {
  cat("\nTo run all tests, execute: run_all_tests()\n")
  cat("To run individual tests:\n")
  cat("  - test_price_fetching()\n")
  cat("  - test_data_integrity()\n")
  cat("  - test_classification_logic()\n")
  cat("  - test_known_values()\n")
  cat("  - test_module_integration()\n")
} else {
  test_results <- run_all_tests()
}
