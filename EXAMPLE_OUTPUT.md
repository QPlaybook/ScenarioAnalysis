# Yahoo Finance Analysis - Example Output

## How to Run

```r
# Load both modules
source("yahoo_finance_module.R")
source("display_analysis_results.R")

# Run the analysis (will prompt for confirmation before downloading)
price_analysis <- get_price_analysis()

# Display results (multiple view options available)
display_analysis(price_analysis, view = "full")
```

---

## Example Output: FULL VIEW

```
╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║  YAHOO FINANCE PRICE ANALYSIS - INSTRUMENT CLASSIFICATION SUMMARY                            ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝

Instrument                Ticker     Status       Current      Average      StdDev    Distance
─────────────────────────────────────────────────────────────────────────────────────────────────
CLEANENERGY               ICLN       ↑ RICH     $38.45       $28.32       $6.42        1.57
Gold                      GLD        ↑ RICH     $206.50      $180.25      $15.30       1.71
USDEQUITY                 ^GSPC      ↑ RICH     $5820.00     $4950.00     $450.00      1.93
RealEstateUS              VNQ        ↓ CHEAP    $78.50       $92.30       $8.20       -1.68
Comodities                DBC        ↓ CHEAP    $18.25       $26.50       $4.10       -2.01
JPNEQUITY                 ^N225      → PAR      $28500.00    $27200.00    $2100.00     0.62
EUREQUITY                 ^STOXX     → PAR      $425.30      $420.00      $35.50       0.15
EQUITYWATER               CGW        ↑ RICH     $48.75       $42.10       $4.50        1.49
USUTILITIES               XLU        → PAR      $72.30       $71.50       $6.20        0.13
EURUTILITIES              VEUR       → PAR      $52.80       $51.20       $3.80        0.42
USD                       ^DXY       ↑ RICH     $107.50      $100.00      $5.30        1.42
EUR                       EURUSD=X   → PAR      $1.085       $1.08        $0.045       0.11
GBP                       GBPUSD=X   → PAR      $1.280       $1.27        $0.055       0.18
EURSOV                    VGSHX      ↓ CHEAP    $15.20       $18.50       $2.10       -1.57
EURCORP                   VCIT       ↓ CHEAP    $78.00       $88.30       $6.70       -1.54
USDSOV                    IEF        ↓ CHEAP    $82.50       $95.00       $7.50       -1.67
USDCORP                   LQD        ↓ CHEAP    $110.30      $125.00      $8.30       -1.77
InvestorAB                INVESTAB   → PAR      $385.00      $380.00      $28.00       0.18
EQUITYSWISS               EWL        → PAR      $32.50       $32.00       $2.50        0.20
Balancedfund              VBIAX      → PAR      $68.20       $67.50       $4.10        0.17
equityfund                VTI        ↑ RICH     $245.50      $220.00      $15.00       1.70
RealEstateEurope          REM        ↓ CHEAP    $35.80       $42.00       $4.00       -1.55
EURSOVInflation           VTIP       ↓ CHEAP    $61.50       $68.00       $3.50       -1.86
USDSOVInflation           TIP        ↓ CHEAP    $94.30       $106.50      $6.80       -1.79
─────────────────────────────────────────────────────────────────────────────────────────────────

═════════════════════════════════════════════════════════════
SUMMARY BY CLASSIFICATION
═════════════════════════════════════════════════════════════

Status          Count        Avg Price   Avg Distance
──────────────────────────────────────────────────────────
↑ RICH              7        $1,500.77          1.62
→ PAR               9          $132.40          0.22
↓ CHEAP             9          $640.28         -1.68

↑ RICH (7): CLEANENERGY, Gold, USDEQUITY, EQUITYWATER, USD, equityfund, TBD
→ PAR (9): JPNEQUITY, EUREQUITY, USUTILITIES, EURUTILITIES, EUR, GBP, InvestorAB, EQUITYSWISS, Balancedfund
↓ CHEAP (9): RealEstateUS, Comodities, EURSOV, EURCORP, USDSOV, USDCORP, RealEstateEurope, EURSOVInflation, USDSOVInflation


═════════════════════════════════════════════════════════════
RESULTS BY ASSET CLASS
═════════════════════════════════════════════════════════════

Currency
                      Status       Current      Average      StdDev
───────────────────────────────────────────────────────────────────
  EUR                 → PAR     $1.09        $1.08        $0.05
  USD                 ↑ RICH    $107.50      $100.00      $5.30
  GBP                 → PAR     $1.28        $1.27        $0.06

ETF
                      Status       Current      Average      StdDev
───────────────────────────────────────────────────────────────────
  CLEANENERGY         ↑ RICH     $38.45       $28.32       $6.42
  EQUITYWATER         ↑ RICH     $48.75       $42.10       $4.50
  EQUITYSWISS         → PAR      $32.50       $32.00       $2.50
  RealEstateEurope    ↓ CHEAP    $35.80       $42.00       $4.00
  RealEstateUS        ↓ CHEAP    $78.50       $92.30       $8.20
  USUTILITIES         → PAR      $72.30       $71.50       $6.20
  equityfund          ↑ RICH     $245.50      $220.00      $15.00

Fund
                      Status       Current      Average      StdDev
───────────────────────────────────────────────────────────────────
  Balancedfund        → PAR      $68.20       $67.50       $4.10
  EURCORP             ↓ CHEAP    $78.00       $88.30       $6.70
  EURSOV              ↓ CHEAP    $15.20       $18.50       $2.10

Index
                      Status       Current      Average      StdDev
───────────────────────────────────────────────────────────────────
  EUREQUITY           → PAR      $425.30      $420.00      $35.50
  JPNEQUITY           → PAR      $28500.00    $27200.00    $2100.00
  USDEQUITY           ↑ RICH     $5820.00     $4950.00     $450.00
  Comodities          ↓ CHEAP    $18.25       $26.50       $4.10

Stock
                      Status       Current      Average      StdDev
───────────────────────────────────────────────────────────────────
  InvestorAB          → PAR      $385.00      $380.00      $28.00

```

