# SQL data cleaning

# Data 
US President Barack Obama's administration has published records of White House visitors during his time in office.
https://obamawhitehouse.archives.gov/briefing-room/disclosures/visitor-records
Here I will clean and prepare the dataset for solely 2016 (January - October). It contains 970 504 records in 28 columns.
Columns describtion is provided here: https://obamawhitehouse.archives.gov/files/disclosures/visitors/WhiteHouse-WAVES-Key-1209.txt

To summarize - this dataset contains information on White house visitors, visitees, time of visit, visit facility along with some other information throughout 2016.
This includes both tourist and business visits to White House.

# Tools
Data was be uploaded into Postgres database.
All the operations were performed using PostgreSQL language in DBeaver Community edition, version 24.2.0.

# Data cleaning and preparation plan
1) Visual inspection of data entries, check for consistency of data in the column and the corresponding data type.
2) Remove duplicating entries.
3) Unification of empty entries (NULLs).
4) Data types correction.
5) Data unification and standartisation.
6) Columns remove.
7) Final touch.

# Results

Original data is highly inconsistent, contains a lot of missing values and entry logics is unclear.

Total entries: 970 504 -> 968 954 due to removal of duplicated and faulty rows.

Total number of rows: 28 -> due to removal of row with single value and empty row.

All the missing value identified and replaced with NULL.

Logics behind data input is partially restored and explained.

All data columns are brought to correct type.

Data variability due to inconsistent data inputting is decreased without any losses:

   Unique caller names: 1230 -> 1224
   
   Unique meeting locations: 2 279 -> 2 046
   
   Unique visitees: 6 505 -> 5 885
   
   Posts of arrival and departures: 21 -> 20 
   
