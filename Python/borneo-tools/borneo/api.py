import requests
import ast
import getpass
import json
import datetime

cert = False


def get_token_v2(auth_url=None, login=None, password=None, config=None):

    def check_response(resp):
        if all(elem in resp for elem in ["access_token", 'token_type']):
            access_token = resp['access_token']
            token_type = resp['token_type']
            return {"Authorization": token_type + ' ' + access_token}
        else:
            raise RuntimeError(json.dumps(resp))
    config = config or {}
    _auth_url = auth_url or config.get('auth_url', None)
    _login = login or config.get('admin_login', None)
    _password = password or config.get('admin_pass', None)
    if None in [_auth_url, _login, _password]:
        raise RuntimeError('Login or password or auth url was not provided')
    possible_client_ids = ['AdminAPI', 'AdminApi']
    data = {
        "grant_type": "password"
        , "username": _login
        , "password": _password
        , "client_secret": "secretPassword"
        , "scope": "openid AdminApiScope offline_access"
    }
    print(f'Getting token for {_login} from {_auth_url}')
    for client_id in possible_client_ids:
        print(f'Trying client_id = {client_id}...')
        data['client_id'] = client_id
        response = ast.literal_eval(requests.post(_auth_url, data=data, verify=cert).content.decode())
        try:
            return check_response(response)
        except RuntimeError as re:
            dict_re = json.loads(str(re))
            err = dict_re.get('error', None)
            if err == 'invalid_client':
                continue
            else:
                raise re
    raise RuntimeError('Failed getting token attempts with all client_ids')


def generate_token_header(token):
    return {"Authorization": 'Bearer ' + token}


def get_token(auth_url, login, password):
    data = {
        "grant_type": "password"
        , "username": login
        , "password": password
        , "client_id": "AdminAPI"
        , "client_secret": "secretPassword"
        , "scope": "openid AdminApiScope offline_access"
    }
    headers = {}
    print(f'Getting token for {login} from {auth_url}')
    response = ast.literal_eval(requests.post(auth_url, data=data, headers=headers, verify=cert).content.decode())
    if "access_token" in response:
        return response["access_token"]
    else:
        raise RuntimeError("Error getting API token: ", response)


def test_method(token, api_url):
    method_path = api_url + "/Schedule/ReadSettings"
    headers = generate_token_header(token)
    data = {}
    return requests.post(method_path, data=data, headers=headers, verify=cert).ok


def add_products_to_new_collector(token, api_url):
    method_path = api_url + "/Collector/AddProductsToNewCollector"
    headers = generate_token_header(token)
    data = {"date": (datetime.datetime.now() + datetime.timedelta(hours=-4)).isoformat()
            , "messageId": "00000000-0000-0000-0000-000000000000"
            , "createdOn": "0001-01-01T00:00:00"}
    return requests.post(method_path, data=data, headers=headers, verify=cert)


def redistribution_overdue_products(token, api_url):
    method_path = api_url + "/Collector/RedistributionOverdueProducts"
    headers = generate_token_header(token)
    data = {"fullRedistribution": False
            , "date": (datetime.datetime.now() + datetime.timedelta(hours=-4)).isoformat()
            , "messageId": "00000000-0000-0000-0000-000000000000"
            , "createdOn": "0001-01-01T00:00:00"}
    return requests.post(method_path, data=data, headers=headers, verify=cert)


def equifax_request_for_clientlist(token, api_url, clients):
    method_path = api_url + "/CreditRobot/SengEquifaxRequestForClientList"
    headers = generate_token_header(token)
    data = clients
    return requests.post(method_path, data=data, headers=headers, verify=cert)


requests.urllib3.disable_warnings()

if __name__ == "__main__":

    default_login = "admin"
    l = str(input(f"Login ({default_login}):\t") or default_login)
    p = getpass.getpass()
    # auth_url = config['lime']['auth_url']
    auth_url = 'http://192.168.189.52:19081/PineryLime/SecurityTokenService/identity/connect/token'
    print(get_token_v2(auth_url, l, p))





