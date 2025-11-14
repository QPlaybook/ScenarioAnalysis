# ScenarioAnalysis - AI Assistant Guide

## Project Overview

This repository contains an R-based **Scenario Analysis** tool for financial instrument portfolio optimization. The tool performs Monte Carlo-style simulations to evaluate investment strategies under different scenario outcomes, identifies optimal strategies using cumulative distribution analysis, and generates random portfolio combinations to find the best risk-adjusted returns.

### Purpose
- Evaluate financial instruments across multiple scenario paths
- Calculate probability-weighted impact distributions
- Identify dominant strategies (those that beat all other strategies)
- Generate and evaluate random portfolio combinations
- Visualize results through interactive plots (Sharpe ratios, density charts, heatmaps)

## Repository Structure

```
ScenarioAnalysis/
├── strat7b.R          # Main R script containing the entire analysis pipeline
├── strat32.xlsx       # Input data file (Excel format)
├── output.html        # Generated HTML report with interactive visualizations
└── .git/              # Git version control
```

### File Descriptions

#### `strat7b.R` (505 lines)
The main analysis script organized into distinct sections:

1. **Data Loading** (lines 2-25): Loads Excel data using `readxl`, interactive file selection
2. **Parameter Listing** (lines 30-39): Extracts unique scenarios and instruments
3. **Table Creation** (lines 44-51): Creates clean working tables
4. **Scenario Building** (lines 56-89): Generates all possible scenario paths with probabilities
5. **Instrument Linking** (lines 94-157): Merges instrument performance with scenario paths
6. **Impact Rounding** (lines 173-183): Rounds and bins impact values
7. **Rich/Cheap Adjustments** (lines 189-223): Applies valuation-based scaling (factor: 1.3)
8. **Results Display** (lines 228-264): Creates histograms and Sharpe ratio plots
9. **Optimal Strategy Selection** (lines 268-366): Eliminates dominated strategies
10. **Loss Analysis** (lines 369-381): Calculates probability of losses
11. **Portfolio Construction** (lines 385-408): Generates 10,000 random portfolios
12. **Performance Metrics** (lines 434-448): Calculates returns, standard deviation, Sharpe ratios
13. **Visualization** (lines 450-505): Creates portfolio performance plots and heatmaps

#### `strat32.xlsx`
Excel workbook with two required sheets:
- **Scenarios**: Contains scenario types, outcomes, probabilities, and instrument performance
- **Values**: Contains instrument metadata including Rich_cheap classification

#### `output.html`
HTML report (529.7KB) containing interactive Plotly visualizations generated during the analysis.

## Code Architecture

### Dependencies
```r
require(tidyverse)   # Data manipulation and visualization
require(readxl)      # Excel file reading
require(plotly)      # Interactive plots
require(dtplyr)      # Data table performance optimization
```

### Workflow Pipeline

```
1. Load Excel Data (Scenarios + Values sheets)
   ↓
2. Extract unique scenarios and instruments
   ↓
3. Build all possible scenario paths (Cartesian product)
   ↓
4. Link instrument performance to each scenario path
   ↓
5. Apply rich/cheap valuation adjustments
   ↓
6. Calculate probability-weighted impact distributions
   ↓
7. Identify optimal (non-dominated) strategies
   ↓
8. Generate random portfolio combinations (10,000)
   ↓
9. Calculate portfolio performance metrics
   ↓
10. Visualize results (Sharpe ratios, densities, heatmaps)
```

### Key Algorithms

#### Scenario Path Generation (lines 62-81)
- Creates all combinations of scenario outcomes via iterative merging
- Multiplies probabilities across independent scenarios
- Result: Complete probability tree of all possible paths

#### Optimal Strategy Elimination (lines 313-352)
```r
eliminate_func <- function(input_data)
```
- Compares cumulative probability distributions pairwise
- Strategy A dominates B if A's cumulative distribution is ≥ B's at all impact levels
- Removes dominated (suboptimal) strategies
- Uses stochastic dominance criterion

