import pyodbc
import json
from borneo import config_path, global_config


class RedistrRunningError(RuntimeError):
    pass


def is_redistr_active(curs):
    tsql = "select Value from cache.state where serviceuuid = 'col'"
    if curs.execute(tsql).fetchone()[0] == 1:
        raise RedistrRunningError("Redistribution is running")


def get_all_users(curs):
    print('Getting users')
    tsql = """with op as 
            (
                select 
                    CollectorId 
                    , count(*) as OverdueCount
                from Collector.OverdueProduct op
                where op.IsDone = 0
                group by CollectorId
            )
                       
            select
                a.id as UserId
                , a.Username
                , a.Name
                , a.Roles
                , a.Is_Enabled
                , a.CollectorId
                , a.CollectorEnabled
                , isnull(a.CollectorGroups, N'Не в группе') as CollectorGroups
                , isnull(op.OverdueCount, 0) as OverdueCount
            from sts.vw_admins a
            left join op on op.CollectorId = a.CollectorId"""
    with curs.execute(tsql):
        return curs.fetchall()


def get_groups(curs):
    print('Getting groups')
    tsql = 'select id as GroupId, Name as GroupName from Collector."Group"'
    with curs.execute(tsql):
        return curs.fetchall()


def enable_or_disable_collector(curs, collector_id):
    tsql = 'update Collector.Collector set IsDisabled = ~IsDisabled where id = ?'
    return curs.execute(tsql, collector_id).rowcount


def enable_or_disable_user(curs, username):
    tsql = """
            update uc
            set uc.ClaimValue = iif(uc.ClaimValue = 'True', 'False', 'True')
            from sts.users u
            inner join sts.UserClaims uc on uc.UserId = u.Id
                and uc.ClaimType = 'Is_Enabled'
            where u.UserName = '""" + username + "'"
    res = curs.execute(tsql).rowcount
    curs.execute("delete from cache.state where [key] = 'admins_with_claims_key'")
    return res


def add_collector(curs, username):
    tsql = """
            insert collector.Collector(Name, UserId, IsDisabled, CreatedOn, CreatedBy)
            select Name, id, 0, getdate(), 0x44
            from sts.vw_admins a
            where Username = ?
             and not exists
            (
                select 1 from Collector.Collector c
                where c.UserId = a.id
            )
            """
    return curs.execute(tsql, username).rowcount


def remove_from_group(curs, collector_id):
    tsql = 'delete cg from collector.CollectorGroup cg where CollectorId = ?'
    return curs.execute(tsql, collector_id).rowcount


def add_to_group(curs, collector_id, group_id):
    tsql = """
            merge Collector.CollectorGroup as target
            using (select ? as CollectorId, ? as GroupId) as source 
            on (target.CollectorId = source.CollectorId)
            when matched then
            update set Groupid = source.GroupId
            when not matched then
            insert (GroupId, CollectorId, CreatedOn, CreatedBy)
            values (source.GroupId, source.CollectorId, getdate(), 0x44)
            ;
            """
    return curs.execute(tsql, collector_id, group_id).rowcount


def db_connect(connect_cfg):
    """
    Функция db_connect работает по двум схемам:
    1. принимает на вход json-набор параметров (из локального файла connect_config.json, старая схема)
    2. принимает на вход имя проекта из глобального конфиг-файла borneo_config.json
    """
    project_config = None
    if type(connect_cfg) is str and global_config:
        try:
            project_config = global_config[connect_cfg]
        except KeyError:
            print(f'There is no project with a name "{connect_cfg}" in {config_path}.\n')
            try:
                json.loads(connect_cfg)
            except ValueError:
                raise ValueError(f'{connect_cfg} is not a project name nor a valid json')
    elif type(connect_cfg) is dict:
        project_config = connect_cfg
    else:
        raise TypeError('db_connect function accepts only str and dict as parameter type')
    try:
        cnxn = pyodbc.connect(driver='{SQL Server Native Client 11.0}', **project_config)
    except:
        cnxn = pyodbc.connect(driver='{ODBC Driver 13 for SQL Server}', **project_config)
    cnxn.autocommit = True
    return cnxn.cursor()


if __name__ == "__main__":
    if not global_config:
        with open('connect_config.json', 'r') as f:
            config = json.load(f)
    else:
        config = global_config
    project = "test"
    cursor = db_connect(project)
    try:
        print('result', enable_or_disable_collector(cursor, 10000))
    except RuntimeError as e:
        print(e)