---

## Example Output: SUMMARY VIEW

```
╔════════════════════════════════════════════════════════════════════════════════════════════════╗
║  YAHOO FINANCE PRICE ANALYSIS - INSTRUMENT CLASSIFICATION SUMMARY                            ║
╚════════════════════════════════════════════════════════════════════════════════════════════════╝

[Main table as shown above]

═════════════════════════════════════════════════════════════
SUMMARY BY CLASSIFICATION
═════════════════════════════════════════════════════════════

[Summary table as shown above]
```

---

## Example Output: COMPACT VIEW

```
COMPACT VIEW
════════════════════════════════════════════════════════════════════

# A tibble: 25 × 5
   Instrument          Classification Price_Current Price_Mean Price_StdDev
   <chr>               <chr>                   <dbl>       <dbl>        <dbl>
 1 Comodities          C                       18.25       26.5         4.1
 2 EURCORP             C                       78          88.3         6.7
 3 EURSOV              C                       15.2        18.5         2.1
 4 RealEstateEurope    C                       35.8        42           4
 5 RealEstateUS        C                       78.5        92.3         8.2
 6 USDSOV              C                       82.5        95           7.5
 7 USDCORP             C                      110.3       125           8.3
 8 EURSOVInflation     C                       61.5        68           3.5
 9 USDSOVInflation     C                       94.3       106.5         6.8
10 Balancedfund        P                       68.2        67.5         4.1
11 EUR                 P                        1.085       1.08        0.045
12 EUREQUITY           P                      425.3       420          35.5
13 EQUITYSWISS         P                       32.5        32           2.5
14 GBP                 P                        1.28        1.27        0.055
15 InvestorAB          P                      385         380          28
16 JPNEQUITY           P                      28500       27200        2100
17 USUTILITIES         P                       72.3        71.5         6.2
18 EURUTILITIES        P                       52.8        51.2         3.8
19 CLEANENERGY         R                       38.45       28.32        6.42
20 equityfund          R                      245.5       220          15
21 EQUITYWATER         R                       48.75       42.1         4.5
22 Gold                R                      206.5       180.25       15.3
23 USDEQUITY           R                      5820        4950         450
24 USD                 R                      107.5       100           5.3
25 CLEANENERGY         R                       38.45       28.32        6.42

Key: R = Rich, C = Cheap, P = Par
```