#### Rich/Cheap Adjustment (lines 191-214)
Applies valuation-based scaling (factor = 1.3):
- **Rich instruments**: Reduce upside (÷1.3), amplify downside (×1.3)
- **Cheap instruments**: Amplify upside (×1.3), reduce downside (÷1.3)
- **Par instruments**: No adjustment

#### Portfolio Construction (lines 391-403)
- Randomly selects 5 instruments per portfolio
- Generates random weights using `runif()`
- Normalizes weights to sum to 1
- Creates 10,000 portfolio combinations

## Data Format Requirements

### Scenarios Sheet
Expected columns:
- `ScenarioType`: Category of scenario (e.g., "Rates", "Credit", "Equity")
- `Outcome`: Specific outcome within scenario type
- `proba`: Probability of this outcome (should sum to 1 within each ScenarioType)
- `[Instrument columns]`: Performance/return for each instrument under this outcome

**Note**: Column names will have spaces removed automatically (line 23)

### Values Sheet
Expected columns:
- `Instrument`: Instrument identifier (must match column names from Scenarios sheet)
- `Rich_cheap`: Valuation classification ("rich", "cheap", or "par")
- Additional columns are preserved but not used

**Note**: Instrument names will have spaces removed automatically (line 24)

### Excel File Selection
The script uses RStudio's interactive file picker (line 11-17):
```r
filepath <- rstudioapi::selectFile(...)
```
This requires running in RStudio IDE.

## Key Variables and Parameters

### Configuration Parameters
- `rich_cheap_factor = 1.3` (line 193): Scaling factor for valuation adjustments
- `nbr_draws = 10000` (line 390): Number of random portfolios to generate
- Portfolio size: 5 instruments (line 393)
- Impact rounding: 0.5 increments (lines 176, 209)

### Important Data Structures
- `list_scenarios`: Unique scenario types
- `list_instr`: All instrument identifiers
- `ScenarioPaths_tab`: All possible scenario combinations with probabilities
- `summarised_impact`: Impact distributions by instrument
- `optim_strat`: Optimal (non-dominated) strategies
- `full_impact_portfolio_tab`: Portfolio performance metrics

## Visualization Outputs

The script generates interactive Plotly visualizations:

1. **Sharpe Ratio Plot** (lines 239-240): Risk-return scatter for individual instruments
2. **Impact Histograms** (lines 242-262): Probability distributions with expected values
3. **Cumulative Density Chart** (lines 300-306): CDFs for all instruments
4. **Optimal Strategies Chart** (lines 357-364): CDFs for non-dominated strategies only
5. **Portfolio Performance Scatter** (lines 452-455): All 10,000 portfolios
6. **Top Portfolio Chart** (lines 463-471): Top 20 portfolios by Sharpe ratio
7. **Portfolio Composition Heatmap** (lines 494-504): Weight allocation in top portfolios

All plots use `ggplotly()` for interactivity and `theme_bw()` for clean styling.

## Development Workflows

### Running the Analysis
1. Open `strat7b.R` in RStudio
2. Ensure all dependencies are installed
3. Run script (it will prompt for Excel file selection)
4. Select `strat32.xlsx` or another compatible Excel file
5. Review interactive plots as they appear
6. Check `View()` outputs for tabular results (lines 237, 379, 489)

### Modifying the Analysis

#### Changing Rich/Cheap Impact
Edit `rich_cheap_factor` on line 193 (currently 1.3)

#### Adjusting Portfolio Parameters
- Number of portfolios: Edit `nbr_draws` on line 390
- Instruments per portfolio: Edit `size = 5` on line 393
- Weight distribution: Modify `runif()` logic on lines 394-396

