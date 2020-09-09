import csv
import sys

reader = csv.reader(open("tmp/raw.csv", "rU"), delimiter=',')
writer = csv.writer(sys.stdout, delimiter='|')
writer.writerows(reader)