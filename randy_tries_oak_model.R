

## Randy tries Exercise 8 with Oak model he knows

## Dependencies (load packages and files) ----

library(rsyncrosim)
library(tidyverse)


oak_library <- ssimLibrary("oak_model/oak-redo.ssim")

## Load project definitions (Called "Definitions" in SyncroSim by default) ----

oak_project <- project(ssimObject = oak_library,
                       project = "Definitions")
# check oak_project
oak_project


## Run original scenario ----

original_scenario <- run(oak_project,
                         scenario = c('original'))

## View results ----

# first check run log
runLog(original_scenario)


# make dataframe of outputs
org_scenario_outputs <- datasheet(original_scenario, 
                                  name = "stsim_OutputStratumState")

# initial conditions look weird
subset(org_scenario_outputs, 
       Timestep == "0" & Iteration == "1")


original_scenario <- run(oak_project,
                         scenario = c('original'))
# I think they are!  the CalcFromDist value is NA

## Wrangle and plot results ----
org_scenario_outputs_1000 <- org_scenario_outputs %>%
  filter(Timestep == 1000) %>%
  group_by(StateClassID) %>%
  summarise(Amount = sum(Amount))

org_scenario_outputs_1000$StateClassID <- factor(org_scenario_outputs_1000$StateClassID, levels = org_scenario_outputs_1000$StateClassID)



class_amounts_chart <- 
  ggplot(data = org_scenario_outputs_1000, 
         aes(x = StateClassID, y = Amount)) +
  geom_bar(stat = "identity") +
  labs(
    title = "Original Scenario",
    caption = "Chart © Randy Swaty",
    x = "",
    y = "Number of cells") +
  coord_flip() +
  theme_bw(base_size = 14) +
  scale_x_discrete(limits = rev)


class_amounts_chart


## Make a new scenario(copy of original), change something

org_scenario_no_fire <- scenario(ssimObject = oak_project,
                                  scenario = "org_scenario_no_fire",
                                  sourceScenario = original_scenario)


# Make sure this new Scenario has been added to the Library
scenario(oak_library)  # looks good

# try to load in and change inputs

#  need to find correct table
datasheet(oak_project)

# 
# # Retrieves a dataframe of the State Class definitions for this Project
# myStateClasses = datasheet(oak_project, name = "stsim_Transition")
# myStateClasses


myNewInputDataframe <- datasheet(org_scenario_no_fire,
                                 name = "stsim_Transition",
                                 empty  =FALSE) 

myNewInputDataframe <- myNewInputDataframe %>%
                            mutate(Probability = ifelse(TransitionTypeID %in%
                                                        c("Mixed Fire",
                                                          "Surface Fire",
                                                          "Replacement Fire"),
                                                        0, 
                                                        Probability))

saveDatasheet(org_scenario_no_fire,
             myNewInputDataframe,
             "stsim_Transition")
                              
org_scenario_no_fire <- run(oak_project,
                            scenario = c('org_scenario_no_fire')) 


# make dataframe of outputs
no_fire_outputs <- datasheet(org_scenario_no_fire, 
                                  name = "stsim_OutputStratumState")



