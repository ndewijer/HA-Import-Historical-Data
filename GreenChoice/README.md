# Prepare greenchoice import data into Home-Assitant

Greenchoice has no API to call but an export can be made of the energy consumption and production that has been pulled directly from the smartmeter. 

This data, in CSV format can be used to prepare data for use in Home-Assistant.

The CSV itself contains all the data in a table, but we require it to be in seperate files.

This script breaks the CSV into 4 seperate CSV with unix timestamps instead of normal datetimes. 