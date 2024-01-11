# ST-Sim Online Course
# Exercise 8 - Running ST-Sim from R

# Last edited by: ApexRMS, April 16, 2021

# IMPORTANT SETUP INSTRUCTIONS
#
# Before running this script:
#   1. Install SyncroSim software (preferably Windows version - see www.syncrosim.com/download)
#   2. Install rysncrosim, raster and rgdal R packages (from CRAN)
#
# Note that this Exercise was developed against the following:
#   SyncroSim - version 2.2.24 (note that instructions below assume Windows version but works also with Linux)
#   R - version 4.0.3
#   SyncroSim packages:
#      stim - version 3.2.26
#   R packages:
#      rsyncrosim - version 1.2.4
#      raster - version 3.4-5  (which requires rgdal package to be installed also)
#      this.path - version 0.2.1

# ****************************************************************************************************
# Task 1: Setup --------------------------------------------------------------------------------------
# ****************************************************************************************************

# Load R packages
library(rsyncrosim)  # package for working with SyncroSim
library(raster)      # package for working with raster data
library(this.path)   # package for setting the working directory

# Check to see if the stsim SyncroSim package is installed (and install it if necessary)
myInstalledPackages = package()
if (!(is.element("stsim", myInstalledPackages$name))) addPackage("stsim")


# ****************************************************************************************************
# Task 2: Post-processing output ---------------------------------------------------------- 
# ****************************************************************************************************

# In this Task you will learn how to post-process output from a SyncroSim model run

# Start by opening the following library in SyncroSim for Windows:
# Folder: Documents/SyncroSim/Course/Exercise 8/
# Filename: Exercise 8.ssim
#
# Look at the Project Definitions and Scenario in this Library
# This Library is the same one used to start Exercise 4
#

# Open an existing SyncroSim Library ****************************

# Check the current working directory matches the Exercise 8 folder
setwd(this.dir())  # set the working folder to the folder of this R script
getwd()

# Lists the files in the current working directory - make sure you see the file "Exercise 8.ssim"
list.files()

# Opens Library. Note that if the Library does not exist already then this command will create a new empty library
myLibrary <- ssimLibrary("Exercise 8.ssim")


# Load Project Definitions ****************************

# If this command returns no projects, SyncroSim created a new blank library - change your working folder above and try again
project(myLibrary)     # If you get an error you may need to replace with: rsyncrosim::project(myLibrary)
myProject <- project(myLibrary, project="Definitions")
myProject

# List all the datasheets available for stsim Projects
datasheet(myProject, summary=TRUE)

# Retrieves a dataframe of the State Class definitions for this Project
myStateClasses = datasheet(myProject, name="stsim_StateClass")
myStateClasses


# Load and Run a Scenario  ****************************

# List all the Scenarios in the Library. Note that this list can include Result Scenarios
scenario(myLibrary, summary=TRUE)

# Get the "No harvest" scenario
myScenario <- scenario(myLibrary, scenario="No harvest")
myScenario

# Run the "No harvest" scenario (with multiprocessing)
myResultScenario <- run(myScenario, jobs = 6)

# List all the datasheets available for stsim Scenarios (including both input and output)
myDataSheetGuide <- datasheet(myResultScenario, summary = TRUE)  # The list is long! 

head(myDataSheetGuide)  # You can view the full list of datasheets by clicking on "datasheetGuide" in top right "Environment" pane of RStudio


# Analyse the Scenario's Tabular Output ****************************

# Retrieve raw tabular state class tabular output into a dataframe (see myDatasheetGuide for valid names)
outputRaw <- datasheet(myResultScenario, name="stsim_OutputStratumState")

# Show a bit of this dataframe
# It is raw output, so it has lots of rows - however you can view it also using RStudio "Environment" pane
tail(outputRaw)

# Now we can post-process this output however we like in R
# We use only base R functions to summarize and plot here - other packages can help with this (e.g. ddplyr, ggplot2, rasterVis)

# First we sum the Amount field over all fields except Iteration, Timestep and StateLabelXID
outputSum <- aggregate(outputRaw["Amount"], by=outputRaw[c("Iteration", "Timestep", "StateLabelXID")], sum)
tail(outputSum)

# Then we average over Iterations
outputMean <- aggregate(outputSum["Amount"], by=outputSum[c("Timestep", "StateLabelXID")], mean)
tail(outputMean)

# And finally plot the mean conifer area over time
conifer <- subset(outputMean, StateLabelXID=="Conifer")
x<-conifer$Timestep
y<-conifer$Amount
plot(x,y, type ="l", col="blue", xlab="Timestep", ylab="Total Conifer Area (ac)")


# Analyse the Scenario's Spatial Output ****************************

# Retrieve raw raster output into a dataframe (see myDatasheetGuide for valid names)
# Get only the raster data for iteration 1 and timestep 20
outputRaster <- datasheetRaster(myResultScenario, datasheet="stsim_OutputSpatialState", iteration=1, timestep=20)
outputRaster

plot(outputRaster)        # Plot the raster
freq(outputRaster)        # Count of # of cells for each State Class ID value on the raster


