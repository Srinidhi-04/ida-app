from django.http import HttpRequest, HttpResponse, JsonResponse
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

APP_VERSION = 15.4

@auth_exempt
async def index(request: HttpRequest):
    return HttpResponse("API is up and running")

@auth_exempt
@request_type("GET")
async def check_update(request: HttpRequest):
    try:
        check = requires_fields(request.GET, {"version": "float"})
        if check:
            return JsonResponse(check, status = 400)

        version = float(request.GET.get("version"))
        
        if version < int(APP_VERSION):
            return JsonResponse({"message": "Hard update"})
        
        if version < APP_VERSION:
            return JsonResponse({"message": "Soft update"})
        
        return JsonResponse({"message": "Updated"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def send_query(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"query": "str"})
        if check:
            return JsonResponse(check, status = 400)

        user: UserCredentials = request.user

        query = request.POST.get("query")

        await send_question(user.name, user.email, query)

        return JsonResponse({"message": "Query sent successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def refresh_token(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"token": "str"})
        if check:
            return JsonResponse(check, status = 400)

        user: UserCredentials = request.user

        token = request.POST.get("token")

        try:
            await user.user_tokens.aget(token = token, type = "fcm")
        except ObjectDoesNotExist:
            token_obj = UserTokens(user = user, token = token, type = "fcm")
            await token_obj.asave()

        return JsonResponse({"message": "FCM token refreshed successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def delete_token(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"token": "str"})
        if check:
            return JsonResponse(check, status = 400)

        user: UserCredentials = request.user

        token = request.POST.get("token")

        try:
            token_obj: UserTokens = await user.user_tokens.aget(token = token, type = "fcm")
            await token_obj.adelete()
        except ObjectDoesNotExist:
            raise Exception("FCM token does not exist")

        return JsonResponse({"message": "FCM token deleted successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)