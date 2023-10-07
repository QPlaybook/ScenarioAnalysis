
require(tidyverse)
require(readxl)
require(plotly)
require(dtplyr)


#################
# load data #####

filepath <- rstudioapi::selectFile(
  caption = "Select File",
  label = "Select",
  path = ,
  filter = "All Files (*)",
  existing = TRUE
)

DataScenarios <-read_excel(path = filepath, sheet = "Scenarios")
DataValues <-read_excel(path = filepath, sheet = "Values")

# remove space in names
names(DataScenarios) <- gsub(pattern = " ", replacement = "", x = names(DataScenarios))
DataValues$Instrument <- gsub(pattern = " ", replacement = "", x = DataValues$Instrument)

#################


#######################
# list parameters #####

# list of unique scenarios
list_scenarios <- DataScenarios$ScenarioType %>% unique()

# list of instruments
list_instr <- DataScenarios %>% select(-c(ScenarioType,Outcome,proba)) %>% names() %>% unique()


#######################


##########################
# create clean tables ####

Scenarios_tab <- DataScenarios %>% select(ScenarioType, Outcome, proba)

InstPerf_tab <- DataScenarios %>% select(-proba) %>% 
  gather(key = "Inst", value = "Perf", c(all_of(list_instr)))

Values_tab <- DataValues

##########################


######################
# Build scenarios ####


temp <- NULL
temp_result <- NULL

for(i in list_scenarios){
  
  temp <- Scenarios_tab[Scenarios_tab$ScenarioType == i , c("Outcome", "proba")]
  names(temp) <- c(i, "new_proba")
  
  if(is.null(temp_result)) {
    
    temp_result <-
      temp %>% mutate(proba = new_proba) %>% select(-new_proba)
    
  } else {
    
    temp_result <- merge(temp, temp_result, all = T)
    temp_result <- temp_result %>% 
      mutate(proba = proba * new_proba) %>% 
      select(-new_proba)
    
  }
  
}

# list of all possible paths
ScenarioPaths_tab <- temp_result

# clean 
rm(temp, temp_result)

######################


##########################
# link up instruments ####

temp <- NULL
final_temp <- NULL

InstPerf_tab_temp <- InstPerf_tab %>% spread(., key = ScenarioType, value = Perf) 

# for every instrument merge the shock
for (i in list_instr) {
  
  print(i)
  
  temp <- InstPerf_tab_temp %>% filter(Inst == i) %>%
    select(-Inst)
  
  temp_result <- NULL
  # merge the returns to the scenarios
  for (j in list_scenarios) {
    
    
    if (is.null(temp_result)) {
      
      x <- ScenarioPaths_tab %>% lazy_dt()
      
      
    } else {
      
      x <- temp_result %>% lazy_dt()
      
    }
    
    y <- temp %>% select(Outcome, all_of(j)) %>% .[complete.cases(.),] 
    names(y) <- c(j, paste(j, "-Impact", sep = ""))
    
    y <- y %>% lazy_dt()
    
    temp_result <- left_join(x,y, by = j)
    
  }
  
  temp_result <- as_tibble(temp_result)
  
  # sum returns
  temp_columns <- str_detect(names(temp_result), "-Impact" ) %>% names(temp_result)[.]
  temp_result[,i] <- temp_result[,temp_columns] %>% rowSums()
  
  # remove underlying moves
  temp_result <- temp_result %>% select(-all_of(temp_columns))
  
  # save
  if( is.null( final_temp)) {
    final_temp <- temp_result
  } else{
    names_filter <- names(temp_result) %>% str_detect(i) %>% names(temp_result)[.]
    temp_result <- temp_result %>% select(all_of(names_filter))
    final_temp <- cbind(final_temp, temp_result)
  }
  
}


full_impact <- final_temp

##########################

rm(temp, temp_result, final_temp, x)
gc()

###################
# wide to long ####

# used to multiply the shocks

full_impact <- full_impact %>% pivot_longer(cols = all_of(list_instr), names_to = "Inst", values_to = "Impact")

###################



#######################
# round the impact ####

full_impact <- full_impact %>%
  mutate(Impact = round(Impact*2,digits = 0)/2) 

# bin the impact
summarised_impact <- full_impact %>% 
  group_by(Inst, Impact) %>% 
  summarise(proba = sum(proba))

#####################



############################
# rich / cheap impacts ####

# add in impact rich / cheap
# done here because it improves processing speed

rich_cheap_factor <- 1.3 # scale of impact for rich cheap

summarised_impact <- summarised_impact %>% left_join( DataValues, by =c("Inst" = "Instrument"))

