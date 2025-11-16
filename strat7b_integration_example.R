###################################################################
# Integration Example: strat7b.R + Yahoo Finance Module      ######
###################################################################
#
# This script shows how to integrate the Yahoo Finance price
# analysis module with the existing strat7b.R workflow.
#
# Two integration approaches are shown:
# 1. UPDATE VALUES: Replace Excel rich/cheap with market-based
# 2. PARALLEL ANALYSIS: Compare Excel vs. market classifications
#

# ===== APPROACH 1: UPDATE VALUES WITH MARKET PRICES =====

# Step 1: Load the Yahoo Finance module
source("yahoo_finance_module.R")

# Step 2: Fetch prices and classify instruments
# (This will ask for confirmation before downloading)
price_analysis <- get_price_analysis(
  mapping_file = "yahoo_finance_mapping.csv",
  ask_confirmation = TRUE
)

# Step 3: View current market classifications
cat("\n=== CURRENT MARKET CLASSIFICATIONS ===\n")
print(
  price_analysis$analysis %>%
    select(Instrument, Classification, Distance_from_Mean) %>%
    arrange(Distance_from_Mean)
)

# Step 4: Export to CSV for reference
export_classifications_to_csv(price_analysis)

# Step 5: Create updated Values sheet with market data
market_classifications <- price_analysis$analysis %>%
  select(Instrument, Classification, Price_Current, Price_Mean, Price_StdDev) %>%
  rename(
    Rich_cheap = Classification,
    Current_Price = Price_Current,
    Historical_Mean = Price_Mean,
    Historical_StdDev = Price_StdDev
  )

# Step 6: Save to Excel (requires writexl package)
# install.packages("writexl") if not already installed
# library(writexl)
# write_xlsx(market_classifications, "strat32_market_values.xlsx")

cat("\nMarket-based values ready for integration\n")


# ===== APPROACH 2: COMPARISON - EXCEL VS. MARKET =====

cat("\n\n=== COMPARING EXCEL VS. MARKET CLASSIFICATIONS ===\n")

# Load existing Excel data
filepath <- "strat32.xlsx"
DataValues <- read_excel(path = filepath, sheet = "Values")

# Clean instrument names
DataValues$Instrument <- gsub(pattern = " ", replacement = "", x = DataValues$Instrument)

# Compare classifications
comparison <- price_analysis$analysis %>%
  select(Instrument, Classification, Distance_from_Mean, Price_Current) %>%
  left_join(
    DataValues %>% select(Instrument, Rich_cheap),
    by = "Instrument"
  ) %>%
  rename(Market = Classification, Excel = Rich_cheap) %>%
  mutate(
    Agreement = case_when(
      Market == Excel ~ "✓ AGREE",
      TRUE ~ "✗ DIFFER"
    )
  ) %>%
  select(Instrument, Market, Excel, Agreement, Distance_from_Mean, Price_Current) %>%
  arrange(desc(Agreement))

print(comparison)

# Summary
cat("\n=== DISAGREEMENTS (Market vs Excel) ===\n")
disagreements <- comparison %>% filter(Agreement == "✗ DIFFER")
print(disagreements)

cat("\nTotal disagreements:", nrow(disagreements), "/", nrow(comparison), "\n")


# ===== APPROACH 3: INCORPORATE INTO ANALYSIS =====

# To fully integrate into strat7b.R, make these modifications:
#
# At the beginning of strat7b.R (after loading libraries):
#
# source("yahoo_finance_module.R")
#
# # Option A: Ask user if they want to update prices
# update_prices <- readline("Update instrument valuations from Yahoo Finance? (yes/no): ")
#
# if (tolower(trimws(update_prices)) == "yes") {
#   price_analysis <- get_price_analysis()
#   DataValues <- left_join(
#     DataValues,
#     price_analysis$analysis %>%
#       select(Instrument, Classification) %>%
#       rename(Rich_cheap = Classification),
#     by = "Instrument"
#   )
#   cat("✓ Valuations updated from market data\n")
# }
#
# # Option B: Use market data for scenario adjustments (line ~193)
# # Keep using the same rich_cheap_factor = 1.3 but with current classifications
#

# ===== BATCH PROCESSING OPTION =====

# If you want to run this weekly/monthly without interaction:

