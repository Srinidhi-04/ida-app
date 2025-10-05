import uuid
import datetime
import random as rd
from hashlib import sha256
from django.http import HttpRequest, JsonResponse
from django.contrib.auth import authenticate
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

@auth_exempt
@request_type("POST")
def signup(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "name": "str", "password": "str"})
    if check:
        return JsonResponse(check, status = 400)

    email = request.POST.get("email")
    name = request.POST.get("name")
    password = request.POST.get("password")
    mailing = request.POST.get("mailing") == "yes"

    try:
        user: UserCredentials = UserCredentials.objects.create_user(email = email, name = name, password = password, avatar = rd.randint(1, 10), mailing = mailing)
    except Exception:
        return JsonResponse({"error": "A user with that email already exists"}, status = 400)

    send_verification_code(user.name, user.signup_code, user.email)
    if mailing:
        send_subscriber(user.name, user.email, mailing)

    return JsonResponse({"message": "User successfully signed up", "user_id": user.user_id, "email": user.email})

@auth_exempt
@request_type("POST")
def verify_code(request: HttpRequest):
    check = requires_fields(request.POST, {"user_id": "int", "code": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user_id = int(request.POST.get("user_id"))
    code = int(request.POST.get("code"))

    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)

    if user.signup_code != code:
        return JsonResponse({"error": "The code is incorrect"}, status = 400)
    
    user.signup_code = None

    uid = uuid.uuid4().hex
    token = UserTokens(user = user, token = sha256(uid.encode()).hexdigest(), expires_at = (datetime.datetime.now(tz = datetime.timezone.utc) + datetime.timedelta(days = 30)))
    token.save()

    user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
    user.save()

    settings = UserSettings(user = user, announcements = True, updates = True, merch = True, status = True, reminders = "2 hours before")
    settings.save()

    return JsonResponse({"message": "Code successfully verified", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "token": uid})

@auth_exempt
@request_type("POST")
def send_code(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str"})
    if check:
        return JsonResponse(check, status = 400)

    email = request.POST.get("email")
    forgot = request.POST.get("forgot") == "yes"
    
    try:
        user: UserCredentials = UserCredentials.objects.get(email = email)
    except:
        return JsonResponse({"error": "A user with that email does not exist"}, status = 400)

    while True:
        code = rd.randint(100000, 999999)
        try:
            UserCredentials.objects.get(signup_code = code)
        except:
            break
    
    if not forgot:
        user.signup_code = code
    else:
        user.forgot_code = code

    user.save()

    send_verification_code(user.name, code, user.email)

    return JsonResponse({"message": "Code successfully resent", "user_id": user.user_id, "email": user.email})

@auth_exempt
@request_type("POST")
def change_password(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "password": "str", "code": "int"})
    if check:
        return JsonResponse(check, status = 400)

    email = request.POST.get("email")
    password = request.POST.get("password")
    code = int(request.POST.get("code"))

    try:
        user: UserCredentials = UserCredentials.objects.get(email = email)
    except:
        return JsonResponse({"error": "A user with that email does not exist"}, status = 400)
    
    if user.forgot_code != code:
        return JsonResponse({"error": "The code is incorrect"}, status = 400)

    user.forgot_code = None
    user.set_password(password)

    user.user_tokens.update(expires_at = datetime.datetime.now(tz = datetime.timezone.utc))

    uid = uuid.uuid4().hex
    token = UserTokens(user = user, token = sha256(uid.encode()).hexdigest(), expires_at = (datetime.datetime.now(tz = datetime.timezone.utc) + datetime.timedelta(days = 30)))
    token.save()

    user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
    user.save()

    settings: UserSettings = user.user_settings

    return JsonResponse({"message": "Password successfully reset", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "token": uid})

@auth_exempt
@request_type("POST")
def login(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "password": "str"})
    if check:
        return JsonResponse(check, status = 400)

    email = request.POST.get("email")
    password = request.POST.get("password")

    user: UserCredentials = authenticate(request, email = email, password = password)

    if user and user.signup_code:
        while True:
            code = rd.randint(100000, 999999)
            try:
                UserCredentials.objects.get(signup_code = code)
            except:
                break
        
        user.signup_code = code
        user.save()

        send_verification_code(user.name, user.signup_code, user.email)

        return JsonResponse({"message": "Code successfully resent", "user_id": user.user_id, "email": user.email})

    if user:
        uid = uuid.uuid4().hex
        token = UserTokens(user = user, token = sha256(uid.encode()).hexdigest(), expires_at = (datetime.datetime.now(tz = datetime.timezone.utc) + datetime.timedelta(days = 30)))
        token.save()

        user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
        user.save()

        settings: UserSettings = user.user_settings

        return JsonResponse({"message": "User successfully logged in", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "token": uid})
    
    return JsonResponse({"error": "Email or password is incorrect"}, status = 400)

@request_type("GET")
def get_permissions(request: HttpRequest):
    check = requires_fields(request.GET, {"category": "str"})
    if check:
        return JsonResponse(check, status = 400)

    user: UserCredentials = request.user

    category = request.GET.get("category")

    if category == "announcements":
        roles = ["admin", "comms"]
    elif category == "events":
        roles = ["admin", "events"]
    elif category == "shop":
        roles = ["admin", "merch"]
    elif category == "roles":
        roles = ["admin"]

    return JsonResponse({"data": {"roles": roles, "access": user.role in roles, "role": user.role}})