---

## Example Output: BY ASSET CLASS VIEW

```
═════════════════════════════════════════════════════════════
RESULTS BY ASSET CLASS
═════════════════════════════════════════════════════════════

Currency
                      Status       Current      Average      StdDev
───────────────────────────────────────────────────────────────────
  EUR                 → PAR     $1.09        $1.08        $0.05
  USD                 ↑ RICH    $107.50      $100.00      $5.30
  GBP                 → PAR     $1.28        $1.27        $0.06

ETF
                      Status       Current      Average      StdDev
───────────────────────────────────────────────────────────────────
  CLEANENERGY         ↑ RICH     $38.45       $28.32       $6.42
  [... more rows ...]

[Complete breakdown by asset class]
```

---

## CSV Export

The function also exports a detailed CSV file `analysis_results_full.csv` with all statistics:

| Instrument | Ticker | Asset_Class | Classification | Price_Current | Price_Mean | Price_StdDev | Price_Lower_Bound | Price_Upper_Bound | Distance_from_Mean | Percentile_Position | Date_Min | Date_Max | N_Days |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| EUR | EURUSD=X | Currency | par | 1.0850 | 1.0800 | 0.0450 | 1.0350 | 1.1250 | 0.1111 | 0.5556 | 2019-11-16 | 2024-11-16 | 1826 |
| USD | ^DXY | Index | rich | 107.5000 | 100.0000 | 5.3000 | 94.7000 | 105.3000 | 1.4151 | 0.7076 | 2019-11-16 | 2024-11-16 | 1826 |
| Gold | GLD | ETF | rich | 206.5000 | 180.2500 | 15.3000 | 164.9500 | 195.5500 | 1.7157 | 0.8579 | 2019-11-16 | 2024-11-16 | 1826 |
| ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... | ... |

---

## Key Insights from This Example

### Rich Instruments (Expensive - Consider selling/underweighting):
- **USDEQUITY** (S&P 500): 1.93σ above mean - strongest bull market in 5 years
- **Gold**: 1.71σ above mean - geopolitical safe-haven demand
- **equityfund**: 1.70σ above mean - broad US equity strength
- **CLEANENERGY**: 1.57σ above mean - ESG and renewable energy momentum

### Cheap Instruments (Inexpensive - Consider buying/overweighting):
- **Comodities**: 2.01σ below mean - weakness in energy/metals complex
- **USDSOVInflation (TIP)**: 1.79σ below mean - lower real rates
- **USDCORP**: 1.77σ below mean - credit spread widening fears
- **Fixed Income across board**: Bonds in bear market extending into 2024

### Par/Fairly Valued:
- **Currencies (EUR, GBP)**: FX markets mean-reverting
- **JPNEQUITY**: Stable around historical average
- **Utilities**: Defensive positioning at fair value
- **Balanced funds**: Adequate diversification levels

---

## Usage in strat7b.R

Replace the hardcoded Excel Rich_cheap classifications with these market-based values:

```r
# Before: Relied on static Excel values
# After: Dynamic market-based valuations with current data

DataValues <- DataValues %>%
  left_join(
    price_analysis$analysis %>%
      select(Instrument, Classification) %>%
      rename(Rich_cheap = Classification),
    by = "Instrument"
  )

# Now rich_cheap_factor = 1.3 applies to current market conditions
```

This makes your scenario analysis responsive to real-time valuations!
