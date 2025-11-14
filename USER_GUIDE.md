# Scenario Analysis & Portfolio Optimization Tool - User Guide

## Index
1. [Overview](#overview)
2. [System Requirements](#system-requirements)
3. [Input Data Structure](#input-data-structure)
4. [Application Workflow](#application-workflow)
5. [Key Outputs & Visualizations](#key-outputs--visualizations)
6. [Key Metrics & Definitions](#key-metrics--definitions)
7. [How to Use](#how-to-use)

---

## Overview

This R-based application analyzes financial scenarios and their impact on investment instruments. It combines multiple market scenarios with different probabilities, calculates instrument performance across all possible paths, applies current valuation adjustments, and generates optimized portfolios ranked by risk-adjusted returns.

**Purpose**: Help investors identify optimal portfolio allocations based on scenario-driven risk and return analysis.

---

## System Requirements

- **R** (latest version recommended)
- **RStudio** (for running the application)
- **Required R Packages**:
  - `tidyverse` - Data manipulation and visualization
  - `readxl` - Excel file reading
  - `plotly` - Interactive charts
  - `dtplyr` - Performance optimization
  - `rstudioapi` - File selection UI

---

## Input Data Structure

**File Format**: Excel workbook (`.xlsx`) with two sheets:

### Sheet 1: "Scenarios"
| ScenarioType | Outcome | proba | Instrument1 | Instrument2 | ... |
|---|---|---|---|---|---|
| Scenario A | Outcome 1 | 0.3 | 5.2 | -1.5 | ... |
| Scenario A | Outcome 2 | 0.7 | -2.0 | 3.1 | ... |
| Scenario B | Outcome X | 0.5 | 1.8 | 2.4 | ... |

- **ScenarioType**: Category of market scenario (e.g., "Interest Rates", "Equity Growth")
- **Outcome**: Specific outcome within that scenario type
- **proba**: Probability of that outcome (0-1)
- **Instrument Columns**: Performance impact (%) of each instrument under that scenario outcome

### Sheet 2: "Values"
| Instrument | Rich_cheap |
|---|---|
| Instrument1 | rich |
| Instrument2 | cheap |
| Instrument3 | par |

- **Instrument**: Name matching columns in Scenarios sheet
- **Rich_cheap**: Current valuation level ("rich", "cheap", or "par")

---

## Application Workflow

### Phase 1: Data Loading & Preparation
- User selects Excel file via dialog
- Application loads Scenarios and Values sheets
- Removes spaces from instrument names for processing

### Phase 2: Scenario Path Building
- Combines all scenario types to create complete scenario paths
- Example: If you have "Interest Rates" (2 outcomes) and "Growth" (3 outcomes), creates 6 combined paths
- Calculates joint probability for each path (multiplies individual probabilities)

### Phase 3: Impact Calculation
- Maps each instrument's performance across all scenario paths
- Sums impacts for each instrument across all scenario outcomes
- Rounds impacts to nearest 0.5 for clarity

### Phase 4: Rich/Cheap Adjustment
- Applies valuation multiplier (1.3x) based on current valuations:
  - **Rich + Positive Impact**: Reduces impact by 1.3x (less upside potential)
  - **Rich + Negative Impact**: Amplifies impact by 1.3x (greater downside risk)
  - **Cheap + Positive Impact**: Amplifies impact by 1.3x (greater upside potential)
  - **Cheap + Negative Impact**: Reduces impact by 1.3x (less downside risk)
  - **Par**: No adjustment

### Phase 5: Instrument Analysis
- Calculates performance metrics for each instrument:
  - Expected return (weighted by probability)
  - Standard deviation (volatility)
  - Sharpe ratio (risk-adjusted return)
  - Probability of losses (impact < 0)

### Phase 6: Portfolio Generation
- Creates 10,000 random portfolios:
  - Each selects 5 instruments randomly
  - Weights are randomly distributed and normalized
- Calculates portfolio performance by combining weighted instrument impacts

### Phase 7: Performance Ranking
- Ranks all 10,000 portfolios by Sharpe ratio
- Identifies top 20 optimal portfolios
- Displays portfolio composition for top performers

---

## Key Outputs & Visualizations

### 1. **Sharpe Ratios Chart**
- X-axis: Volatility (standard deviation)
- Y-axis: Expected return
- **Interpretation**: Points further right = more volatile; higher = better returns. Optimal = upper-left quadrant

### 2. **Distribution Histograms**
- Shows probability distribution of impacts for each instrument
- Red line: Expected return
- **Interpretation**: Narrow = predictable; wide = uncertain outcomes

### 3. **Cumulative Impact Densities**
- Line chart showing cumulative probability vs. impact
- Compares all instruments on same scale
- **Interpretation**: Steeper rise at left = higher downside risk; steeper rise at right = higher upside potential

### 4. **Optimized Strategies Chart**
- Cumulative densities for only non-dominated instruments
- Eliminates instruments beaten by others on all metrics
- **Interpretation**: Best strategies to consider

### 5. **Portfolio Sharpe Plot**
- X-axis: Portfolio volatility
- Y-axis: Portfolio return
- Shows top 20 portfolios by Sharpe ratio
- **Interpretation**: Select portfolios based on risk tolerance

### 6. **Portfolio Composition Heatmap**
- Rows: Instruments
- Columns: Top 20 portfolios
- Color intensity: Weight allocation
- **Interpretation**: Identify common instrument combinations in best portfolios

---

## Key Metrics & Definitions

| Metric | Formula | Interpretation |
|---|---|---|
| **Expected Return** | Sum(Impact × Probability) | Average outcome across all scenarios |
| **Volatility (StDev)** | Sqrt(Variance) | Dispersion of returns; higher = more uncertain |
| **Sharpe Ratio** | Expected Return / Volatility | Risk-adjusted return; higher = better efficiency |
| **Probability of Loss** | Sum(Probabilities where Impact < 0) | Likelihood of negative outcome; lower = better |
| **Joint Probability** | Probability A × Probability B | Chance of combined scenario outcomes occurring |

---

## How to Use

### Step 1: Prepare Data
1. Create Excel workbook with "Scenarios" and "Values" sheets
2. Ensure scenario data includes all outcome combinations
3. Set Rich_cheap valuations based on current market assessment

### Step 2: Run Analysis
1. Open `strat7b.R` in RStudio
2. Run the entire script
3. Select your Excel file when prompted
4. Wait for analysis to complete (~30 seconds for typical datasets)

### Step 3: Interpret Results
1. **Review instrument metrics** (displayed table)
   - Compare Sharpe ratios to identify best risk-adjusted instruments

2. **Examine distributions** (histograms)
   - Look for instruments with acceptable downside risk

3. **Compare strategies** (cumulative density lines)
   - Identify instruments that dominate across outcomes

4. **Select portfolios** (Sharpe plot)
   - Choose top portfolios matching your risk tolerance

5. **Review allocations** (heatmap)
   - Verify instrument weights align with your strategy

### Step 4: Export Results
- All visualizations are interactive (hover for details)
- Right-click charts to export as PNG
- Portfolio metrics table can be copied for external use

---

## Tips for Best Results

1. **Scenario Design**: Use mutually exclusive, exhaustive outcome pairs
2. **Probability Validation**: Ensure outcomes within each scenario sum to 1.0
3. **Realistic Impacts**: Ground instrument impacts in historical analysis
4. **Valuation Calibration**: Update Rich_cheap quarterly based on market conditions
5. **Stress Testing**: Run analysis with extreme valuation scenarios to test robustness

---
