import json
import sys
import datetime
import xlsxwriter
import os
import borneo.db as db
import argparse

epilogue = """
###
1. Как работать с утилитой
Для работы утилите нужно два файла: query.sql и config.json. По умолчанию они расположены в папке со скриптом, их
расположение может быть указано опциями --query_loc и --config_loc
Запрос, указанный в *query.sql*, с параметрами-знаками вопроса, будет выполнен на проекте *project_name*, указанном
в *config.json*. Данные для коннекта будут взяты из *D:\\borneo-config.json*. 
Имя выходного файла по умолчанию *output.xlsx*, может быть изменено входным параметром -o/--output.
Для выгрузки файла без заголовка нужно запускать утилиту с опцией --no_header.
###
2. Конфигурация результата запроса с помощью файла *config.json*
Файл должен содержать валидный json. 
Допустимы следующие поля:
sheet_name - Имя листа в документе, Sheet1 по умолчанию
header_format - формат заголовка (кроме цвета, который настраивается индивидуально для колонки)
project_name - имя проекта из *D:\\borneo-config.json*
columns - массив json-документов вида:
    {"name": "val", "red": val, "green": val, "blue": val, "format": "val", "try_number_cast": "True"}
    name - имя поля, которое будет подставлено в заголовок
    red, green, blue - компоненты RGB цвета ячейки заголовка
    format - для дат и чисел можем указать формат ячейки
    try_number_cast - если поле может содержать как числа, так и строки, и нужно выводить числа как числа, а строки - как строки
    , то выставляем этот опциональный флаг
### 
3. Получить файл *config.json* в эталонном формате можно запустив утилиту с опцией --generate_config. 
Для его формирования нужен файл *config.json* с единственным полем: project_name

"""
pathname = os.path.dirname(sys.argv[0])
script_path = os.path.abspath(pathname)

parser = argparse.ArgumentParser(epilog=epilogue, description='Выгружаем результат запроса в xlsx'
                                 , formatter_class=argparse.RawDescriptionHelpFormatter)
parser.add_argument('--query_loc', default=script_path + '\query.sql'
                    , help='путь к запросу, по умолчанию query.sql')
parser.add_argument('--config_loc', default=script_path + '\config.json'
                    , help='путь к конфиг файлу, по умолчанию config.json')
parser.add_argument('query_parameters', metavar='N', nargs='*'
                    , help='query.sql ? параметры в порядке их появления в запросе')
parser.add_argument('-o', '--output', default='output.xlsx'
                    , help='имя выходного файла, по умолчанию output.xlsx')
parser.add_argument('--no_header', action="store_true"
                    , help='выгружаем в xlsx без заголовка')
parser.add_argument('--generate_config', action="store_true"
                    , help='режим для генерации файла config.json')

args = parser.parse_args()
report_path = args.output

try:
    with open(args.query_loc, 'r') as file:
        sql = file.read()
except FileNotFoundError:
    print(f'Не найден файл {args.query_loc}')
    input('Press Enter to exit...(ha-ha)')
    sys.exit()

bad_params = [x for x in sql.split() if x.startswith('?') and x != '?']
if bad_params:
    print(f'Параметрами в запросе могут служить только ? (вопросительные знаки)'
          f', однако {", ".join(bad_params)} были обнаружены')
    input('Press Enter to exit...(ha-ha)')
    sys.exit()

parameters_in_query = len([x for x in sql.split() if x == '?'])
input_parameters = len(args.query_parameters)
if parameters_in_query != input_parameters:
    print(f'В файле с запросом {parameters_in_query} параметров(а), но были предоставлены {input_parameters}')
    input('Press Enter to exit...(ha-ha)')
    sys.exit()

try:
    with open(args.config_loc, 'r', encoding='utf-8') as file:
        config = json.load(file)
except FileNotFoundError:
    print(f'Не найден конфиг-файл {args.config_loc}, он должен существовать и содержать хотя бы одно поле: project_name')
    input('Press Enter to exit...(ha-ha)')
    sys.exit()

sheet_name = config.get('sheet_name', 'Sheet1')
header_format_json = config.get('header_format')
project_name = config.get('project_name')

try:
    cursor = db.db_connect(project_name)
    columns = [column[0] for column in cursor.execute(sql, *args.query_parameters).description]
except:
    print(f'Поле project_name не указано в config.json, или значение project_name не было найдено в D:\\borneo_config'
          f', или не удалось подключиться к базе')
    input('Press Enter to exit...(ha-ha)')
    sys.exit()

if args.generate_config:
    default_config = {}
    default_config['project_name'] = project_name
    default_config['sheet_name'] ='Your sheet name'
    default_config['header'] = {"bold": "True", "font_name": "Arial", "font_size": 8, "text_h_align": 2
                                , "text_v_align": 1, "text_wrap": "True", "bottom": 1, "top": 1, "left": 1, "right": 1}
    default_config['columns'] = []
    default_config['columns'].append({"name": "DELETE ME FOR I AM HERE TO BE AN EXAMPLE"
                                     , "red": 255, "green": 182, "blue": 193
                                     , "format": "dd.MM.yyyy", "try_number_cast": "True"})
    for column in columns:
        default_config['columns'].append({"name": column})
    with open(script_path + '\generated_config.json', 'w') as file:
        file.write(json.dumps(default_config, indent=4))
    print("Сформирован файл generated_config.json")
    sys.exit()

header_columns = len(config['columns'])
query_columns = len(columns)
if len(columns) != len(config['columns']):
    print(f'В запросе query.sql {query_columns} полей(я), но были предоставлены {header_columns} полей(я) in config.json')
    input('Press Enter to exit...(ha-ha)')
    sys.exit()

print(datetime.datetime.now(), "Проверки завершены, формирую файл и добавляю заголовок")

# Cоздаем книгу с заданным именем и фиксированным объемом памяти для работы
# чтобы не было чрезмерного потребления ОЗУ
workbook = xlsxwriter.Workbook(report_path, {'constant_memory': True})
worksheet = workbook.add_worksheet(sheet_name)

cell_format = []

# Формат ячеек
for curr_column, column in enumerate(config['columns']):
    # Каждый формат должен быть иницииализирован единожды,
    # не может изменяться после его применения
    cell_format.append(workbook.add_format(header_format_json))
    # Выставляем форматирование для полей с датами
    column_format = column.get('format')
    if column_format:
        worksheet.set_column(curr_column, curr_column, None, workbook.add_format({'num_format': column_format}))

# Заголовок
if not args.no_header:
    for curr_column, column in enumerate(config['columns']):
        bg_color = '#'
        for color in ['red', 'green', 'blue']:
            if not column.get(color):
                bg_color = '#'
                break
            bg_color += format(column[color], 'x')
        # Присваиваем нужный цвет текущей ячейке
        if bg_color != '#':
            cell_format[curr_column].set_bg_color(bg_color)
        worksheet.write(0, curr_column, column['name'], cell_format[curr_column])

print(datetime.datetime.now(), "Начинаю получение и запись результатов запроса")

rows_shift = not args.no_header
with cursor.execute(sql, *args.query_parameters):
    for r_num, row in enumerate(cursor.fetchall(), rows_shift):
        for c_num, col in enumerate(row):
            if config['columns'][c_num].get('try_number_cast'):
                try:
                    worksheet.write_number(r_num, c_num, float(col))
                except:
                    worksheet.write(r_num, c_num, col)
            else:
                worksheet.write(r_num, c_num, col)

workbook.close()

print(datetime.datetime.now(), "Готово")
