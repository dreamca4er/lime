# -*- coding: utf-8 -*-
import borneo.db as db
import borneo.api as ba
import json
import datetime as dt
import sys
import os
import time
import logging
import redis
from dateutil.relativedelta import relativedelta
from calc_unit import CalcUnit, RequestFailed
import requests

cert = False


def check_calc_statuses(curs, products_list):
    tsql = f'select id from prd.Product where id in {products_list} and CalcStatus = 2'
    with curs.execute(tsql):
        return [x[0] for x in curs.fetchall()]


def get_products(curs, tsql):
    with curs.execute(tsql):
        return curs.fetchall()


def check_cache_db(curs):
    tsql = "select Value from cache.State where [Key] = 'Recalculation'"
    with curs.execute(tsql):
        return int(curs.fetchone()[0]) or 0


def check_cache_redis(redis_path):
    return len(redis_path.keys(pattern='Lime#Prd#Recalc_*'))


my_format = '%Y-%m-%d %H:%M:%S'

pathname = os.path.dirname(sys.argv[0])
script_path = os.path.abspath(pathname)
check_script_path = os.path.join(script_path, 'check_script.sql')
log_path = os.path.join(script_path, 'execution_log.txt')
config_path = os.path.join(script_path, 'connect_config.json')

with open(config_path, 'r') as f:
    all_configs = json.loads(f.read())
    config = all_configs['konga']

with open(check_script_path, 'r') as s:
    query = s.read()

webhook_url = 'https://hooks.slack.com/services/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'
icon = config.get('recalc_icon', None)
slack_username = 'Recalc Checker'
payload = dict(username=slack_username, icon_url=icon)

""" Входные параметры """
pack_size = '200'
workers_num = '1'
calc_iters = 50
worker_timeout = 24 * 60 * 60  # После этого числа секунд считаем, что пересчет завис и заканчиваем с воркером
time_diff = config.get('time_diff', -4)

# operation_date = (dt.datetime.now() + dt.timedelta(hours=time_diff)).isoformat()
operation_date = (dt.datetime.now() + relativedelta(months=-8)).isoformat()

cursor = db.db_connect(config)
method_path = config['api_url'] + '/Product/RecalculateProductsById'
l = config['admin_login']
p = config['admin_pass']
headers = {}

logging.basicConfig(filename=log_path, filemode='w', format='%(asctime)s %(message)s', datefmt=my_format)
logger = logging.getLogger('RecalcLogger')
logger.setLevel(logging.INFO)
stdout_handler = logging.StreamHandler(sys.stdout)
logger.addHandler(stdout_handler)

check_cache = None
redis_cache = None
cache_pointer = None

if all(elem in config for elem in ['redis_host', 'redis_port']):
    redis_cache = redis.StrictRedis(host=config['redis_host'], port=config['redis_port'], db=0)
    try:
        redis_cache.ping()
        logger.info(f'Redis Cache connection to {config["redis_host"]}:{config["redis_port"]} succeded')
        check_cache = check_cache_redis
        cache_pointer = redis_cache
    except:
        logger.info('Redis Cache connection failed')
        redis_cache = None
else:
    check_cache = check_cache_db
    cache_pointer = cursor


a = input('Initiate calculation? (y/n): ')
while a != 'y':
    if a == 'n':
        exit()
    else:
        a = input('Print y or n: ')

calculated_products = []
workers = []
total_duration = 0

for i in range(0, int(workers_num)):
    workers.append(CalcUnit())

logger.info(f'Running script for {calc_iters} iteration(s)')