#### Adding New Visualizations
- Use `summarised_impact` data frame for instrument-level analysis
- Use `full_impact_portfolio_tab` for portfolio-level analysis
- Follow existing `ggplot() + ... + theme_bw()` pattern
- Wrap with `ggplotly()` for interactivity

#### Changing Impact Rounding
Edit rounding factor in:
- Line 176: `round(Impact*2, digits = 0)/2`
- Line 209: `round(Impact_incl_current_price*2, digits = 0)/2`

## Coding Conventions

### Style Guidelines
- **Pipe operator**: Uses `%>%` from magrittr/tidyverse (lines throughout)
- **Assignment**: Uses `<-` exclusively, never `=`
- **Naming**: snake_case for variables and functions
- **Data frames**: Converted to tibbles for better printing
- **Comments**: Section headers use multiple `#` characters (e.g., `#################`)

### Data Manipulation Patterns
- **Wide to long**: `pivot_longer()` (lines 166, 282, 495)
- **Long to wide**: `pivot_wider()` or `spread()` (lines 98, 273, 481)
- **Grouping**: `group_by() %>% summarise()` (lines 180-181, 232-235)
- **Filtering**: `filter()` with logical conditions
- **Merging**: `left_join()` for preserving all rows (lines 129, 195, 414)

### Performance Optimization
- Uses `lazy_dt()` from dtplyr for large joins (lines 115, 120, 127)
- Explicit `as_tibble()` conversion after data.table operations (line 133)
- Memory cleanup with `rm()` and `gc()` (lines 87, 158-159)

### Temporary Variables
- Prefix with `temp` or `temp_` (lines 59, 95, 318, etc.)
- Clean up after use to free memory
- Use `NULL` initialization for loop accumulation (lines 59-60, 95-96)

## AI Assistant Guidelines

### When Modifying This Codebase

1. **Preserve the Pipeline Structure**
   - The script is organized in sequential sections
   - Each section depends on outputs from previous sections
   - Maintain section comments and ordering

2. **Data Integrity**
   - Always validate that `sum(proba) ≈ 1` within scenario groups
   - Check for NA/NaN values after calculations
   - Verify instrument names match between Scenarios and Values sheets

3. **Memory Management**
   - Use `rm()` to clean up large temporary objects
   - Call `gc()` after major cleanup
   - Consider using `lazy_dt()` for very large datasets

4. **Testing Changes**
   - Verify plots render correctly after modifications
   - Check that probability distributions sum correctly
   - Ensure portfolio weights sum to 1 (line 395)

5. **Adding Features**
   - Follow existing naming conventions (snake_case)
   - Add section headers with `####` for major additions
   - Document new parameters at the top of their section
   - Maintain the pattern: calculate → visualize → clean up

6. **Common Pitfalls to Avoid**
   - Don't modify `list_scenarios` or `list_instr` after initial definition
   - Preserve column name cleaning (lines 23-24) - rest of code expects no spaces
   - Don't change data frame structure before it's used downstream
   - Be careful with `replace_all` in grouped operations

7. **Debugging Tips**
   - Use `View()` to inspect intermediate data frames
   - Check dimensions with `dim()` before/after transformations
   - Use `summary()` to verify probability and impact ranges
   - Plot distributions early to catch issues

### When Answering Questions

1. **Refer to line numbers** in strat7b.R for specific implementations
2. **Explain the financial logic** behind calculations (e.g., Sharpe ratios, stochastic dominance)
3. **Provide code snippets** that match existing style conventions
4. **Consider performance implications** for large datasets
5. **Suggest visualizations** using the existing plotly/ggplot2 framework

### When Extending Functionality

Consider these common extensions:
- **Constraints**: Add min/max weight constraints in portfolio construction
- **Alternative metrics**: VaR, CVaR, maximum drawdown
- **Optimization**: Replace random portfolios with mean-variance optimization
- **Stress testing**: Add scenario weighting/filtering options
- **Export**: Save results to CSV/Excel using `write.csv()` or `write_xlsx()`
- **Backtesting**: Load historical data for validation

