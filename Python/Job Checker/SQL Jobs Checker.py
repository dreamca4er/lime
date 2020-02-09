import requests as r
import pyodbc
import json
import datetime
import sys
import os


def db_connect(connect_cfg):
    cnxn = pyodbc.connect(driver='{ODBC Driver 13 for SQL Server}', **connect_cfg)
    cnxn.autocommit = True
    return cnxn.cursor()


pathname = os.path.dirname(sys.argv[0])
script_path = os.path.abspath(pathname)
log_path = os.path.join(script_path, "log.txt")
config_path = os.path.join(script_path, 'connect_config.json')

with open(log_path, 'w') as f:
    f.write(str(datetime.datetime.now()) + " started")

with open(config_path, 'r') as f:
    config = json.load(f)

calm_potter = config['ok_icon']
mad_potter = config['bad_icon']
webhook_url = config['webhook_url']
username = 'SQL Server Agent Checker'

cursor = db_connect(config['srv-bi'])
tsql = 'select * from dbo.vw_AllTodayJobErrors'
result = []

with cursor.execute(tsql):
    for row in cursor.fetchall():
        result.append(f':warning: {row[0]}: Job *{row[1]}* failed on step *{row[2]}* at *{row[3]}*')

if len(result) == 0:
    text = ':heavy_check_mark: Jobs are fine'
    icon_url = calm_potter
else:
    text = '\n'.join(result).replace('\\', '/')
    icon_url = mad_potter

payload = dict(text=text, username=username, icon_url=icon_url)
response = r.post(webhook_url, data=json.dumps(payload), verify=True).text
with open(log_path, 'a') as f:
    f.write('\n' + str(datetime.datetime.now()) + " " + response)
