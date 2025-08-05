from django.http import HttpRequest, JsonResponse
from ida_app.models import UserCredentials

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

    def process_view(self, request: HttpRequest, view_func, view_args, view_kwargs):
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
                user_id = int(request.POST.get("user_id"))
        except:
            return JsonResponse({"error": "'user_id' field is required as an int"}, status = 400)

        token = request.headers.get("authorization")
        if not token:
            return JsonResponse({"error": "Authorization token is required"}, status = 400)
        if not token.startswith("Bearer "):
            return JsonResponse({"error": "Invalid authorization token format"}, status = 400)
        token = token[7:]

        try:
            user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
            if user.token != token:
                return JsonResponse({"error": "Invalid authorization token"}, status = 400)
            if roles and user.role not in roles:
                return JsonResponse({"error": "Insufficient permissions"}, status = 400)
        except:
            return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
        
        request.user = user
        return None