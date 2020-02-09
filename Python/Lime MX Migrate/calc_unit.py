import borneo.db as db
import borneo.api as ba
import requests as req


class RecalcIsAlreadyInProgress(RuntimeError):
    pass


class RecalcIsAlreadyCompleted(RuntimeError):
    pass


class RequestFailed(RuntimeError):
    pass


class CalcUnit:
    def __init__(self):
        self.cursor = None
        self.check_query = None
        self.recalc_date = None
        self.products_list = None
        self.method_path = None
        self.request_status_code = None
        self.requests_data = None
        self.recalc_was_completed = False
        self.head = {}

    def set_recalc_parameters(self, config=None, method_path=None, check_query=None, products_list=None
                              , recalc_date=None, operation_date=None, headers=None):
        self.cursor = db.db_connect(config)
        self.check_query = check_query
        self.recalc_date = recalc_date
        self.head = headers or {}
        self.products_list = products_list
        self.method_path = method_path
        self.request_status_code = None
        self.requests_data = {"recalcDate": recalc_date, "productIds": products_list, "operationDate": operation_date}
        self.recalc_was_completed = False

    def start_recalc(self):
        if self.recalc_was_completed:
            raise RecalcIsAlreadyCompleted()
        if len(self.products_in_progress()) > 0:
            raise RecalcIsAlreadyInProgress()
        try:
            result = req.post(self.method_path, json=self.requests_data, verify=ba.cert, timeout=30, headers=self.head)
            self.request_status_code = result.status_code
            if result.status_code == 200:
                return 1
            else:
                self.request_status_code = None
                raise RequestFailed(f'Code {result.status_code}, {result.text}')
        except req.Timeout:
            self.request_status_code = None
            raise RequestFailed(f'Request timeout')
        except req.ConnectionError:
            self.request_status_code = None
            raise RequestFailed(f'Request connection error')

    def products_in_progress(self):
        if not self.request_status_code:
            return []
        with self.cursor.execute(self.check_query):
            check_result = self.cursor.fetchall()
        if len(check_result) > 0:
            return [x[0] for x in check_result]
        elif self.request_status_code == 200:
            self.recalc_was_completed = True
            return []
        else:
            return []
