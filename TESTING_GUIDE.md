# Testing Guide - Yahoo Finance Module

## Quick Start

```r
# Load the test suite
source("test_yahoo_finance.R")

# Run all tests (takes 2-5 minutes)
run_all_tests()
```

---

## Individual Tests

### Test 1: Price Fetching and Validation
Tests basic functionality with 6 well-known tickers.

```r
test_price_fetching()
```

**Tests**:
- ✓ GLD (Gold ETF) - Expected: $150-$500
- ✓ TLT (20Y Treasury) - Expected: $70-$150
- ✓ IEF (10Y Treasury) - Expected: $75-$110
- ✓ ^GSPC (S&P 500) - Expected: $4000-$6500
- ✓ AAPL (Apple) - Expected: $150-$250
- ✓ VTI (Total Stock Market) - Expected: $200-$300

**Output**: Pass/Fail/Warning for each ticker with current price

---

### Test 2: Data Integrity
Validates statistics calculation for GLD data.

```r
test_data_integrity()
```

**Checks**:
- ✓ Fetches 2 years of GLD price history
- ✓ Calculates min/max/mean/median/stdev correctly
- ✓ Mean is between min and max
- ✓ StdDev is positive
- ✓ Current price is reasonable

**Output**: Statistics table for GLD with validation checks

---

### Test 3: Classification Logic
Tests rich/cheap/par classification with synthetic data.

```r
test_classification_logic()
```

**Test Cases**:
- Price = Mean + 1.5σ → Expected: "rich"
- Price = Mean - 1.5σ → Expected: "cheap"
- Price = Mean + 0.5σ → Expected: "par"
- Price = Mean - 0.5σ → Expected: "par"
- Price = Mean → Expected: "par"

**Output**: 5 test cases with Pass/Fail for each

---

### Test 4: Known Values Comparison
Compares fetched prices to approximate real market values.

```r
test_known_values()
```

**Benchmarks** (as of 2025-11-16):
| Ticker | Expected | Asset | Tolerance |
|--------|----------|-------|-----------|
| GLD | $375 | Gold | ±5-15% |
| TLT | $105 | 20Y Treasury | ±5-15% |
| IEF | $90 | 10Y Treasury | ±5-15% |
| ^GSPC | $5,850 | S&P 500 | ±5-15% |
| EURUSD=X | $1.085 | EUR/USD | ±5% |
| ^N225 | $39,000 | Nikkei 225 | ±5-15% |

**Output**: Table comparing expected vs. actual prices with % difference

**Interpretation**:
- **✓ CLOSE** (< 5% diff): Prices match well
- **⚠ REASONABLE** (5-15% diff): Normal market movement
- **✗ DIVERGENT** (> 15% diff): Check ticker or market conditions

---

### Test 5: Module Integration
End-to-end test of the full module.

```r
test_module_integration()
```

**Steps**:
1. Loads yahoo_finance_module.R
2. Tests load_ticker_mapping() with 25 instruments
3. Checks for duplicate tickers
4. Fetches prices for 3 sample instruments (GLD, IEF, ^GSPC)
5. Tests classify_rich_cheap() function
6. Displays results

**Output**: Success/failure for each step, summary statistics

---

## Full Test Suite

```r
run_all_tests()
```

Runs all 5 tests sequentially with:
- Individual test output
- Consolidated summary
- Timing information
- Pass/fail/warning counts

**Total Time**: 2-5 minutes (depends on network)

---

## Expected Results

### Passing Criteria

All tests should show:
- **TEST 1**: ≥5/6 price validations pass
- **TEST 2**: All statistics calculated correctly
- **TEST 3**: All 5 classification tests pass
- **TEST 4**: ≥4/6 prices within reasonable range
- **TEST 5**: Module loads and processes without errors

### Warnings

Expected warnings (not failures):
- Fallback tickers being used (if primary fails)
- Prices outside expected range during market stress
- Network delays on first run

### Failures to Investigate