# ****************************************************************************************************
# Task 3: Editing and running scenarios ---------------------------------------------------------
# ****************************************************************************************************

# In this Task you will learn how to modify and then run a new Scenario

# List the Scenarios in this Project
scenario(myLibrary)

# Get the Scenario with no harvest
myScenario <- scenario(myProject, scenario = "No harvest")
name(myScenario)

# Make a copy of this scenario and give the copy a new name
myScenario2 <- scenario(myProject, scenario="Harvest 2000 ac/yr", sourceScenario=myScenario)
scenario(myLibrary)


# Edit the inputs for this new Scenario ****************************

# Create an empty template dataframe corresponding to a Transition Target Datasheet for this new scenario
mySheetData <- datasheet(myScenario2, name="stsim_TransitionTarget", empty=TRUE)
str(mySheetData)  # See the structure of the new dataframe (including factors for Transition Groups)

# Now add a new row to this dataframe specifying 2000 ac/hr Harvest
mySheetData <- addRow(mySheetData, data.frame(TransitionGroupID="Harvest [Type]",Amount=2000))
mySheetData

# Save this dataframe back to the new Scenario's datasheet
saveDatasheet(myScenario2, data=mySheetData, name="stsim_TransitionTarget")

# ****************************************************************************************************
# Go to SyncroSim for Windows and select "File | Refresh All Libraries"
# While still in SyncroSim for Windows, double-click on the scenario "Harvest 2000 ac/yr", 
# then click on the Transition Targets tab to see the new target for this scenario
# ****************************************************************************************************


# Run this new Scenario and display results information (in summary form) ****************************

resultSummary <- run(myProject, scenario="Harvest 2000 ac/yr", jobs=6, summary=T)   # Uses multiprocessing
resultSummary

# ****************************************************************************************************
# Return to SyncroSim for Windows and select "File | Refresh All Libraries" again to see that Results have been 
# created for this scenario. While still in SyncroSim for Windows, review the model inputs and outputs 
# (by selecting "Add Results" for this scenario, then view Charts and Maps)
# ****************************************************************************************************


# ****************************************************************************************************
# Task 4: Creating new models from scratch -------------------------------------------------------------
# ****************************************************************************************************

# In this Task you will learn how to create a new SyncroSim Library and model from scratch

# ****************************************************************************************************
# Choose a name for your new library (use a name that doesn't exist already in your Exercise 8 folder)
myNewLibraryName <- "Exercise 8 New.ssim"   
# ****************************************************************************************************

# Create a new library
# NOTE: this will only create a new library if the file doesn't exist already
myLibrary <- ssimLibrary(myNewLibraryName)

# Display internal names of all the library's datasheets - corresponds to the the 'File-Library Properties' menu in SyncroSim
datasheet(myLibrary, summary=TRUE)

# Get the current values for the Library's Backup Datasheet
sheetData <- datasheet(myLibrary, name="core_Backup")                        # Get the current backup settings for the library
sheetData

# Modify the values for the Library's Backup Datasheet
sheetData$IncludeOutput <- TRUE  # Add output to the backup
saveDatasheet(myLibrary, data=sheetData, name="core_Backup")                       # Save the new dataframe back to the library
datasheet(myLibrary, "core_Backup")


# Setup the Project's Definitions *****************************

myProject <- project(myLibrary, project="Definitions")
project(myLibrary, summary=TRUE)     # Lists the projects in this library

# Display internal names of all the project's datasheets - corresponds to the Project Properties in SyncroSim
datasheet(myProject, summary=T)

# Terminology
sheetData <- datasheet(myProject, "stsim_Terminology")
sheetData
sheetData$AmountUnits[1] <- "Hectares"
sheetData$StateLabelX[1] <- "Forest Type"
saveDatasheet(myProject, sheetData, "stsim_Terminology")
datasheet(myProject, "stsim_Terminology")

# Stratum
sheetData <- datasheet(myProject, "stsim_Stratum", empty=T)   # Returns empty dataframe with only required column(s)
sheetData <- addRow(sheetData, "Entire Forest")
saveDatasheet(myProject, sheetData, "stsim_Stratum", force=T)
datasheet(myProject, "stsim_Stratum", optional=T)   # Returns entire dataframe, including optional columns

# First State Class Label (i.e. Forest Types)
forestTypes <- c("Coniferous", "Deciduous", "Mixed")
saveDatasheet(myProject, data.frame(Name=forestTypes), "stsim_StateLabelX", force=T)

# Second State Label (not used)
saveDatasheet(myProject, data.frame(Name="All"), "stsim_StateLabelY", force=T)

# Transition Types
transitionTypes <- data.frame(Name=c("Fire", "Harvest", "Succession"), ID=c(1,2,3))
saveDatasheet(myProject, transitionTypes, "stsim_TransitionType", force=T)

