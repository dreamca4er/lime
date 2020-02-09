import borneo.db as db
import os
import time
import json

scripts_dir = 'scripts'
config_path = '../connect_config.json'

a = input('Run tons of scripts? (y/n): ')
while a != 'y':
    if a == 'n':
        exit()
    else:
        a = input('Print y or n: ')

with open(config_path) as f:
    config = json.loads(f.read())
    curs = db.db_connect(config['lime'])

for file in os.listdir(scripts_dir):
    time.sleep(1)
    with open('scripts/' + file) as scr:
        curs.execute(scr.read())
    print(file)
