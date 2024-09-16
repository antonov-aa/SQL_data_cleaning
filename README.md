# SQL data cleaning

# Data 
US President Barack Obama's administration has published records of White House visitors during his time in office.
https://obamawhitehouse.archives.gov/briefing-room/disclosures/visitor-records
Here I will clean and prepare the dataset for solely 2016. It contains 970 504 records in 28 columns.
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
