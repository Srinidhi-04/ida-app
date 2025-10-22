import datetime
from hashlib import sha256
import json
import asyncio
from django.http import HttpRequest, JsonResponse, QueryDict
from ida_app.models import UserCredentials, UserTokens

def requires_fields(body: QueryDict, fields: dict):
    for field in fields:
        value = body.get(field)
        if not value:
            return {"error": f"'{field}' field is required"}
        
        if fields[field] == "int":
            try:
                int(value)
            except:
                return {"error": f"'{field}' field is required as an int"}
        
        if fields[field] == "float":
            try:
                float(value)
            except:
                return {"error": f"'{field}' field is required as a float"}
        
        if fields[field] == "list":
            try:
                value = json.loads(value)
                if not isinstance(value, list):
                    raise Exception(f"'{field}' field is required as a {fields[field]}")
            except:
                if not isinstance(value, list):
                    return {"error": f"'{field}' field is required as a {fields[field]}"}
                
        if fields[field] == "dict":
            try:
                value = json.loads(value)
                if not isinstance(value, dict):
                    raise Exception(f"'{field}' field is required as a {fields[field]}")
            except:
                if not isinstance(value, dict):
                    return {"error": f"'{field}' field is required as a {fields[field]}"}

def auth_exempt(view):
    view.auth_exempt = True
    return view

def requires_roles(roles: list):
    def set_roles(view):
        view.roles = roles
        return view
    return set_roles

def request_type(type: str):
    def set_type(view):
        view.type = type
        return view
    return set_type

class AuthMiddleware:
    def __init__(self, get_response):
        self.get_response = get_response
    
    def __call__(self, request: HttpRequest):
        request.user = None
        return self.get_response(request)

    async def process_view(self, request: HttpRequest, view_func, view_args, view_kwargs):
        method = getattr(view_func, "type", "GET")
        if request.method != method:
            return JsonResponse({"error": f"This endpoint can only be accessed via {method}"}, status = 400)
        
        request.user = None
        roles = getattr(view_func, "roles", None)

        if getattr(view_func, "auth_exempt", False):
            return None

        try:
            if request.method == "GET":
                user_id = int(request.GET.get("user_id"))
            else:
                user_id = request.POST.get("user_id")
                if user_id:
                    user_id = int(user_id)
                else:
                    body: dict = await asyncio.to_thread(lambda: json.loads(request.body))
                    user_id = int(body.get("user_id"))
        except:
            return JsonResponse({"error": "'user_id' field is required as an int"}, status = 400)

        token = request.headers.get("authorization")
        if not token:
            return JsonResponse({"error": "Authorization token is required"}, status = 400)
        if not token.startswith("Bearer "):
            return JsonResponse({"error": "Invalid authorization token format"}, status = 400)
        token = token[7:]

        try:
            user: UserCredentials = await UserCredentials.objects.prefetch_related("user_tokens").aget(user_id = user_id)
            token_record: UserTokens = await user.user_tokens.aget(token = sha256(token.encode()).hexdigest(), type = "auth")

            if token_record.expires_at <= datetime.datetime.now(tz = datetime.timezone.utc):
                return JsonResponse({"error": "Invalid authorization token"}, status = 400)
            
            if roles and user.role not in roles:
                return JsonResponse({"error": "Insufficient permissions"}, status = 400)
            
        except UserCredentials.DoesNotExist:
            return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
        
        except UserTokens.DoesNotExist:
            return JsonResponse({"error": "Invalid authorization token"}, status = 400)
        
        request.user = user
        return None