import os.path as path
import json

project_default_config = {
  "Project_name": {
      "server": "",
      "database": "",
      "uid": "",
      "pwd": "",
      "auth_url": "<urlpart>/PineryLime/SecurityTokenService/identity/connect/token",
      "api_url": "<urlpart>/PineryLime/TestApiService/api",
      "admin_login": "admin",
      "admin_pass": "Password123",
      "redis_host": "",
      "redis_port": ""
  }
}

config_path = "D:\\borneo_config.json"
global_config = None
if not path.exists(config_path):
    print("Пытаюсь создать файл D:\\borneo_config.json (дефолтное хранилище конфигов)...")
    try:
        with open(config_path, "w") as f:
            f.write(json.dumps(project_default_config))
    except Exception as e:
        print(f"Ошибка при создании файла D:\\borneo_config.json: {str(e)}")
    else:
        print("D:\\borneo_config.json успешно создан, в первую очередь он будет использоваться "
              "как источник конфигов в утилитах.\n"
              "Заполние его конфигами для желаемых проектов по аналогии с имеющимся проектом \"Project_name\".\n"
              "Ненужные для ваших нужд параметры (например, порт и хост Reddis) можно опустить.\n"
              "Можно использовать \"trusted_connection\": \"yes\", вместо логина и пароля, "
              "если доступ в БД настроен соотв. образом")
else:
    print("D:\\borneo_config.json существует, в первую очередь он будет использоваться "
          "как источник конфигов в утилитах.")
    try:
        with open(config_path, "r") as f:
            global_config = json.loads(f.read())
    except ValueError:
        print(f"{config_path} contains invalid json")
    else:
        if len(global_config) == 1 and global_config.get('Project_name'):
            print(f"Заполните {config_path} конфигами реальных проектов")
            global_config = None