batch_update_valuations <- function(excel_file = "strat32.xlsx",
                                    output_file = "strat32_updated.xlsx",
                                    overwrite = FALSE) {

  cat("=== BATCH VALUATION UPDATE ===\n")
  cat("Input: ", excel_file, "\n")

  # Load original data
  DataScenarios <- read_excel(path = excel_file, sheet = "Scenarios")
  DataValues <- read_excel(path = excel_file, sheet = "Values")

  # Clean names
  DataValues$Instrument <- gsub(pattern = " ", replacement = "", x = DataValues$Instrument)

  # Fetch current prices (no confirmation in batch mode)
  price_analysis <- get_price_analysis(ask_confirmation = FALSE)

  # Update classifications
  DataValues_Updated <- DataValues %>%
    left_join(
      price_analysis$analysis %>%
        select(Instrument, Classification, Price_Current) %>%
        rename(Rich_cheap = Classification),
      by = "Instrument"
    ) %>%
    select(-Price_Current)  # Keep existing columns, add Rich_cheap

  # Log the changes
  comparison <- DataValues %>%
    left_join(
      DataValues_Updated %>% select(Instrument, Rich_cheap),
      by = "Instrument",
      suffix = c("_Old", "_New")
    )

  changes <- comparison %>%
    filter(Rich_cheap_Old != Rich_cheap_New) %>%
    select(Instrument, Rich_cheap_Old, Rich_cheap_New)

  if (nrow(changes) > 0) {
    cat("\nClassifications changed:\n")
    print(changes)
  } else {
    cat("\nNo classification changes\n")
  }

  # Save results
  output_name <- if (overwrite) excel_file else output_file

  cat("\nSaving to:", output_name, "\n")
  # write_xlsx(
  #   list(Scenarios = DataScenarios, Values = DataValues_Updated),
  #   output_name
  # )

  cat("✓ Update complete\n")

  return(list(
    scenarios = DataScenarios,
    values = DataValues_Updated,
    changes = changes
  ))
}

# Usage:
# result <- batch_update_valuations()


# ===== HELPER FUNCTION: INSTRUMENT PRICE DETAILS =====

get_instrument_details <- function(instrument_name, analysis) {

  details <- analysis$analysis %>%
    filter(Instrument == instrument_name)

  if (nrow(details) == 0) {
    cat("Instrument not found:", instrument_name, "\n")
    return(NULL)
  }

  cat("\n")
  cat("=== INSTRUMENT DETAILS ===\n")
  cat("Instrument:      ", details$Instrument, "\n")
  cat("Ticker:          ", details$Ticker, "\n")
  cat("Asset Class:     ", details$Asset_Class, "\n")
  cat("Period:          ", format(details$Date_Min, "%Y-%m-%d"), " to ", format(details$Date_Max, "%Y-%m-%d"), "\n")
  cat("Data Points:     ", details$N_Days, " days\n")
  cat("\n")
  cat("Price Statistics:\n")
  cat("  Current Price: $", round(details$Price_Current, 2), "\n")
  cat("  Historical Mean: $", round(details$Price_Mean, 2), "\n")
  cat("  Std Dev: $", round(details$Price_StdDev, 2), "\n")
  cat("  Range: $", round(details$Price_Min, 2), " - $", round(details$Price_Max, 2), "\n")
  cat("\n")
  cat("Valuation Bands (±1 StdDev):\n")
  cat("  Cheap Boundary:  $", round(details$Price_Lower_Bound, 2), "\n")
  cat("  Fair Value:      $", round(details$Price_Mean, 2), "\n")
  cat("  Rich Boundary:   $", round(details$Price_Upper_Bound, 2), "\n")
  cat("\n")
  cat("Current Classification: ", toupper(details$Classification), "\n")
  cat("Distance from Mean:     ", round(details$Distance_from_Mean, 2), " σ\n")
  cat("Percentile Position:    ", round(details$Percentile_Position * 100, 1), "%\n")
  cat("\n")

  return(details)
}

# Usage:
# get_instrument_details("USDEQUITY", price_analysis)


###################################################################
# End of Integration Examples
###################################################################

cat("\n✓ Integration examples ready\n")
cat("See YAHOO_FINANCE_USAGE.md for full documentation\n")
