## Data Preparation

Raw data from [Bangladesh&#39;s Roads and Highways Department](https://www.rhd.gov.bd/RHDAtGlance/index.asp) - RMMS and BMMS database. 


### 1_Data_Cleaning.ipynb
<details>
<summary><b><u>Cleaning of Roads Data</b></u></summary>
<br>  
The length of the road names data were standardized to have the same number of digits (e.g., from N1 to N100). This helped address semantic inconsistencies, ensuring that the data types had a consistent number of characters. In addition, the standardization facilitated easier cross-referencing between datasets and resolved data precision inconsistencies.
<br>
<br>
Subsequently, null and missing values were removed. Typos were identified by checking for discrepancies between entries of latitude and longitude values in each road. If the difference was less than 0.01 of the location values of the LRP (Location Reference Point) name before it, the location values were updated with the latitude or longitude data of the previous point in the road. This process effectively eliminated outliers.

</details>


<details>
<summary><b><u>Cleaning of Bridges Data</b></u></summary>
<br>  
After removing duplicates and data entries with null longitude and latitude values, errors in longitude and latitude data were checked. Some structures had latitude and longitude values in the wrong column, so this was corrected. Then, using the road name and the LRP name that were standardized beforehand, the latitude and longitude data were cross-referenced with the cleaned roads dataset to ensure that the correct location was recorded; this step aimed to address any semantic inaccuracies in the bridge data.
<br>
<br>
Finally, typos were examined and edited if necessary. This was done by ensuring that the location data differences between structures of the same road were less than 0.03 degrees on either longitude or latitude. If not, they were updated with the location value of the bridge before it (backfilled) and cross-referenced with the road data.
</details>

<br>
The cleaned data was converted from Excel files to .tcv files using Python. Then, the Excel files were uploaded to and viewed from the Java file. The results are below:
<br>
<br>


<p align="center">
  <img src="images/bangladesh_map_cleaned.png?raw=true" style="transform: scale(0.8);">
</p>
<p align="center">
  <em>Map of Bangladesh with cleaned roads and bridges data.</em>
</p>


### 2_Combine_Roads_and_Bridges.ipynb
Then, the roads and bridges data were combined to prepare the data for a simulation using NetworkX, an agent-based modeling package in Python. 