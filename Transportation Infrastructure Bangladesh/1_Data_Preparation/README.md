## Data Preparation

Raw data from [Bangladesh&#39;s Roads and Highways Department](https://www.rhd.gov.bd/RHDAtGlance/index.asp). 

***Data Cleaning: Roads***

Using the length of the strings in the road names data, the names of the roads were fixed (e.g., from N1 to N100). Thus, semantic inconsistencies were addressed so that the data types had the same characters, facilitating easy cross-referencing between datasets and fixing data precision inconsistencies. Then, null and missing values were removed. Typos were identified by checking if the discrepancy between entries of latitude and longitude values in each road is less than 0.01 of the location values of the LRP name before it. If so, then the location values were updated with the latitude or longitude data of the point in the road before. This removed the outliers.

***Data Cleaning: Bridges***

After removing duplicates and data entries with null longitude and latitude values, errors in longitude and latitude data values were checked. Some structures had latitude and longitude in the wrong column, so this was fixed. Then, using the road name and the LRP name that were fixed beforehand, the latitude and longitude data were cross-referenced with the cleaned roads dataset to make sure that the correct location was recorded; this was to help address any semantic inaccuracies in the bridge data. Finally, typos were checked and edited if necessary, by ensuring that the location data differences between structures of the same road are less than 0.03 degrees on either longitude or latitude. If not, they were updated with the location value of the bridge before (backfilling) it and cross-referenced with the road data.