# Yahoo Finance Price Analysis Module

## Overview

The `yahoo_finance_module.R` provides automated price fetching and valuation analysis using Yahoo Finance data. It classifies instruments as **rich**, **cheap**, or **par** based on 5-year historical price statistics.

## Quick Start

### 1. Load the Module

```r
source("yahoo_finance_module.R")
```

The module requires:
- `tidyverse` - Data manipulation
- `quantmod` - Fetching price data from Yahoo Finance
- `lubridate` - Date handling

### 2. Run Price Analysis

```r
# Run interactive analysis with confirmation prompt
price_analysis <- get_price_analysis(
  mapping_file = "yahoo_finance_mapping.csv",
  start_date = NULL,  # Default: 5 years ago
  end_date = Sys.Date(),
  ask_confirmation = TRUE  # Will ask before downloading
)
```

This will:
1. Display all 25 instruments to be fetched
2. Ask for confirmation before connecting to Yahoo Finance
3. Download 5-year daily price history for each ticker
4. Calculate statistics (mean, std dev)
5. Classify each instrument
6. Display results

### 3. View Results

The returned `price_analysis` object contains:

```r
# Access components:
price_analysis$analysis       # Classification table with full statistics
price_analysis$mapping        # Original ticker mapping
price_analysis$price_data     # Raw daily price data
price_analysis$failed_tickers # List of tickers that failed to download
```

### 4. Export Classifications

Export results to CSV format compatible with Excel:

```r
export_classifications_to_csv(price_analysis)
```

This creates `values_classification_updated.csv` with columns:
- Instrument
- Ticker
- Classification (rich/cheap/par)
- Current_Price
- Historical_Mean

### 5. Visualize

Create a text-based visualization:

```r
plot_rich_cheap_distribution(price_analysis)
```

Output shows each instrument's position relative to the mean ± 1 standard deviation bands.

## Classification Logic

### Definition

An instrument is classified based on current price relative to 5-year historical statistics:

- **Rich**: `Current_Price >= Mean + 1 × StdDev`
  - Instrument is expensive compared to recent history
  - Upside may be limited

- **Cheap**: `Current_Price <= Mean - 1 × StdDev`
  - Instrument is inexpensive compared to recent history
  - Potential upside opportunity

- **Par**: Between the bounds
  - Fairly valued at historical midpoint
  - Normal valuation zone

### Distance from Mean

The module calculates `Distance_from_Mean` as a continuous measure:

- **+1.0** = At rich boundary (Mean + 1 StdDev)
- **0.0** = At historical mean
- **-1.0** = At cheap boundary (Mean - 1 StdDev)

Values outside [-1, +1] indicate rich (>1) or cheap (<-1).

### Percentile Position

`Percentile_Position` shows where price falls within the bounds:
- **0.0** = Cheap boundary
- **0.5** = Historical mean
- **1.0** = Rich boundary

## Integration with Scenario Analysis

To integrate into `strat7b.R`:

### Option 1: Update Existing Values Sheet

After running analysis, use the exported classifications:

```r
# In strat7b.R, after loading DataValues:
source("yahoo_finance_module.R")
price_analysis <- get_price_analysis()
updated_values <- export_classifications_to_csv(price_analysis)

# Merge with existing Values data
DataValues <- left_join(
  DataValues,
  updated_values %>% select(Instrument, Classification),
  by = "Instrument"
)
```

### Option 2: Use for Rich/Cheap Adjustments

The rich/cheap classification can replace or supplement the hardcoded classifications:

```r
# Replace current factor adjustments (line 193)
rich_cheap_factor <- 1.3  # Use same factor as before

# Classification now comes from Yahoo Finance analysis instead of Excel
# This makes the analysis dynamic and market-responsive
```

### Option 3: Create Comparison Report

Compare Excel classifications with market-based classifications:

```r
comparison <- price_analysis$analysis %>%
  left_join(DataValues, by = "Instrument") %>%
  select(Instrument, Classification, Rich_cheap) %>%
  rename(Market_Based = Classification, Excel_Based = Rich_cheap) %>%
  mutate(Agreement = ifelse(Market_Based == Excel_Based, "✓", "✗"))
```

## Functions Reference

### `load_ticker_mapping(mapping_file)`

Loads the CSV mapping file.

**Arguments:**
- `mapping_file` (string): Path to CSV file, default "yahoo_finance_mapping.csv"

**Returns:** Tibble with columns: Instrument, Ticker, Asset_Class, Description, Notes

---

### `fetch_yahoo_prices(tickers, start_date, end_date)`

Fetches historical daily closing prices from Yahoo Finance.

**Arguments:**
- `tickers` (vector): Vector of ticker symbols to fetch
- `start_date` (date): Start date, default is 5 years ago
- `end_date` (date): End date, default is today

