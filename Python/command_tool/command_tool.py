import sys
import os
import json
from PyQt5 import QtWidgets, QtGui
from PyQt5.Qt import QApplication
from PyQt5.QtCore import Qt
from sys import exit
import design
import borneo.db as db

p_join = os.path.join
pathname = os.path.dirname(sys.argv[0])
script_path = os.path.abspath(pathname)
config_path = os.path.join(script_path, 'connect_config.json')
command_types_path = os.path.join(script_path, 'command_types.json')
command_template_path = os.path.join(script_path, 'command_template.sql')
existing_operations_path = os.path.join(script_path, 'existing_operations.sql')
save_changes_path = os.path.join(script_path, 'save_changes.sql')
modules_path = p_join('\\'.join(script_path.split('\\')[:-1]), 'modules')


class Messages:
    @staticmethod
    def show_error(msg, exit_after=True):
        QtWidgets.QMessageBox.critical(QtWidgets.QMessageBox(), 'Error', msg)
        exit_after and exit()

    @staticmethod
    def show_warning(msg):
        QtWidgets.QMessageBox.warning(QtWidgets.QMessageBox(), 'Warning', msg)

    @staticmethod
    def show_info(msg):
        QtWidgets.QMessageBox.information(QtWidgets.QMessageBox(), 'Message', msg, QtWidgets.QMessageBox.Ok)

    @staticmethod
    def ask_confirmation(msg):
        reply = QtWidgets.QMessageBox.question(QtWidgets.QMessageBox(), 'Message',
                                               msg, QtWidgets.QMessageBox.Yes, QtWidgets.QMessageBox.No)
        if reply == QtWidgets.QMessageBox.Yes:
            return True


class TableActions:
    @staticmethod
    def init_table(table, headers):
        table.setColumnCount(len(headers))
        table.setHorizontalHeaderLabels(headers)
        table.setRowCount(0)
        
    @staticmethod
    def resize_columns(table):
        for i in range(0, table.columnCount()):
            if table.horizontalHeaderItem(i).text() not in ['CommandType', 'OperationFullName']:
                table.resizeColumnToContents(i)
            if table.horizontalHeaderItem(i).text() == 'CommandType':
                table.setColumnWidth(i, 370)
            if table.horizontalHeaderItem(i).text() == 'OperationFullName':
                table.setColumnWidth(i, 5)

    @staticmethod
    def copy_from_table(args):
        table = args[0]
        clipboard = args[1]
        cells = []
        for ind in table.selectedIndexes():
            row = ind.row()
            column = ind.column()
            value = table.item(row, column).text()
            cell = dict(row=row, column=column, value=value)
            cells.append(cell)
        clipboard.setText(json.dumps(cells))

    @staticmethod
    def paste_into_table(args):
        table = args[0]
        clipboard = args[1]
        dst_init_row = table.currentRow()
        dst_init_col = table.currentColumn()
        if dst_init_row == -1:
            return
        try:
            clipboard_items = json.loads(clipboard.text())
            for cell in clipboard_items:
                if not all(elem in cell for elem in ('row', 'column', 'value')):
                    return
            scr_init_row = clipboard_items[0]['row']
            scr_init_col = clipboard_items[0]['column']
            for cell in clipboard_items:
                calc_row = dst_init_row + (cell['row'] - scr_init_row)
                calc_column = dst_init_col + (cell['column'] - scr_init_col)
                print(calc_row, calc_column)
                if table.item(calc_row, calc_column):
                    table.item(calc_row, calc_column).setText(cell['value'])
        except json.JSONDecodeError:
            return
        except Exception as e:
            Messages.show_info(f'{type(e), str(e)}')