for calc_iter in range(0, calc_iters):
    cursor = db.db_connect(config)
    check_result = [None]
    calc_tasks = {}
    start_time = time.time()
    if calc_iter % 3 == 0:
        # чистим "кэш" посчитанных продуктов каждые 3 итерации, должно хватать на возможные таймауты
        calculated_products = []
    if calc_iter % 10 == 0:
        # Перезапрашиваем токен
        try:
            headers = ba.get_token_v2(config=config)
        except RuntimeError:
            print('Error getting token')
            headers = {}
    worker_duration = [0] * int(workers_num)
    calc_list = ('p.id not in (' + ','.join(str(x[0]) for x in calculated_products) + ')').replace('p.id not in ()', '0=0')
    get_query = query.replace('@PackSize', pack_size).replace('@CheckSuspended', '1').replace('@Workers', workers_num) \
        .replace('@CurrentDate', f"'{operation_date}'").replace('0=0', calc_list)

    logger.info(f'Iteration {calc_iter + 1}')
    logger.info(f'Getting {workers_num} product pack(s) size {pack_size}')
    initial_products = get_products(cursor, get_query)
    already_in_calc = [x[0] for x in initial_products if x in calculated_products]
    if len(already_in_calc) > 0:
        logger.info(f'{already_in_calc} were already in recalc')
    initial_products = [x for x in initial_products if x not in calculated_products]
    cursor.execute("exec stage.dbo.sp_spi '" + str([x[0] for x in initial_products]) + "'")
    calculated_products += initial_products
    if len(initial_products) == 0:
        logger.info(f'Nothing to calculate, exiting')
        total_duration += int(time.time() - start_time)
        break

    for product in initial_products:
        product_id = product[0]
        recalc_date = product[1].strftime(my_format)
        if recalc_date in calc_tasks:
            calc_tasks[recalc_date].append(product_id)
        else:
            calc_tasks[recalc_date] = [product_id]

    logger.info(f'Setting {workers_num} worker(s) recalc parameters')

    for i in range(0, int(workers_num)):
        if len(calc_tasks) > 0:
            recalc_date, products = calc_tasks.popitem()
            product_list = '(' + ','.join(str(x) for x in products) + ')'
            check_query = query.replace('@PackSize', pack_size).replace('@CurrentDate', f"'{operation_date}'") \
                .replace('1=1', 'p.id in ' + product_list).replace('@CheckSuspended', '0').replace('@Workers', '1')

            workers[i].set_recalc_parameters(config=config, method_path=method_path, check_query=check_query
                                             , products_list=products, recalc_date=recalc_date, headers=headers
                                             , operation_date=operation_date)

    logger.info(f'Initiation {workers_num} worker(s)')

    for worker in workers:
        request_attempts = 3
        while request_attempts > 0:
            products = worker.products_list
            print(products, end=' ')
            calc_start_message = f'Sending request for recalcDate {worker.recalc_date}, {len(products)} product(s)'
            logger.info(calc_start_message)
            payload['text'] = calc_start_message
            requests.post(webhook_url, data=json.dumps(payload), verify=False)
            try:
                request_attempts -= 1
                worker.start_recalc()
                logger.info(f'{dt.datetime.now().strftime(my_format)} {worker.recalc_date} request sent')
                time.sleep(5)
                payload['text'] = 'Request sent'
                requests.post(webhook_url, data=json.dumps(payload), verify=False)
                break
            except RequestFailed as e:
                print(str(e))
                print(f'Request failed, {request_attempts} attempt(s) left', )
                payload['text'] = 'Request failed'
                requests.post(webhook_url, data=json.dumps(payload), verify=False)
                continue

    if not redis_cache:
        logger.info('Redis Cache connect config was not provided, using db table cache.state')

    while len(check_result) > 0:
        check_result = []
        time.sleep(5)
        if len([x for x in worker_duration if x < worker_timeout]) == 0:
            logger.info('All workers had a timeout, starting next iter')
            break
        for i, worker in enumerate(workers):
            products_in_calculation = worker.products_in_progress()
            top3_in_calc = ','.join([str(x) for x in products_in_calculation[:3]]) + '..'
            check_result += products_in_calculation
            if products_in_calculation:
                elapsed_time = int(time.time() - start_time)
                worker_duration[i] = elapsed_time
                formated_duration = time.strftime("%H:%M:%S", time.gmtime(elapsed_time))
                print(f'{formated_duration} {worker.recalc_date}: {len(products_in_calculation)} '
                      f'in calculation({top3_in_calc})')
        recalc_state = check_cache(cache_pointer)
        if recalc_state == 0:
            break

    product_list = '(' + ','.join(str(x[0]) for x in initial_products) + ')'
    problem_products = check_calc_statuses(cursor, product_list)
    if len(problem_products) > 0:
        logger.info(f'CalcStatus 2: {problem_products}')
    elapsed_time = int(time.time() - start_time)
    formated_duration = time.strftime("%H:%M:%S", time.gmtime(elapsed_time))
    total_duration += elapsed_time
    calc_finish_message = f'{len(initial_products)} Product(s), {formated_duration} calc time'
    cursor.execute("exec stage.dbo.sp_spi")
    logger.info(calc_finish_message)
    payload['text'] = calc_finish_message
    requests.post(webhook_url, data=json.dumps(payload), verify=False)

formated_dur = '{:02d}:{:02d}:{:02d}'.format(total_duration // 3600, (total_duration % 3600 // 60), total_duration % 60)
logger.info(f'Recalc finished, total duration {formated_dur}')
