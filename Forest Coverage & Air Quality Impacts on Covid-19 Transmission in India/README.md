## Analyzing and Forecasting Forest Coverage Impacts on Air Quality and Covid-19 Transmission in India Using Machine Learning

(Completed November 2020)

The Covid-19 virus spreads respiratorily as people come in contact with one another. Preliminary evidence in the United States (as of November 2020) shows that environmental factors such as forest density and air quality may have an impact on the spread and mortality rate of Covid-19 ([Costello, 2020](https://scopeblog.stanford.edu/2020/07/17/why-air-pollution-is-linked-to-severe-cases-of-covid-19/)).
- Repiratory and cardiovascular complications are impacted by air quality ([Forouzanfar et al., 2017](https://www.thelancet.com/journals/lancet/article/PIIS0140-6736(17)32366-8/fulltext#articleInformation)).
- Air quality depends on the capacity of trees to remove air pollutants and eliminate volatile organic compounds that contribute to ozone and PM2.5 formation ([Chameides et al.,1988](https://www.science.org/doi/10.1126/science.3420404)). 
- India has high air pollution from urbanization and industry, particularly from the energy sector which might worsen the transmission of Covid-19 ([Contreras and Ferri, 2016](https://www.sciencedirect.com/science/article/pii/S187705091630758X)). 

This analysis investigates the relationship between forest coverage and air quality with the number of Covid-19 cases in India. It aims to answer the following question: <em>Does high forest coverage slow the spread of Covid-19 and minimize cases in India due to better air quality?</em>

The data used in this analysis is from open source resources:
- AnuragAnalog. (2020, June 19). Geodata-of-India [Dataset](https://github.com/AnuragAnalog/Geodata-of-India)
- Development Data Lab. (2020, April 14). Development Data Lab [Dataset](http://www.devdatalab.org/covid)
- Socioeconomic High-resolution Rural-Urban Geographic Platform


<details>
<summary><b><u>Approach</b></u></summary>
<br> 

1. Conduct exploratory data analysis by each Indian state, examining the following three main variable groups: air quality, health and demographic, and Covid-19 cases. 
    - Air quality variables are total area of forest, the forest cover value, and mean pollution. 
    - Health and demographic variables are slum, work and total population, urban share, population density and number of doctors and hospitals. 
    - Covid-19 variables are total cases and deaths. 

2. Apply spatial visualization, regression, and clustering algorithms to identify patterns and relationships between variables. 

</details>




<details>
<summary><b><u>Data Collection and Interrogation</b></u></summary>
<br> 

Covid-19 data
- Data from January 30 to April 26, 2020 from the Data Development Lab India (DLL India). Files used: covid_cases_deaths_district.csv, covid_deaths_recoveries.csv, and covid_infected_deaths.csv 
- The following operations were done: 
    - Renamed the state names according to the state name in shapefile
    - Merged Covid_cases_death_districts with death_recoveries by state_id
    - Dropped duplicates
    - Recovered number of Covid-19 patients by summing up grouped data by state

Health and demographics data
- The files titled pc11_demographics.csv and health_district_pc11.csv are from DLL India and the Socioeconomic High-resolution Rural-Urban Geographic Platform (SHRUG) (2020). The demographics data is from the 2011 population census; the relevant variables are StateID, UrbanShare, PopDens, StateName, SlumPop, TotPop, WorkPopGeo. 

Air quality and forest data
- The mean pollution data (ddl_pollution_sedac_lgd.csv) is from DLL India and includes data on mean pollution per state. The state names were renamed according to the state name in shapefile, merging on state ID.
- Forest data (Indian_forest.csv and shrug_ec13_state_key.csv) is from the SHRUG platform. This consists of a calculation of forest coverage by pixel density of each state photographed by satellites between 2000 and 2014. 2014 forest data was used because it is the most recent data available; the relevant variables are the total amount of forest coverage and the maximum value of forest cover (percent) in each district. This data was reformatted and cleaned by merging and averaging the data by state. States were renamed according to the state names in the shapefile and merged with the shapefile.

Final dataframe
- The aforementioned cleaned data along with the Indian shapefile, were saved as the final dataframe. The shape file was retrieved from Github user AnuragAnalog (2020) and contains the boundaries of India. 
- The variables of interest are: Total number of hospitals, Total number of doctors, urban share, population density, slum population, total population, working population, mean pollution, forest data from 2000 until 2014, ec13_state_id, Covid-19 deaths and cases and average.

The data has the following limitations:
1. The India shapefile contains new states; for example, Ladakh became a state in 2019. Air quality data is not available for newly-created states. However, since air quality data overlaps with other known maps of India, the consequence of not having accurate mapping from state to air quality is insignificant. 
2. The forest data is from 2000 to 2014 while Covid-19 outbreak data start from 2020. The forest condition might have changed between 2015 and 2019. 
3. Demographic data comes from 2011. 
4. The timeframe from which the mean population was taken is unknown. 
5. Covid-19 cases and deaths change frequently, so the data will quickly become outdated.  
6. Two states were dropped in this analysis, Ladakh and Telangana, because demographic data was not available. 


</details>


<details>
<summary><b><u>Literature Review</b></u></summary>
<br> 

 
| Author                | Year | Description in Literature                                                                                                                                                                         | Brief Summary                                                                                                                                                        |
| --------------------- | ---- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Chameides et al.      | 1988 | Trees improve air quality by directly removing air pollutants, altering local microclimates and building energy use, and eliminating volatile organic compounds (VOCs).                           | Without trees, these mechanisms can contribute to O3 and PM2.5 formation.                                                                                            |
| Greenstone & Hanna    | 2014 | India has high levels of air pollution due to industry and consumption.                                                                                                                           | Air pollution has a big effect on mortality in India especially affecting people with a higher chance of respiratory diseases.                                         |
| Forouzanfar et al.    | 2016 | Air pollution causes 4.2 million deaths due to damages to the respiratory and cardiovascular systems                                                 | A small increase in long-term exposure to pollution causes larger increases in the Covid-19 death rate.                                                              |
| Jarvis et al.         | 2020 | Several researchers in multiple countries have been exploring the relationship between the spread of Covid-19 and the physical distance between people.                                         | The spread of the virus substantially declines when people actively adopt physical distance measures because the virus is mostly transferred through the air. |
| Roviello & Roviello   | 2020 | A study from Italy proved that the Southern region of Italy had less Covid-19 compared to the Northern region because of high forestry which increased its capacity to absorb particulate matter. | Different species of trees and plants have varying ability to generate antivirals.                                                                                   |
| Fattorini & Regoli    | 2020 | Researchers explore the relationship with local air pollution and the spread of the virus in Italy.                                                                                  | Environmental pollution should be considered in pandemic prevention policies.                                                                                       |
| Sahoo et al.          | 2020 | Air quality and environmental factors are examined as contributing factors to Covid-19's transmission.                                                                          | There is a relationship between particulate matter, population density, and Covid-19 cases and deaths, though more research is needed to solidify this finding.      |
| Mishra, Gayen & Haque | 2020 | Urbanisation plays a big role in the spread of the global pandemic caused by Covid-19 particularly in India.                                                                                                                  | Disease transmission in the big cities in India is especially fast in urban slum areas.                                                                              |

<b>References</b>
<br>
- Chameides, W. L., Lindsay, R. W., Richardson, J., & Kiang, C. S. (1988). The role of biogenic hydrocarbons in urban photochemical smog: Atlanta as a case study. <em>Science, 241</em>(4872), 1473-1475.
- Fattorini, D., & Regoli, F. (2020). Role of the chronic air pollution levels in the Covid-19 outbreak risk in Italy. <em>Environmental Pollution</em>, 114732.
- Forouzanfar, M. H., Afshin, A., Alexander, L. T., Anderson, H. R., Bhutta, Z. A., Biryukov, S., ... & Cohen, A. J. (2016). Global, regional, and national comparative risk assessment of 79 behavioural, environmental and occupational, and metabolic risks or clusters of risks, 1990–2015: a systematic analysis for the Global Burden of Disease Study 2015. <em>The lancet, 388</em> (10053), 1659-1724.
- Greenstone, M., & Hanna, R. (2014). Environmental regulations, air and water pollution, and infant mortality in India. American Economic Review, 104(10), 3038-72.
- Jarvis, C. I., Van Zandvoort, K., Gimma, A., Prem, K., Klepac, P., Rubin, G. J., & Edmunds, W. J. (2020). Quantifying the impact of physical distance measures on the transmission of COVID-19 in the UK. BMC medicine, 18, 1-10.
- Mishra, S. V., Gayen, A., & Haque, S. M. (2020). COVID-19 and urban vulnerability in India. Habitat international, 103, 102230.
- Roviello, V., & Roviello, G. N. (2020). Lower COVID-19 mortality in Italian forested areas suggests immunoprotection by Mediterranean plants. Environmental chemistry letters, 1-12.
- Sahoo, P. K., Mangla, S., Pathak, A. K., Salãmao, G. N., & Sarkar, D. (2020). Pre-to-post lockdown impact on air quality and the role of environmental factors in spreading the COVID-19 cases-a study from a worst-hit state of India. <em>International journal of biometeorology</em>, 1-18




</details>

## Analysis

### Spatial Visualization

Almost all states with high cases and deaths have a large number of total hospitals, doctors, work population, total population, slum population, and mean pollution. These states also have a low amount of forest coverage, total forest, and surprisingly, population density. 

<p align="center">
  <img src="images/map_all_variables.png?raw=true" style="transform: scale(0.5);">
</p>


### Regression 

Based on the linear regression, an increase in all variables except forest coverage value will also increase Covid-19 cases.


<p align="center">
  <img src="images/all_regression.png?raw=true" style="transform: scale(1);">
</p>

The MSE and R-squared values are summarized for each variable below.

| **Variable** | **Mean Squared Error (MSE)** | **Coefficient of determination (R<sup>2</sup>)** |
| --------------------- | ---------------------------- | ------------------------------------------------ |
| Urban Share           | 0.10                         | \-0.13                                           |
| Total Population      | 4.68 x 10<sup>15</sup>       | 0.55                                             |
| Slum Population       | 5.66 x 10<sup>12</sup>       | 0.58                                             |
| Work Population       | 9.07 x 10<sup>14</sup>       | 0.60                                             |
| Total Doctors         | 4.06 x 10<sup>5</sup>        | 0.44                                             |
| Total Hospitals       | 9.95 x 10<sup>4</sup>        | \-3.17                                           |
| Mean Pollution        | 6.83 x 10<sup>5</sup>        | 0.02                                             |
| Average Forest        | 3.09 x 10<sup>9</sup>        | \-0.30                                           |
| Forest Coverage (%)   | 71.17                        | 0.26                                             |
| Total Forest (area)   | 8.47 x 10<sup>7</sup>        | \-1.13                                           |


Variables with small MSE values are not widely dispersed around the mean. There is a wide range of values for almost all of the variables except urban share, which makes sense given the high population and land area of India. 

The variables with a good fit with total deaths have positive R-squared values: total population, slum population, work population, total doctors, mean pollution, and forest coverage. 

### Clustering 



The data was spatially clustered using KMeans and three clusters. Mean population, slum population, forest coverage, work population, and total cases were examined based on three cateogries: low, medium, and high.

| **Cluster** | **Total Cases** | **Slum Population** | **Work Population** | **Mean Pollution** | **Forest Coverage** |
| ----------- | --------------- | ------------------- | ------------------- | ------------------ | ------------------- |
| **0**       | Medium          | Medium              | Medium              | Medium             | Medium              |
| **1**       | Low             | Low                 | Low                 | Low                | High                |
| **2**       | High            | High                | High                | High               | Low                 |

Clustering was conducted to see if increasing forest coverage will help decrease Covid-19 cases and deaths. In addition, the analysis investigates if a decrease in pollution (e.g., by asking people to work from home, reducing energy consumption to improve air quality) would reduce Covid-19 cases and deaths. The mean of the clustering results are as follows: 

| **Cluster**             | **0**      | **1**     | **2**      |
| ----------------------- | ---------- | --------- | ---------- |
| **Total Cases**         | 26,698     | 716       | 51,016     |
| **Mean Pollution**      | 1,123      | 422       | 4,311      |
| **Slum Population**     | 5,688,993  | 202,048   | 9,044,194  |
| **Forest Coverage (%)** | 17         | 35        | 16         |
| **Work Population**     | 33,884,680 | 3,872,275 | 57,621,300 |

<p align="center">
  <img src="images/map_cluster.png?raw=true" style="transform: scale(.5);">
</p>

There are 9 states in cluster 0 that have a medium number of total cases. In cluster 1, there are 17 states with a low number of cases. In cluster 2, there are 2 states with the highest number of cases.


**Observations**
1. States with higher forest coverage generally have lower Covid-19 cases. 
    - There are a few outliers and exceptions to this pattern. The state with the most cases, Maharashtra, has a relatively low forest coverage percentage. The high cases could be due to the fact that there is a large population in Maharashtra. 
2. Higher forest coverage have relatively less mean pollution. 
    - On a larger scale, this pattern is consistent. This supports the point that forests and pollution are negatively correlated. 
3. Generally, there is a small positive correlation between pollution and total cases.
    - The mean squared error for this relationship is positive, so there is a slight correlation, though not as strong as hypothesized. Forest coverage is a better predictor of total cases. More research into the contributors to pollution would help identify the specific causes of pollution and how they might affect Covid-19 cases.


## Conclusion 

In summary, states with lower forest coverage typically have higher pollution. Higher polluted states tend to have higher populations. Polluted and populated states have a higher number of Covid-19 cases. These findings suggest that environmental factors like forest density and air quality impact the transmission of Covid-19. Policies that improve air quality such as decreased fuel consumption and limits on deforestation could be enacted as pandemic prevention policies. 