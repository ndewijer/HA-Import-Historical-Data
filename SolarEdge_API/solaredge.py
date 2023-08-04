import json
import datetime
import csv
import os
import sys

file_path = os.path.dirname(os.path.abspath(sys.argv[0]))

json_file = file_path+"/solaredge.json"
csv_file = file_path+"/energy_solar_st.csv"

if __name__ == '__main__':
    file = json.load(open(json_file))

    writer = csv.writer(open(csv_file, 'w'), delimiter=',')

    counter = 0

    for row in file['energy']['values']:

        date_format = datetime.datetime.strptime(row['date'], "%Y-%m-%d %H:%M:%S")
        unix_time = datetime.datetime.timestamp(date_format)
        if row['value'] == None:
            counter = counter + 0
        else:
            counter = counter + (row['value'] / 1000)
        writer.writerow([unix_time, counter])