summarised_impact <- summarised_impact %>% 
  mutate(Impact_incl_current_price = case_when(Rich_cheap == "rich" ~ 
                                                 case_when( Impact >= 0 ~ Impact / rich_cheap_factor, # when rich and good outcome, result is less massive
                                                            Impact <0 ~ Impact * rich_cheap_factor ), # when rich and bad outcome, result is massive
                                               Rich_cheap == "cheap" ~
                                                 case_when ( Impact >= 0 ~ Impact * rich_cheap_factor, # when cheap and good outcome, result is massive
                                                             Impact <0 ~ Impact / rich_cheap_factor ), # when cheap and bad outcome, result is less massive
                                               Rich_cheap == "par" ~ Impact,
                                               TRUE ~ Impact))

# round for clarity
summarised_impact <- summarised_impact %>% 
  mutate(Impact_incl_current_price = round(Impact_incl_current_price*2,digits = 0)/2) 

# replace Impact with the impact including the current price level
summarised_impact <- summarised_impact %>% 
  mutate(Impact = Impact_incl_current_price) %>% 
  select(-c(Impact_incl_current_price, Rich_cheap))

summarised_impact <- as.data.frame(summarised_impact)

# regroup to avoid duplicate combinations of INST and shock
summarised_impact <- summarised_impact %>% 
  group_by(Inst, Impact) %>% 
  summarise(proba = sum(proba))

#######################


###############################
# display results in grid  ####

# from now on only use the summarised impacts as the analysis of the scenarios is not relevant

# get averages
TempAverages <- summarised_impact %>% group_by(Inst) %>% 
  summarise(ImpactTotal = sum(Impact*proba),
            stdev = sd(Impact*proba),
            sharpe = ImpactTotal / stdev)

View(TempAverages)

sharpe_plot <- TempAverages %>% ggplot(aes(x=stdev , y = ImpactTotal, colour = Inst )) + geom_point(show.legend = FALSE) + theme_bw() + ggtitle("Sharpe Ratios")
ggplotly(sharpe_plot)

ggplot() + 
  geom_histogram(
    data = summarised_impact,
    aes(
      x = Impact,
      y = proba
    ),
    alpha = 0.2,
    colour = "blue",
    fill = "blue",
    stat = "identity"
  ) +
  geom_vline(data = TempAverages,  aes(xintercept = ImpactTotal), colour = "red", linetype = 1) +
  geom_label(data = TempAverages, aes(
    x = ImpactTotal,y = 0,
    label = round(ImpactTotal,2)),
    label.size = 0.01) +
  geom_vline(xintercept = 0, colour = "blue", linetype = 2) +
  facet_wrap(~Inst) + 
  theme_bw() + 
  theme(legend.position = "none")

###############################


######################################################################
# best choices #######################################################
# build a logic to select the top 3 distributions that beat all others.


# make long to wide to fill in all combinations
summarised_impact <- pivot_wider(
  data = summarised_impact,
  names_from = Inst,
  values_from = proba,
  values_fill = 0
)

# make wide to long again
summarised_impact <- pivot_longer(
  data = summarised_impact,
  cols = all_of(list_instr),
  names_to = "Inst", 
  values_to = "proba"
)


# now that all the gaps are filled calculate the cumsum
summarised_impact <- summarised_impact %>%
  arrange(Inst, Impact) %>% 
  group_by(Inst) %>% 
  mutate(cumul_proba = cumsum(proba))

# round to avoid extreme situations
summarised_impact <- summarised_impact %>% mutate( across(!Impact, round, 4))


# plot results
cumulative_density_chart <- summarised_impact %>% 
  ggplot(aes(x= Impact, y = cumul_proba, colour = Inst)) + 
  geom_line() +
  ggtitle("Impact densities")+
  theme_bw()

ggplotly(cumulative_density_chart)

#################################



# Eliminate suboptimal strategies: ie any strategy which is beaten by another
eliminate_func <- function(input_data) {
  
  # compare every strategy one by one,
  # no need to go back
  
  suboptimal <- NULL
  
  for(i in list_instr) {
    
    comp_from <- input_data %>% filter(Inst == all_of(i)) %>% data.frame() %>% select(cumul_proba) 
    temp <- list_instr[list_instr != i]
    
    for( j in temp) {

      comp_to <- input_data %>% filter(Inst == all_of(j)) %>% data.frame() %>% select(cumul_proba)
      # A strategy is suboptimal if another strategy beats it for all impacts
      # if all areas of the comp are negative then it is suboptimal
      
      comp <- cbind(comp_from, comp_to)
      names(comp) <- c("comp_from", "comp_to") 
      comp <- comp %>% mutate(diff = comp_to - comp_from)
      
      if( max(comp$diff) <= 0 ) {
        
        ifelse(is.null(suboptimal), suboptimal <- i, suboptimal <- c(suboptimal, i))
        break()
        
      }
      
    }
    
      
  }
  
  # return the table excluding the suboptimal results
  output <- input_data %>% filter(!Inst %in% suboptimal)
  
  return(output)
  
}

optim_strat <- eliminate_func(summarised_impact)

# plot

