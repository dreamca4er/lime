import sys
from os import path
import json
from PyQt5 import QtWidgets, QtGui
import PyQt5.QtCore as Qcore
from sys import exit

import design
import borneo
import borneo.db as db
import borneo.api as bapi

DB_LOGIN = None
DB_PASS = None
CONFIG_PATH = 'connect_config.json'
METHOD_LOG = 'current_execution_log.txt'
with open(METHOD_LOG, 'w') as mlog:
    mlog.write('')

if len(sys.argv) > 1:
    if sys.argv[1] == '--embedded-db-credentials':
        try:
            import creds
            DB_LOGIN = creds.writer_login
            DB_PASS = creds.writer_pass
        except:
            app = QtWidgets.QApplication(sys.argv)
            QtWidgets.QMessageBox.critical(QtWidgets.QMessageBox(), 'Error'
                                           , 'Утилита запущена в режиме встроенных кредов'
                                             ', однако при сборке они предоставлены не были.'
                                             ' Обратитесь к разработчику')
            exit()


class CollectionChanges(QtWidgets.QMainWindow, design.Ui_MainWindow):
    def __init__(self):
        super().__init__()
        self.setupUi(self)
        self.is_authorized = None
        self.cur_project = None
        self.auth_url = None
        self.api_url = None
        self.cursor = None
        self.admin_login = None
        self.admin_pass = None
        self.api_token = None
        self.users = None
        self.embedded_db_login = DB_LOGIN
        self.embedded_db_password = DB_PASS
        self.collector_groups = dict()
        self.connection_string = dict()
        self.token_btn.clicked.connect(lambda: self.get_token())
        self.redistribute_btn.clicked.connect(lambda: self.redistribution())
        self.new_portfolio_btn.clicked.connect(lambda: self.new_portfolio())
        reconnect_menu = self.menu.addMenu("Проекты")
        if borneo.global_config is not None:
            self.config = borneo.global_config
            self.show_info(f"Использую глобальный конфиг файл {borneo.config_path}")
        else:
            self.show_warning(f"Не удается использовать глобальный конфиг файл {borneo.config_path}"
                              f", использую {CONFIG_PATH}")
            try:
                with open(CONFIG_PATH, 'r') as f:
                    self.config = json.load(f)
            except FileNotFoundError:
                self.show_error(f"Не найден файл {CONFIG_PATH} и не удается использовать глобальный "
                                f"конфиг файл {borneo.config_path}, завершаю работу")
            except json.JSONDecodeError:
                self.show_error(f"{CONFIG_PATH} содержит невалидный JSON, завершаю работу")
        # Отображаем только те проекты, в которых заполнены все нужные конфиги
        options_list = ['server', 'database', 'auth_url', 'api_url', 'uid', 'pwd', 'admin_login', 'admin_pass']
        if len(sys.argv) > 1:
            if sys.argv[1] == '--embedded-db-credentials':
                print('Running with --embedded-db-credentials')
                options_list.remove('uid')
                options_list.remove('pwd')
        for pr, s in self.config.items():
            if all(elem in s for elem in options_list):
                reconnect_menu.addAction(pr, (lambda d=pr: self.project_connect(d)))
        self.exit_action = QtWidgets.QAction('Выход', self.menu)
        self.exit_action.triggered.connect(self.close)
        self.menu.addAction(self.exit_action)
        self.refresh_action = QtWidgets.QAction('Обновить списки', self.menu)
        self.refresh_action.setShortcut('F5')
        self.refresh_action.triggered.connect(lambda: self.refresh_users_lists())
        self.collectors_tree.customContextMenuRequested.connect(self.collectors_tree_menu)
        self.collectors_tree.expanded.connect(lambda: self.resize_collectors_columns())
        self.collectors_tree.collapsed.connect(lambda: self.resize_collectors_columns())
        self.all_users_tree.customContextMenuRequested.connect(self.all_users_menu)
        self.all_users_tree.expanded.connect(lambda: self.resize_all_users_columns())
        self.all_users_tree.collapsed.connect(lambda: self.resize_all_users_columns())
        self.search_user.textChanged.connect(self.generate_users_tree)
        self.search_collector.textChanged.connect(self.generate_collectors_list)
        self.centralwidget.hide()
        self.setFixedSize(self.size())

    @staticmethod
    def show_error(msg, exit_after=True):
        error_msg = QtWidgets.QMessageBox()
        error_msg.setIcon(QtWidgets.QMessageBox.Critical)
        error_msg.setWindowTitle('Error')
        error_msg.setText(msg)
        error_msg.setTextInteractionFlags(Qcore.Qt.TextSelectableByMouse)
        error_msg.exec()
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

    def check_for_errors(func):
        def error_checker(*args):
            fname = func.__name__
            try:
                with open(METHOD_LOG, 'a') as mlog:
                    mlog.write(fname + ' start\n')
                return func(*args)
            except db.RedistrRunningError as r:
                CollectionChanges.show_warning(str(r))
                return
            except Exception as r:
                CollectionChanges.show_error(str(r), False)
                return
            finally:
                with open(METHOD_LOG, 'a') as mlog:
                    mlog.write(fname + ' end\n')
        return error_checker

    def method_logger(func):
        def wrapper(*args):
            fname = func.__name__
            if fname != 'error_checker':
                with open(METHOD_LOG, 'a') as mlog:
                    mlog.write(fname + ' start\n')
            func(*args)
            if fname != 'error_checker':
                with open(METHOD_LOG, 'a') as mlog:
                    mlog.write(fname + ' end\n')
        return wrapper

    @method_logger
    def project_connect(self, proj):
        self.centralwidget.hide()
        try:
            self.cur_project = proj
            curr_conf = self.config[proj]
            for elem in ['server', 'database']:
                self.connection_string[elem] = curr_conf.get(elem)
            if len(sys.argv) > 1:
                if sys.argv[1] == '--embedded-db-credentials':
                    self.connection_string['uid'] = self.embedded_db_login
                    self.connection_string['pwd'] = self.embedded_db_password
            else:
                for elem in ['uid', 'pwd']:
                    self.connection_string[elem] = curr_conf.get(elem)
            self.admin_login = curr_conf['admin_login']
            self.admin_pass = curr_conf['admin_pass']
            self.auth_url = curr_conf['auth_url']
            self.api_url = curr_conf['api_url']
            if 'trusted_connection' in curr_conf:
                self.connection_string['trusted_connection'] = curr_conf['trusted_connection']
            elif 'trusted_connection' in self.connection_string:
                self.connection_string.pop('trusted_connection')
            print({k: v for k, v in self.connection_string.items() if k != 'pwd'})
            self.cursor = db.db_connect(self.connection_string)
            self.set_project_label_text()
            self.refresh_users_lists()
            for i, v in db.get_groups(self.cursor):
                self.collector_groups[i] = v
            self.get_token()
            self.centralwidget.show()
            self.menu.removeAction(self.exit_action)
            self.menu.addAction(self.refresh_action)
            self.menu.addAction(self.exit_action)
        except Exception as e:
            with open(METHOD_LOG, 'a') as mlog:
                mlog.write(str(e) + '\n')
            print(str(e))

    @check_for_errors
    def generate_users_tree(self):
        self.all_users_tree.clear()
        search_string = self.search_user.toPlainText().lower()
        user_types = {}
        user_statuses = {
            "False": QtWidgets.QTreeWidgetItem(["Отключен"])
            , "True": QtWidgets.QTreeWidgetItem(["Включен"])
        }
        for k, v in user_statuses.items():
            self.all_users_tree.addTopLevelItem(v)
        for user in self.users:
            user_type = user.CollectorId and 'Коллектора' or 'Другие сотрудники'
            user_enabled = user.Is_Enabled
            if search_string in user.Name.lower() + user.Username.lower():
                if user_enabled not in user_types:
                    user_types[user_enabled] = {}
                    user_types[user_enabled][user_type] = []
                elif user_type not in user_types[user_enabled]:
                    user_types[user_enabled][user_type] = []
                user_types[user_enabled][user_type].append((user.Name, user.Username))
        for status, types in user_types.items():
            for user_type, users in types.items():
                type_to_add = QtWidgets.QTreeWidgetItem([user_type])
                user_statuses[status].addChild(type_to_add)
                for user in users:
                    user_to_add = QtWidgets.QTreeWidgetItem([x for x in user])
                    type_to_add.addChild(user_to_add)
                    type_to_add.setExpanded(search_string != '')
                user_statuses[status].setExpanded(search_string != '')

    @check_for_errors
    def generate_collectors_list(self):
        self.collectors_tree.clear()
        search_string = self.search_collector.toPlainText().lower()
        groups_list = {}
        col_statuses = {
            "False": QtWidgets.QTreeWidgetItem(["Отключен"])
            , "True": QtWidgets.QTreeWidgetItem(["Включен"])
        }
        self.collectors_tree.addTopLevelItem(col_statuses['True'])
        self.collectors_tree.addTopLevelItem(col_statuses['False'])
        # Генерируем иерархию коллекторов
        for user in self.users:
            if user.CollectorId and search_string in user.Name.lower():
                if user.CollectorEnabled not in groups_list:
                    groups_list[user.CollectorEnabled] = {}
                    groups_list[user.CollectorEnabled][user.CollectorGroups] = []
                elif user.CollectorGroups not in groups_list[user.CollectorEnabled]:
                    groups_list[user.CollectorEnabled][user.CollectorGroups] = []
                groups_list[user.CollectorEnabled][user.CollectorGroups] \
                    .append((str(user.CollectorId), user.Name, str(user.OverdueCount)))
        # Заполняем дерево коллекторов
        for status in groups_list:
            for group in groups_list[status]:
                group_to_add = QtWidgets.QTreeWidgetItem([group])
                col_statuses[status].addChild(group_to_add)
                for userlist in groups_list[status][group]:
                    user_to_add = QtWidgets.QTreeWidgetItem([x for x in userlist])
                    group_to_add.addChild(user_to_add)
                    group_to_add.setExpanded(search_string != '')
                col_statuses[status].setExpanded(search_string != '')

    @check_for_errors
    def refresh_users_lists(self):
        self.users = db.get_all_users(self.cursor)
        for user in self.users:
            if 'client' in str(user.Roles or '').split(',') and user.Is_Enabled is None:
                self.show_error(f"Юзер {user.UserId} по имени {user.Name} получил Sts.users.Username = {user.Username} "
                                f"вместо своего номера телефона. Исправьте эту оплошность. "
                                f"Проверьте аналогичные ситуации.", True)
        self.generate_collectors_list()
        self.generate_users_tree()

    def resize_all_users_columns(self):
        for i in range(0, self.all_users_tree.columnCount()):
            self.all_users_tree.resizeColumnToContents(i)

    def resize_collectors_columns(self):
        for i in range(0, self.collectors_tree.columnCount()):
            self.collectors_tree.resizeColumnToContents(i)

    def all_users_menu(self, event):
        try:
            # Если никакой пункт меню не находится под курсором - меню не показываем, сбрасываем выделение
            if self.all_users_tree.indexAt(event).row() == -1:
                self.all_users_tree.clearSelection()
                return
            menu = QtWidgets.QMenu(self)
            change_user_status = QtWidgets.QAction(u"Вкл/Выкл пользователя", self)
            change_user_status.triggered.connect(lambda: self.change_user_status())
            menu.addAction(change_user_status)
            if self.all_users_tree.currentItem().parent().text(0) == 'Другие сотрудники':
                add_collector = QtWidgets.QAction(u"Добавить коллектора", self)
                add_collector.triggered.connect(lambda: self.add_collector())
                menu.addAction(add_collector)
            menu.exec_(QtGui.QCursor.pos())
        except Exception as e:
            print(str(e))

    def collectors_tree_menu(self, event):
        try:
            # Если никакой пункт меню не находится под курсором - меню не показываем, сбрасываем выделение
            if self.collectors_tree.indexAt(event).row() == -1:
                self.collectors_tree.clearSelection()
                return
            menu = QtWidgets.QMenu(self)
            change_col_status = QtWidgets.QAction(u"Вкл/Выкл коллектора", self)
            change_col_status.triggered.connect(lambda: self.change_collector_status())
            menu.addAction(change_col_status)
            remove_from_group = QtWidgets.QAction(u"Убрать из группы", self)
            remove_from_group.triggered.connect(lambda: self.remove_collector_from_group())
            menu.addAction(remove_from_group)
            groups = QtWidgets.QMenu("Добавить в группу", self)
            for group_id, group_name in self.collector_groups.items():
                groups.addAction(group_name, (lambda g=group_id: self.add_collector_to_group(g)))
            menu.addMenu(groups)
            menu.exec_(QtGui.QCursor.pos())
        except Exception as e:
            print(str(e))

    def get_current_collector(self):
        try:
            ret_dict = {}
            ret_dict['selected_id'] = int(self.collectors_tree.currentItem().text(0))
            ret_dict['selected_name'] = self.collectors_tree.currentItem().text(1)
            ret_dict['debtors'] = int(self.collectors_tree.currentItem().text(2) or 0)
            return ret_dict
        except:
            CollectionChanges.show_error('Выберите коллектора из списка', False)

    def get_current_user(self):
        ret_dict = {}
        ret_dict['selected_name'] = self.all_users_tree.currentItem().text(0)
        ret_dict['selected_username'] = self.all_users_tree.currentItem().text(1)
        return ret_dict

    @check_for_errors
    def change_collector_status(self):
        db.is_redistr_active(self.cursor)
        cur_col = self.get_current_collector()
        if CollectionChanges.ask_confirmation(f"Сменить статус коллектора {cur_col['selected_name']}?"):
            db.enable_or_disable_collector(self.cursor, cur_col['selected_id'])
            self.refresh_users_lists()

    @check_for_errors
    def remove_collector_from_group(self):
        db.is_redistr_active(self.cursor)
        cur_col = self.get_current_collector()
        if cur_col['debtors'] != 0:
            CollectionChanges.show_error(f"У коллектора {cur_col['selected_name']} непустой портфель, невозможно сменить группу", False)
        elif CollectionChanges.ask_confirmation(f"Исключить коллектора {cur_col['selected_name']} из группы?"):
            db.remove_from_group(self.cursor, cur_col['selected_id'])
            self.refresh_users_lists()

    @check_for_errors
    def add_collector_to_group(self, group_id):
        db.is_redistr_active(self.cursor)
        cur_col = self.get_current_collector()
        if cur_col['debtors'] != 0:
            CollectionChanges.show_error(f"У коллектора {cur_col['selected_name']} непустой портфель, невозможно сменить группу", False)
        elif CollectionChanges.ask_confirmation(f"Добавить коллектора {cur_col['selected_name']} в группу {self.collector_groups[group_id]}?"):
            db.add_to_group(self.cursor, cur_col['selected_id'], group_id)
            self.refresh_users_lists()

    @check_for_errors
    def add_collector(self):
        db.is_redistr_active(self.cursor)
        # Вычленяем логин юзера
        try:
            current_user = self.get_current_user()
            selected_username = current_user['selected_username']
            selected_name = current_user['selected_name']
        except Exception as e:
            CollectionChanges.show_error('Выберите сотрудника из списка', False)
            return
        if CollectionChanges.ask_confirmation(f"Добавить коллектора {selected_name}?"):
            db.add_collector(self.cursor, selected_username)
            self.refresh_users_lists()

    @check_for_errors
    def change_user_status(self):
        try:
            current_user = self.get_current_user()
            selected_username = current_user['selected_username']
            selected_name = current_user['selected_name']
        except Exception as e:
            CollectionChanges.show_error('Выберите сотрудника из списка', False)
            return
        if CollectionChanges.ask_confirmation(f"Изменить статус сотрудника {selected_name}?"):
            db.enable_or_disable_user(self.cursor, selected_username)
            self.refresh_users_lists()

    @check_for_errors
    def get_token(self):
        try:
            self.token_btn.setDisabled(True)
            if borneo.global_config:
                api_param = self.cur_project
            else:
                api_param = self.config[self.cur_project]
            self.api_token = bapi.get_token_v2(api_param)
            self.show_info("Авторизация прошла успешно")
        except Exception as e:
            self.show_error(str(e), True)
        finally:
            self.token_btn.setDisabled(False)

    @check_for_errors
    def redistribution(self):
        db.is_redistr_active(self.cursor)
        if CollectionChanges.ask_confirmation(f"Запустить распределение?"):
            res = bapi.redistribution_overdue_products(self.api_token, self.api_url)
            if res.ok:
                CollectionChanges.show_info('Запрос успешен')
            else:
                print(res.text)
                CollectionChanges.show_error('Ошибка', False)

    @check_for_errors
    def new_portfolio(self):
        db.is_redistr_active(self.cursor)
        if CollectionChanges.ask_confirmation(f"Заполнить портфели новых коллекторов?"):
            if bapi.add_products_to_new_collector(self.api_token, self.api_url).ok:
                CollectionChanges.show_info('Запрос успешен')
            else:
                CollectionChanges.show_error('Ошибка', False)

    def set_project_label_text(self):
        bg_color = {'lime': '#90EE90', 'mango': '#FFDAB9', 'konga': '#4682B4', 'test': '#68A5A7'}
        self.project_label.setText(self.cur_project)
        if self.cur_project in bg_color:
            self.project_label.setStyleSheet('background-color: ' + bg_color[self.cur_project])
        else:
            self.project_label.setStyleSheet('background-color: grey')


def main():
    app = QtWidgets.QApplication(sys.argv)
    window = CollectionChanges()
    window.show()
    app.exec_()

# "C:\Users\Goncharov.AA\PycharmProjects\LimeProject\venv\Scripts\pyuic5.exe" "C:\Users\Goncharov.AA\PycharmProjects\LimeProject\col.ui"  -o design.py


if __name__ == "__main__":
    main()