# State Classes
stateClasses <- datasheet(myProject, name="stsim_StateClass")
stateClasses <- addRow(stateClasses, data.frame(Name="Coniferous:All", StateLabelXID="Coniferous", StateLabelYID="All"))
stateClasses <- addRow(stateClasses, data.frame(Name="Mixed:All", StateLabelXID="Mixed", StateLabelYID="All"))
stateClasses <- addRow(stateClasses, data.frame(Name="Deciduous:All", StateLabelXID="Deciduous", StateLabelYID="All"))
saveDatasheet(myProject, stateClasses, "stsim_StateClass", force=T)

# Ages
ageFrequency <- 1
ageMax <- 101
ageGroups <- c(20,40,60,80,100)
saveDatasheet(myProject, data.frame(Frequency=ageFrequency, MaximumAge=ageMax), "stsim_AgeType", force=T)
saveDatasheet(myProject, data.frame(MaximumAge=ageGroups), "stsim_AgeGroup", force=T)

# ****************************************************************************************************
# Go to SyncroSim for Windows and open the new library  you created (e.g. Exercise 8 New.ssim);
# Check that the Library and Project Properties are correct
# ****************************************************************************************************


# Create new Scenario (within this Project) and setup the Scenario Properties  *****************************

# Create a new SyncroSim "No Harvest" scenario
myScenario <- scenario(myProject, "No harvest")

# Display the internal names of all the scenario datasheets
myDataSheetGuide <- subset(datasheet(myScenario, summary=T), scope=="scenario")   # Generate list of all Datasheets as reference

# Edit the scenario datasheets:

# Run Control - Note that we will set this as a non-spatial run
sheetName <- "stsim_RunControl"
sheetData <- data.frame(MaximumIteration=6, MinimumTimestep=0, MaximumTimestep=20, isSpatial=F)
saveDatasheet(myScenario, sheetData, sheetName)

# States
sheetName <- "stsim_DeterministicTransition"
sheetData <- datasheet(myScenario, sheetName , optional=T, empty=T)
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Coniferous:All",StateClassIDDest="Coniferous:All",AgeMin=21,Location="C1"))
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Deciduous:All",StateClassIDDest="Deciduous:All",Location="A1"))
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Mixed:All",StateClassIDDest="Mixed:All",AgeMin=11,Location="B1"))
saveDatasheet(myScenario, sheetData, sheetName)

# Probabilistic Transitions
sheetName <- "stsim_Transition"
sheetData <- datasheet(myScenario, sheetName , optional=T, empty=T)
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Coniferous:All",StateClassIDDest="Deciduous:All", TransitionTypeID="Fire",Probability=0.01))
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Coniferous:All",StateClassIDDest="Deciduous:All", TransitionTypeID="Harvest",Probability=1,AgeMin=40))
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Deciduous:All",StateClassIDDest="Deciduous:All", TransitionTypeID="Fire",Probability=0.002))
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Deciduous:All",StateClassIDDest="Mixed:All", TransitionTypeID="Succession",Probability=0.1,AgeMin=10))
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Mixed:All",StateClassIDDest="Deciduous:All", TransitionTypeID="Fire",Probability=0.005))
sheetData <- addRow(sheetData, data.frame(StateClassIDSource="Mixed:All",StateClassIDDest="Coniferous:All", TransitionTypeID="Succession",Probability=0.1,AgeMin=20))
saveDatasheet(myScenario, sheetData, sheetName)

# Initial Conditions: Non-spatial

sheetName <- "stsim_InitialConditionsNonSpatial"
sheetData <- data.frame(TotalAmount=100, NumCells=100, CalcFromDist=F)
saveDatasheet(myScenario, sheetData, sheetName)
datasheet(myScenario, sheetName)

sheetName <- "stsim_InitialConditionsNonSpatialDistribution"
sheetData <- data.frame(StratumID="Entire Forest", StateClassID="Coniferous:All", RelativeAmount=1)
saveDatasheet(myScenario, sheetData, sheetName)
datasheet(myScenario, sheetName)

# Transition targets - set harvest to 0 for this scenario
saveDatasheet(myScenario, data.frame(TransitionGroupID="Harvest [Type]", Amount=0), "stsim_TransitionTarget")

# Output options - non-spatial only
datasheet(myScenario, "stsim_OutputOptions")
sheetData <- data.frame(SummaryOutputSC=T, SummaryOutputSCTimesteps=1,
                       SummaryOutputTR=T, SummaryOutputTRTimesteps=1)
saveDatasheet(myScenario, sheetData, "stsim_OutputOptions")

# ****************************************************************************************************
# Go to SyncroSim for Windows and Refresh; check the Scenario's Properties are all correct
# ****************************************************************************************************


# Run this new Scenario **************************************

resultSummary <- run(myProject, scenario="No harvest", jobs=6, summary=T)   # Uses multiprocessing
resultSummary

backup(myLibrary)  # Backup of your library - automatically zipped into a .backup subfolder

# ****************************************************************************************************
# Return to SyncroSim for Windows and Refresh to see that Results have been created
# Remember to add your scenario to the Active Results in order to then create a Chart
# Use SyncroSim for Windows to view the review the model inputs and outputs
# ****************************************************************************************************
