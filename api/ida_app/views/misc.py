from django.http import HttpRequest, HttpResponse, JsonResponse
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

APP_VERSION = 13.1

@auth_exempt
def index(request: HttpRequest):
    return HttpResponse("API is up and running")

@auth_exempt
@request_type("GET")
def check_update(request: HttpRequest):    
    check = requires_fields(request.GET, {"version": "float"})
    if check:
        return JsonResponse(check, status = 400)

    version = float(request.GET.get("version"))
    
    if version < int(APP_VERSION):
        return JsonResponse({"message": "Hard update"})
    
    if version < APP_VERSION:
        return JsonResponse({"message": "Soft update"})
    
    return JsonResponse({"message": "Updated"})

@request_type("POST")
def send_query(request: HttpRequest):
    check = requires_fields(request.POST, {"query": "str"})
    if check:
        return JsonResponse(check, status = 400)

    user: UserCredentials = request.user

    query = request.POST.get("query")

    send_question(user.name, user.email, query)

    return JsonResponse({"message": "Query sent successfully"})