**Returns:** List containing:
- `prices` - Tibble with columns: Date, Ticker, Price
- `failed` - Vector of tickers that failed to download

---

### `classify_rich_cheap(price_data)`

Calculates rich/cheap classification based on price statistics.

**Arguments:**
- `price_data` (tibble): Output from `fetch_yahoo_prices()`

**Returns:** Tibble with columns:
- Ticker, Date_Min, Date_Max
- Price statistics: Min, Max, Mean, StdDev, Current
- Bounds: Price_Lower_Bound, Price_Upper_Bound
- Classification, Distance_from_Mean, Percentile_Position

---

### `get_price_analysis(mapping_file, start_date, end_date, ask_confirmation)`

Main function combining all steps.

**Arguments:**
- `mapping_file` (string): Path to CSV mapping, default "yahoo_finance_mapping.csv"
- `start_date` (date): 5 years ago by default
- `end_date` (date): Today by default
- `ask_confirmation` (logical): Whether to prompt before downloading, default TRUE

**Returns:** List containing:
- `analysis` - Full results table
- `mapping` - Ticker mapping
- `price_data` - Raw daily prices
- `failed_tickers` - Tickers that failed

---

### `export_classifications_to_csv(analysis, output_file)`

Exports classifications to CSV format.

**Arguments:**
- `analysis` (list): Output from `get_price_analysis()`
- `output_file` (string): Output filename, default "values_classification_updated.csv"

**Returns:** Tibble with exported data

---

### `plot_rich_cheap_distribution(analysis)`

Creates text-based visualization of valuation positions.

**Arguments:**
- `analysis` (list): Output from `get_price_analysis()`

**Returns:** Prints visualization to console (no return value)

## Example Workflow

```r
# 1. Load module
source("yahoo_finance_module.R")

# 2. Run analysis (will prompt for confirmation)
price_analysis <- get_price_analysis()

# 3. View summary (included in output automatically)
# Already printed during get_price_analysis()

# 4. Visualize positions
plot_rich_cheap_distribution(price_analysis)

# 5. Export for Excel
export_classifications_to_csv(price_analysis)

# 6. Examine specific instruments
price_analysis$analysis %>%
  filter(Classification == "rich") %>%
  select(Instrument, Price_Current, Price_Mean, Price_StdDev)
```

## Troubleshooting

### "Download cancelled"
- The user selected "no" when prompted. Rerun with `ask_confirmation = FALSE` to skip.

### "Ticker failed: Connection timeout"
- Network issue. Yahoo Finance may be temporarily unavailable. Try again later.
- Or run with specific tickers: `fetch_yahoo_prices(c("AAPL", "MSFT"))`

### "No Close price"
- Ticker symbol may be incorrect in `yahoo_finance_mapping.csv`
- Check Yahoo Finance website for correct ticker format

### Missing packages
```r
# Install if needed:
install.packages("tidyverse")
install.packages("quantmod")
install.packages("lubridate")
```

## Performance Notes

- First run takes 2-5 minutes (downloads all tickers)
- Subsequent runs are faster if price_data is cached
- Network interruptions may cause partial failures; retry with failed tickers only
- 5-year history = ~1,250 daily prices per instrument

## Limitations

1. **Currencies (FX pairs)**: Yahoo Finance updates may lag 15+ minutes
2. **Emerging market ETFs**: Some may have gaps in historical data
3. **Delisted instruments**: Tickers that no longer trade will fail
4. **Data quality**: Yahoo Finance data may have adjustments/splits that affect price comparisons

## Future Enhancements

Potential improvements to consider:

- **Caching**: Store downloaded prices locally to avoid repeated downloads
- **Return analysis**: Calculate log returns and volatility instead of raw prices
- **Mean reversion**: Use Z-scores or percentile ranks instead of standard deviations
- **Multi-timeframe**: Compare different lookback periods (1yr, 3yr, 5yr, 10yr)
- **Relative valuation**: Compare instruments to their respective benchmarks
- **Forward-looking**: Incorporate analyst consensus estimates
- **API integration**: Connect to Bloomberg/Reuters for professional-grade data

## Integration with Rich/Cheap Adjustments (strat7b.R)

The module produces classifications that work seamlessly with the existing rich/cheap adjustment system:

```r
# Current strat7b.R approach (lines 191-214):
# Rich/cheap classifications hardcoded in Excel Values sheet
# Adjustment factor: 1.3

# With Yahoo Finance module:
# Classifications are updated with current market data
# Same adjustment factor (1.3) applies
# Result: Analysis always reflects current valuations
```

This makes the scenario analysis more responsive to market conditions while maintaining the same analytical framework.
