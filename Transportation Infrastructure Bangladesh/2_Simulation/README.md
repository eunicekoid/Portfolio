## Introduction

This part of the analysis investigates how the driving time of trucks on roads N1, N2, and side roads is affected depending on the condition of bridges. 

## Files

├── README.md         
│                         
├── data	      
│   ├── README.md        
│   ├── processed      
│   └── raw           
│
├── experiment        <- Output results from running the simulation for different scenarios, gathered in csvs.
|
|
├── model             <- All edited (mesa)model-files necessary to run the simulation, based on Yilin HUANG's work.
│
├── notebook          <- Jupyter notebook for data cleaning
│   └── data          <- Needed data for the notebooks          



## How to Use

* Go through the data preparation:
```
	Go to directory 'notebook' and open 'data-preparation.ipynb'
```

* Launch the simulation model with visualization (this file can be found in the directory 'model')
```
    $ python model_viz.py
```

* Launch the simulation model without visualization (this file can be found in the directory 'model')
```
    $ python model_run.py
```

* Go through the resulting data
```
	Go to directory 'experiment' and open excel file associated with a scenario. 
```