Red flags requiring investigation:
- **TEST 1**: < 4/6 passing (ticker issues)
- **TEST 2**: Mean outside min/max (data corruption)
- **TEST 3**: Classification wrong (logic bug)
- **TEST 4**: > 3/6 prices divergent (data quality)
- **TEST 5**: Module fails to load (code error)

---

## Troubleshooting

### "Error: Package 'quantmod' not installed"
```r
install.packages("quantmod")
```

### "Error: Column not found in mapping"
```r
# Check mapping file exists and has correct columns:
read.csv("yahoo_finance_mapping.csv") %>% head()
```

### "No price data returned"
- Network issue: Yahoo Finance may be temporarily unavailable
- Wait a few seconds and retry
- Check internet connection

### "GLD price seems wrong"
- Check if GLD is suspended/delisted (unlikely)
- Check date - prices change daily/hourly
- If significantly different (>15%), market may have moved significantly

### Test hangs/takes very long
- Normal: First run fetches 5 years of data for each instrument
- Expected time: 2-5 minutes
- If > 10 minutes: Network issue, try again

---

## Quick Price Verification

If you want to manually verify GLD:

```r
# Quick check without running full tests
source("yahoo_finance_module.R")

# Fetch just GLD
suppressMessages(suppressWarnings({
  gld <- quantmod::getSymbols("GLD",
    from = Sys.Date() - 10,
    to = Sys.Date(),
    auto.assign = FALSE)
}))

# Show current price
current_price <- as.numeric(gld[nrow(gld), grep("Close", colnames(gld))])
cat("Current GLD price: $", round(current_price, 2), "\n")
```

Expected output (as of 2025-11-16):
```
Current GLD price: $ [your value should be ~$375]
```

---

## Production Use

After tests pass, use in production:

```r
# Load the module
source("yahoo_finance_module.R")

# Run with confirmation prompt
price_analysis <- get_price_analysis()

# Will ask:
# "Proceed with downloading 5-year price history from Yahoo Finance? (yes/no):"

# Type: yes

# Results will show:
# - Classification table (rich/cheap/par)
# - Summary by classification
# - Results by asset class
# - Full CSV export
```

---

## Continuous Testing

Recommended cadence:

**Weekly**:
```r
# Quick validation
run_all_tests()
```

**Before Major Analysis**:
```r
# Full validation
test_known_values()  # Ensure prices current
test_module_integration()  # Ensure everything works
get_price_analysis()  # Run actual analysis
```

**Monthly**:
```r
# Check for ticker changes
review_failed_tickers <- function() {
  source("yahoo_finance_module.R")
  result <- get_price_analysis(ask_confirmation = FALSE)
  if (length(result$failed_tickers) > 0) {
    cat("Failed tickers to investigate:\n")
    print(result$failed_tickers)
  }
}
```

---

## Integration with strat7b.R

Once tests confirm prices are working:

```r
# In strat7b.R, after loading DataValues:

source("yahoo_finance_module.R")

# Ask user if they want current market prices
update_prices <- readline("Update valuations from Yahoo Finance? (yes/no): ")

if (tolower(trimws(update_prices)) == "yes") {
  price_analysis <- get_price_analysis()

  # Update DataValues with market-based classifications
  DataValues <- DataValues %>%
    left_join(
      price_analysis$analysis %>%
        select(Instrument, Classification) %>%
        rename(Rich_cheap = Classification),
      by = "Instrument"
    )

  cat("✓ Valuations updated from market data\n")
}

# Rest of strat7b.R continues with updated or original DataValues
```

---

## Contact & Support

If tests fail:
1. Check CLAUDE.md for project context
2. Review CODE_REVIEW_AND_IMPROVEMENTS.md for technical details
3. Check YAHOO_FINANCE_USAGE.md for module documentation
4. Run individual tests to isolate issues
5. Check git log for recent changes: `git log --oneline -5`

---

**Last Updated**: 2025-11-16
**Test Suite Version**: 1.0
**Module Version**: 1.1 (with fallback support)