temp <- optim_strat %>%   
  ggplot(aes(x = Impact, y = cumul_proba, colour = Inst )) + 
  geom_line() +
  theme_bw() 


ggplotly(temp)

#######################################################################

#######################################
# check out proportion loss making ####

Inst_proportion_below_0 <- summarised_impact %>% 
  mutate(above_0 = ifelse(Impact >= 0, 1, 0))%>% 
  group_by(Inst) %>% 
  summarise(avg = sum(Impact * proba),
            sd = sd( Impact * proba),
            perc_above_0 = sum(above_0 * proba),
            perc_below_0 = sum( (1 - above_0) * proba) )

View(Inst_proportion_below_0)

#######################################


########################
# build portfolios #####

temp <- NULL
portfolio_tab <- data.frame(list_instr)

nbr_draws <- 10000

for (i in 1:nbr_draws){
  temp_rows <- sample(1:length(list_instr),size = 5, replace = F)
  temp_weights <- runif(length(temp_rows))
  temp_weights <- temp_weights/sum(temp_weights)
  temp_weights <- round(temp_weights, digits = 3)
  temp <- matrix(NA, nrow = length(list_instr), ncol = 1 )
  temp[temp_rows] <- temp_weights
  temp <- data.frame(temp)
  names(temp) <- paste("prtf_", i, sep = "")
  portfolio_tab <- cbind(portfolio_tab, temp)
  
}

# fill NAs with 0
portfolio_tab[is.na(portfolio_tab)] = 0

########################

##############################################
# merge portfolios with impacts and proba #####


full_impact_portfolio_tab <- left_join( summarised_impact  ,
                                        portfolio_tab,
                                        by = c("Inst" = "list_instr"))



##############################################


##############
# calc portfolio returns ####

for (i in 1:nbr_draws) { 
  col <- paste("prtf_", i, sep = "")
  full_impact_portfolio_tab[,col] <- full_impact_portfolio_tab[,"Impact"] * full_impact_portfolio_tab[,"proba"] * full_impact_portfolio_tab[,col]
  }

##############################


####################################
# produce performance metrics ######

columns <- str_detect(names(full_impact_portfolio_tab), "prtf_")

full_impact_portfolio_tab_ret <- full_impact_portfolio_tab[,columns] %>% apply(MARGIN = 2, sum)
full_impact_portfolio_tab_sd <- full_impact_portfolio_tab[,columns] %>% apply(MARGIN = 2, sd)

full_impact_portfolio_tab <- data.frame(names(full_impact_portfolio_tab)[columns], full_impact_portfolio_tab_ret, full_impact_portfolio_tab_sd)
names(full_impact_portfolio_tab) <- c("portfolio", "return", "sd")

full_impact_portfolio_tab <- full_impact_portfolio_tab %>% mutate(sharpe = return / sd)

##################################

##########################
# display  ###############

portfolio_sharpe <-
  ggplot(full_impact_portfolio_tab, aes(x = sd, y = return, colour = portfolio)) + geom_point() + theme_bw() +
  ggtitle("All Portfolio Performance") + theme(legend.position="none")



#########################

#####################
# display top #####

TOP_tab <- full_impact_portfolio_tab %>% arrange(desc(sharpe))  %>% head(20)

portfolio_sharpe <- 
  ggplot(TOP_tab, aes(x = sd, y = return, colour = portfolio)) + 
  geom_point(show.legend = FALSE) + 
  geom_point() + theme_bw() + 
  ggtitle("Top Portfolio Performance") + theme(legend.position="none") 

ggplotly(portfolio_sharpe)

###################

##################
# portfolio charac

temp <- names(portfolio_tab) %in% c("list_instr", TOP_tab$portfolio)
temp <- portfolio_tab[,temp] %>% 
  pivot_longer(cols = TOP_tab$portfolio, names_to = "Portfolio", values_to = "Weight") %>% 
  pivot_wider(names_from = "Portfolio", values_from = "Weight")

# remove unused instruments
temp <- temp[rowSums(temp[,2:11]) != 0,]

# order by the highest weights of the best portfolio
temp <- temp %>% arrange(desc(temp[,2]))

temp %>% View()

temp <- temp %>% arrange((temp[,2]))
# plot heatmap

temp_heatmap <- temp %>% 
  pivot_longer(cols = TOP_tab$portfolio, names_to = "Portfolio", values_to = "Weight") %>% 
  mutate(list_instr = factor(list_instr, levels = temp$list_instr),
         Portfolio = factor(Portfolio, levels = TOP_tab$portfolio)) %>% 
ggplot(aes(x = Portfolio, y = list_instr, colour = Weight, fill = Weight)) + geom_tile() +  
  scale_fill_gradient(low = "white", high = "steelblue") +
  labs(x = "", y = "") +
  theme_bw() +
  theme(legend.position = "none")

ggplotly(temp_heatmap)