### Git Workflow

Current branch: `claude/claude-md-mhywyh9d8lf3j5rm-01W486motJtZjwEgx4EeoGNy`

**Important**: Always develop on Claude-specific branches (prefix: `claude/`)

Commit practices:
- Use descriptive messages (see line 1: "add report", "saving to git")
- Commit functional checkpoints, not work-in-progress
- Include both code changes and generated output.html in commits

## RStudio-Specific Features

The script uses RStudio API features:
- **File selection**: `rstudioapi::selectFile()` (line 11)
- **Data viewing**: `View()` (lines 237, 379, 489)

**Non-RStudio environments**: These will fail outside RStudio IDE. Consider:
- Hardcoding `filepath` for command-line execution
- Replacing `View()` with `print()` or `head()`

## Performance Considerations

### Computational Complexity
- Scenario paths grow exponentially with scenario types
- 10,000 portfolios with 5 instruments each = manageable
- Increase `nbr_draws` cautiously; each portfolio requires full impact calculation

### Bottlenecks
- Nested loops for instrument linking (lines 101-151): O(instruments × scenarios)
- Portfolio performance calculation (lines 426-429): O(portfolios × rows)
- Optimal strategy elimination (lines 313-352): O(instruments²)

### Optimization Strategies
- Use `lazy_dt()` for large merges (already implemented)
- Consider parallelization with `parallel` or `future` packages
- Cache intermediate results if running repeatedly
- Filter out low-probability scenarios (<0.01%) to reduce combinations

## Output Interpretation

### Sharpe Ratio
`sharpe = ImpactTotal / stdev` (line 235)
- Higher is better (more return per unit risk)
- Used to rank both instruments and portfolios

### Optimal Strategies
Strategies that are NOT dominated by any other strategy
- A strategy dominates another if its CDF is always ≥ at all impact levels
- Result: Pareto frontier of risk-return profiles

### Portfolio Heatmap
Shows weight allocation across top 20 portfolios
- Darker blue = higher weight
- Reveals which instruments appear frequently in optimal portfolios
- Ordered by weight in the best portfolio

## Version History

Based on git log:
- `6c6b450`: "add report" - Added HTML output generation
- `44a6e90`: "saving to git" - Initial commit

## Future Enhancements

Potential improvements for AI assistants to implement:

1. **Parameterization**: Move hardcoded values to configuration section
2. **Error handling**: Add checks for missing columns, invalid probabilities
3. **Command-line support**: Remove RStudio dependencies for automation
4. **Alternative optimizers**: Implement quadratic programming for efficient frontier
5. **Reporting**: Generate PDF/Word reports with summary statistics
6. **Caching**: Save intermediate results to avoid recomputation
7. **Unit tests**: Add validation for critical functions
8. **Documentation**: Add roxygen2 comments for functions

## Questions & Troubleshooting

### Common Issues

**"Error: Column not found"**
- Check that Excel sheet names are exactly "Scenarios" and "Values"
- Verify column names (spaces will be removed automatically)
- Ensure instrument names match between sheets

**"Probabilities don't sum to 1"**
- Check that probabilities within each ScenarioType sum to 1
- Rounding errors may cause small deviations (acceptable if <0.01)

**"Memory issues"**
- Reduce `nbr_draws` (line 390)
- Limit number of scenario types
- Add `gc()` calls after major operations

**"Plots not showing"**
- Ensure plotly is installed and loaded
- Check that data frames contain expected columns
- Verify no NA/NaN values in plotting columns

### Contact & Support

This is an internal analysis tool. For questions:
1. Review this CLAUDE.md file
2. Examine the relevant section in strat7b.R
3. Check Excel data format requirements
4. Consult git history for context on changes

---

**Last Updated**: 2025-11-14
**Script Version**: strat7b.R (505 lines)
**Data Version**: strat32.xlsx