class CommandTool(QtWidgets.QMainWindow, design.Ui_MainWindow):
    def __init__(self):
        super().__init__()
        self.setupUi(self)
        self.cur_project = None
        self.cursor = None
        self.dialog = None
        self.product_id = None
        self.product_type = None
        self.generated_commands = list()
        self.connection_string = dict()
        self.command_types = list()
        self.src_lay.setAlignment(Qt.AlignTop)
        self.dst_lay.setAlignment(Qt.AlignTop)
        self.gen_com_bth.clicked.connect(self.generate_commands)
        self.write_com_btn.clicked.connect(self.write_commands)
        self.add_com_btn.clicked.connect(self.select_commands_to_add)
        self.get_cur_com_btn.clicked.connect(self.show_existing_commands)
        self.save_cur_com_btn.clicked.connect(self.save_commands_changes)
        self.del_cur_com_btn.clicked.connect(self.delete_commands)
        self.productid_edit.textChanged.connect(self.refresh_tables)
        self.clipboard = QApplication.clipboard()
        self.gen_copy = QtWidgets.QShortcut(QtGui.QKeySequence("Ctrl+C"), self.gen_com_tbl
                                            , lambda a=(self.gen_com_tbl, self.clipboard): TableActions.copy_from_table(a))
        self.cur_copy = QtWidgets.QShortcut(QtGui.QKeySequence("Ctrl+C"), self.cur_com_tbl
                                            , lambda a=(self.cur_com_tbl, self.clipboard): TableActions.copy_from_table(a))
        self.gen_paste = QtWidgets.QShortcut(QtGui.QKeySequence("Ctrl+V"), self.gen_com_tbl
                                             , lambda a=(self.gen_com_tbl, self.clipboard): TableActions.paste_into_table(a))
        self.cur_paste = QtWidgets.QShortcut(QtGui.QKeySequence("Ctrl+V"), self.cur_com_tbl
                                             , lambda a=(self.cur_com_tbl, self.clipboard): TableActions.paste_into_table(a))
        self.gen_copy.setContext(Qt.WidgetShortcut)
        self.cur_copy.setContext(Qt.WidgetShortcut)
        self.gen_paste.setContext(Qt.WidgetShortcut)
        self.cur_paste.setContext(Qt.WidgetShortcut)
        reconnect_menu = self.menu.addMenu("Проекты")
        with open(config_path, 'r') as f:
            try:
                self.config = json.load(f)
            except:
                Messages.show_error("Invalid connect_config.json file")
        with open(command_types_path, 'r') as f:
            try:
                self.command_types = json.load(f)
            except:
                Messages.show_error("Invalid command_types.json file")
                return
        for pr, s in self.config.items():
            if all(elem in s for elem in ('server', 'database', 'uid', 'pwd')) or pr == 'test':
                reconnect_menu.addAction(pr, (lambda d=pr: self.project_connect(d)))
        self.exit_action = QtWidgets.QAction('Выход', self.menu)
        self.exit_action.triggered.connect(self.close)
        self.menu.addAction(self.exit_action)
        self.centralwidget.hide()

    def project_connect(self, proj):
        self.centralwidget.hide()
        try:
            self.cur_project = proj
            curr_conf = self.config[proj]
            for elem in ['server', 'database', 'uid', 'pwd']:
                self.connection_string[elem] = curr_conf.get(elem)
            if 'trusted_connection' in curr_conf:
                self.connection_string['trusted_connection'] = curr_conf['trusted_connection']
            elif 'trusted_connection' in self.connection_string:
                self.connection_string.pop('trusted_connection')
            print({k: v for k, v in self.connection_string.items() if k != 'pwd'})
            self.cursor = db.db_connect(self.connection_string)
            self.set_project_label_text()
            self.centralwidget.show()
            self.refresh_tables()
        except Exception as e:
            print(str(e))

    def set_project_label_text(self):
        bg_color = {'lime': '#90EE90', 'mango': '#FFDAB9', 'konga': '#4682B4', 'test': '#68A5A7'}
        self.project_label.setText(self.cur_project)
        if self.cur_project in bg_color:
            self.project_label.setStyleSheet('background-color: ' + bg_color[self.cur_project])
        else:
            self.project_label.setStyleSheet('background-color: grey')

    def add_commands_to_table(self, table, commands, add_checkboxes):
        initial_row = table.rowCount()
        for i, command in enumerate(commands, initial_row):
            row_position = table.rowCount()
            table.insertRow(row_position)
            start_column = 0
            if add_checkboxes:
                start_column = 1
                checkbox_item = QtWidgets.QTableWidgetItem()
                checkbox_item.setFlags(Qt.ItemIsUserCheckable | Qt.ItemIsEnabled)
                checkbox_item.setCheckState(Qt.Checked)
                table.setItem(i, 0, checkbox_item)
            for j, command_field in enumerate(command, start_column):
                field = command_field
                if table.horizontalHeaderItem(j).text() == 'CommandSnapshot':
                    field = json.loads(command_field)
                    if 'ProductId' in field:
                        field['ProductId'] = self.product_id
                    if 'ProductType' in field:
                        field['ProductType'] = self.product_type
                if table.horizontalHeaderItem(j).text() == 'CommandType':
                    for command_type in self.command_types:
                        if command_type['CommandType'] == field:
                            red = command_type.get('red' or 255)
                            green = command_type.get('green' or 255)
                            blue = command_type.get('blue' or 255)
                            color = QtGui.QColor(red, green, blue)
                table.setItem(i, j, QtWidgets.QTableWidgetItem(str(field or '')))
            for j, command_field in enumerate(command, start_column):
                table.item(i, j).setBackground(color)
        TableActions.resize_columns(table)
        self.showMaximized()

    def check_product_id(self):
        self.product_id = self.productid_edit.text()
        int(self.product_id)
        sql = f'select ProductType from prd.product where id = {self.product_id}'
        with self.cursor.execute(sql):
            row = self.cursor.fetchone()
            if not row:
                raise ValueError
            self.product_type = row[0]

    def generate_commands(self):
        self.gen_com_tbl.setRowCount(0)
        self.colors = []
        gen_sql_path = p_join(script_path, 'generate_commands.sql')
        try:
            with open(gen_sql_path, 'r') as f:
                generate_sql = f.read()
        except:
            Messages.show_warning(f"Не могу открыть {gen_sql_path}")
        try:
            self.check_product_id()
        except ValueError or TypeError:
            Messages.show_warning(f"Введите корректный Id продукта")
            return
        except Exception as e:
            print(type(e), str(e))
        prepared_sql = generate_sql.replace('@productid', self.product_id).replace('\\n', ' ')
        with self.cursor.execute(prepared_sql):
            self.generated_commands = self.cursor.fetchall()
        if len(self.generated_commands) == 0:
            return
        table_col_names = ['V'] + [column[0] for column in self.cursor.description]
        if self.gen_com_tbl.columnCount() == 0:
            TableActions.init_table(self.gen_com_tbl, table_col_names)
        self.add_commands_to_table(self.gen_com_tbl, self.generated_commands, True)

    def write_commands(self):
        inserted_count = 0
        for row in range(self.gen_com_tbl.rowCount()):
            insert_row = dict(ProductId=self.product_id)
            column_names = ['ProductId']
            if self.gen_com_tbl.item(row, 0).checkState() == 0:
                continue
            for column in range(1, self.gen_com_tbl.columnCount()):
                column_name = self.gen_com_tbl.horizontalHeaderItem(column).text()
                column_names.append(column_name)
                cell_value = self.gen_com_tbl.item(row, column).text().replace('\'', "\"")
                insert_row[column_name] = cell_value
                if column_name == 'CommandSnapshot':
                    for elem in ['OperationDate']:
                        try:
                            insert_row[elem] = json.loads(cell_value)[elem]
                            column_names.append(elem)
                        except KeyError:
                            Messages.show_warning(f"Отсутствует {elem} в CommandSnapshot")
                            return
                        except json.JSONDecodeError:
                            Messages.show_warning("Невалидный JSON в CommandSnapshot")
                            return
            insert_values = ','.join(("'" + str(v) + "'" for k, v in insert_row.items()))
            insert_columns = ','.join((v for v in column_names))
            try:
                self.cursor.execute(f'insert prd.operationlog({insert_columns}) values ({insert_values})')
                inserted_count += 1
            except Exception as e:
                Messages.show_error(str(e), False)
                return
        Messages.show_info(f"Добавлено команд: {inserted_count}")
        self.show_existing_commands()

    def select_commands_to_add(self):
        try:
            self.check_product_id()
        except ValueError or TypeError:
            Messages.show_warning(f"Введите корректный Id продукта")
            return
        self.dialog = QtWidgets.QDialog()
        vertical_layout = QtWidgets.QVBoxLayout()
        self.dialog.setLayout(vertical_layout)
        commands_table = QtWidgets.QTableWidget()
        commands_table.setColumnCount(2)
        commands_table.setHorizontalHeaderLabels(['Команда', 'Кол-во'])
        self.dialog.layout().addWidget(commands_table)
        for i, command_type in enumerate(self.command_types):
            self.command_types[i]['num'] = QtWidgets.QSpinBox()
            current_row = commands_table.rowCount()
            commands_table.insertRow(current_row)
            commands_table.setItem(current_row, 0, QtWidgets.QTableWidgetItem(command_type['name']))
            commands_table.setCellWidget(current_row, 1, self.command_types[i]['num'])
        buttonbox = QtWidgets.QDialogButtonBox()
        ok_button = QtWidgets.QDialogButtonBox.Ok
        cancel_button = QtWidgets.QDialogButtonBox.Cancel
        buttonbox.addButton(ok_button)
        buttonbox.addButton(cancel_button)
        buttonbox.rejected.connect(self.dialog.close)
        buttonbox.accepted.connect(self.add_commands)
        buttonbox.setCenterButtons(True)
        self.dialog.layout().addWidget(buttonbox)
        self.dialog.exec_()

    def add_commands(self):
        self.dialog.close()
        with open(command_template_path, 'r') as f:
            try:
                command_template_sql = f.read()
            except:
                Messages.show_error("Invalid command_template.sql file")
                return
        if sum(x['num'].value() for x in self.command_types) == 0:
            Messages.show_warning(f"Не выбрано ни одной команды")
            return
        try:
            for item in self.command_types:
                if item['num'].value() > 0:
                    command_sql = command_template_sql.replace('@CommandType', "'" + item['CommandType'] + "'")
                    with self.cursor.execute(command_sql):
                        template_commands = self.cursor.fetchall()
                    for i in range(item['num'].value()):
                        if self.gen_com_tbl.columnCount() == 0:
                            table_col_names = ['V'] + [column[0] for column in self.cursor.description]
                            TableActions.init_table(self.gen_com_tbl, table_col_names)
                        self.add_commands_to_table(self.gen_com_tbl, template_commands, True)
        except Exception as e:
            print('add_commands', type(e), str(e))

    def show_existing_commands(self):
        all_command_types = ','.join(("'" + elem['CommandType'] + "'" for elem in self.command_types))
        self.cur_com_tbl.setRowCount(0)
        with open(existing_operations_path, 'r') as f:
            try:
                existing_operations_sql = f.read()
            except:
                Messages.show_error("Invalid existing_operations.sql file")
                return
        try:
            self.check_product_id()
        except ValueError or TypeError:
            Messages.show_warning(f"Введите корректный Id продукта")
            return
        except Exception as e:
            Messages.show_warning(f"here {type(e), str(e)}")
        try:
            existing_operations_sql = existing_operations_sql.replace('@CommandTypes', all_command_types)
            existing_operations_sql = existing_operations_sql.replace('@ProductId', self.product_id)
            with self.cursor.execute(existing_operations_sql):
                existing_operations = self.cursor.fetchall()
            if len(existing_operations) == 0:
                return
            table_col_names = [column[0] for column in self.cursor.description]
            if self.cur_com_tbl.columnCount() == 0:
                TableActions.init_table(self.cur_com_tbl, table_col_names)
            self.add_commands_to_table(self.cur_com_tbl, existing_operations, False)
        except Exception as e:
            print(type(e), str(e))

    def save_commands_changes(self):
        if self.cur_com_tbl.rowCount() == 0:
            return
        with open(save_changes_path, 'r') as f:
            try:
                save_changes_sql = f.read()
            except:
                Messages.show_error("Invalid save_changes.sql file")
                return
        for row in range(self.cur_com_tbl.rowCount()):
            insert_row = dict(ProductId=self.product_id)
            column_names = ['ProductId']
            for column in range(0, self.cur_com_tbl.columnCount()):
                column_name = self.cur_com_tbl.horizontalHeaderItem(column).text()
                column_names.append(column_name)
                cell_value = self.cur_com_tbl.item(row, column).text().replace('\'', "\"")
                insert_row[column_name] = cell_value
                if column_name == 'CommandSnapshot':
                    for elem in ['OperationDate']:
                        try:
                            insert_row[elem] = json.loads(cell_value)[elem]
                            column_names.append(elem)
                        except KeyError:
                            Messages.show_warning(f"Отсутствует {elem} в CommandSnapshot")
                            return
                        except json.JSONDecodeError:
                            Messages.show_warning("Невалидный JSON в CommandSnapshot")
                            return
            insert_values = ','.join(("'" + str(v) + "'" for k, v in insert_row.items()))
            insert_columns = ','.join((v for v in column_names))
            column_links = ','.join((col + ' = src.' + col for col in column_names if col != 'id'))
            try:
                curr_sql = save_changes_sql.replace('@InsertValues', insert_values)\
                    .replace('@InsertColumns', insert_columns)\
                    .replace('@Fields', column_links)
                self.cursor.execute(curr_sql)
            except Exception as e:
                Messages.show_error(str(e), False)
                return
        self.show_existing_commands()

    def refresh_tables(self):
        TableActions.init_table(self.gen_com_tbl, [])
        TableActions.init_table(self.cur_com_tbl, [])

    def delete_commands(self):
        if self.cur_com_tbl.currentRow() > 0:
            if Messages.ask_confirmation(f"Удалить выбранные команды?"):
                for ind in self.cur_com_tbl.selectedIndexes():
                    row = ind.row()
                    operation_id = int(self.cur_com_tbl.item(row, 0).text())
                    self.cursor.execute(f'delete from prd.OperationLog where id = {operation_id}')
                self.show_existing_commands()


def main():
    app = QtWidgets.QApplication(sys.argv)
    window = CommandTool()
    window.show()
    app.exec_()


if __name__ == "__main__":
    main()
