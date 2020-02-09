import pyodbc
import json
import sys
import datetime
import xlsxwriter
import os


def get_cursor(connect_cfg):
    cnxn = pyodbc.connect(driver='{ODBC Driver 13 for SQL Server}', **connect_cfg)
    cnxn.autocommit = True
    return cnxn.cursor()


if len(sys.argv) < 3:
    print('Provide ReportId and output file path')
    sys.exit()
else:
    pathname = os.path.dirname(sys.argv[0])
    script_path = os.path.abspath(pathname)
    ReportId = sys.argv[1]
    report_path = sys.argv[2]

with open(script_path + '/config.json', 'r', encoding='utf-8') as file:
    config = json.load(file)

sheet_name = config['sheet_name']
header_format_json = config['header_format']

with open(script_path + '/query.sql', 'r') as file:
    sql = file.read().replace('?ReportId', ReportId)

print(datetime.datetime.now())

# Cоздаем книгу с заданным именем и фиксированным объемом памяти для работы
# чтобы не было чрезмерного потребления ОЗУ
workbook = xlsxwriter.Workbook(report_path, {'constant_memory': True})
worksheet = workbook.add_worksheet(sheet_name)

print(datetime.datetime.now())

cell_format = []
date_format = workbook.add_format({'num_format': 'dd.MM.yyyy'})

for column in config['columns']:
    # Каждый формат должен быть иницииализирован единожды,
    # не может изменяться после его применения
    cell_format.append(workbook.add_format(header_format_json))
    curr_column = column['index'] - 1
    # Выставляем форматирование для полей с датами
    if column.get('is_date'):
        worksheet.set_column(curr_column, curr_column, None, date_format)
    bg_color = '#'
    for color in ['red', 'green', 'blue']:
        bg_color += format(column[color], 'x')
    # Присваиваем нужный цвет текущей ячейке
    cell_format[curr_column].set_bg_color(bg_color)
    worksheet.write(0, curr_column, column['name'], cell_format[curr_column])

cursor = get_cursor(config['srv-bi'])

with cursor.execute(sql):
    r_num = 0
    while True:
        row = cursor.fetchone()
        if row:
            r_num += 1
            for c, col in enumerate(row):
                worksheet.write(r_num, c, col)
        else:
            break

workbook.close()

print(datetime.datetime.now())
