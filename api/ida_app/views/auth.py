import uuid
import datetime
import random as rd
from hashlib import sha256
from asgiref.sync import sync_to_async
from django.http import HttpRequest, JsonResponse
from django.contrib.auth import authenticate
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

@auth_exempt
@request_type("POST")
async def signup(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "name": "str", "password": "str"})
    if check:
        return JsonResponse(check, status = 400)

    email = request.POST.get("email")
    name = request.POST.get("name")
    password = request.POST.get("password")
    mailing = request.POST.get("mailing") == "yes"

    try:
        user: UserCredentials = await UserCredentials.objects.create_user(email = email, name = name, password = password, avatar = rd.randint(1, 10), mailing = mailing)
    except Exception:
        return JsonResponse({"error": "A user with that email already exists"}, status = 400)

    await send_verification_code(user.name, user.signup_code, user.email)
    if mailing:
        await send_subscriber(user.name, user.email, mailing)

    return JsonResponse({"message": "User successfully signed up", "user_id": user.user_id, "email": user.email})

@auth_exempt
@request_type("POST")
async def verify_code(request: HttpRequest):
    check = requires_fields(request.POST, {"user_id": "int", "code": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user_id = int(request.POST.get("user_id"))
    code = int(request.POST.get("code"))

    try:
        user: UserCredentials = await UserCredentials.objects.aget(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)

    if user.signup_code != code:
        return JsonResponse({"error": "The code is incorrect"}, status = 400)
    
    user.signup_code = None

    uid = uuid.uuid4().hex
    token = UserTokens(user = user, token = sha256(uid.encode()).hexdigest(), expires_at = (datetime.datetime.now(tz = datetime.timezone.utc) + datetime.timedelta(days = 30)))
    await token.asave()

    user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
    await user.asave()

    settings = UserSettings(user = user, announcements = True, updates = True, merch = True, status = True, reminders = "2 hours before")
    await settings.asave()

    return JsonResponse({"message": "Code successfully verified", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "merch": settings.merch, "token": uid})

@auth_exempt
@request_type("POST")
async def send_code(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str"})
    if check:
        return JsonResponse(check, status = 400)

    email = request.POST.get("email")
    forgot = request.POST.get("forgot") == "yes"
    
    try:
        user: UserCredentials = await UserCredentials.objects.aget(email = email)
    except:
        return JsonResponse({"error": "A user with that email does not exist"}, status = 400)

    while True:
        code = rd.randint(100000, 999999)
        try:
            await UserCredentials.objects.aget(signup_code = code)
        except:
            break
    
    if not forgot:
        user.signup_code = code
    else:
        user.forgot_code = code

    await user.asave()

    await send_verification_code(user.name, code, user.email)

    return JsonResponse({"message": "Code successfully resent", "user_id": user.user_id, "email": user.email})

@auth_exempt
@request_type("POST")
async def change_password(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "password": "str", "code": "int"})
    if check:
        return JsonResponse(check, status = 400)

    email = request.POST.get("email")
    password = request.POST.get("password")
    code = int(request.POST.get("code"))

    try:
        user: UserCredentials = await UserCredentials.objects.aget(email = email)
    except:
        return JsonResponse({"error": "A user with that email does not exist"}, status = 400)
    
    if user.forgot_code != code:
        return JsonResponse({"error": "The code is incorrect"}, status = 400)

    user.forgot_code = None
    user.set_password(password)

    await user.user_tokens.aupdate(expires_at = datetime.datetime.now(tz = datetime.timezone.utc))

    uid = uuid.uuid4().hex
    token = UserTokens(user = user, token = sha256(uid.encode()).hexdigest(), expires_at = (datetime.datetime.now(tz = datetime.timezone.utc) + datetime.timedelta(days = 30)))
    await token.asave()

    user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
    await user.asave()

    settings: UserSettings = await UserSettings.objects.aget(user = user)

    return JsonResponse({"message": "Password successfully reset", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "merch": settings.merch, "token": uid})

@auth_exempt
@request_type("POST")
async def login(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "password": "str"})
    if check:
        return JsonResponse(check, status = 400)

    email = request.POST.get("email")
    password = request.POST.get("password")

    user: UserCredentials = await sync_to_async(authenticate)(request, email = email, password = password)

    if user and user.signup_code:
        while True:
            code = rd.randint(100000, 999999)
            try:
                await UserCredentials.objects.aget(signup_code = code)
            except:
                break
        
        user.signup_code = code
        await user.asave()

        await send_verification_code(user.name, user.signup_code, user.email)

        return JsonResponse({"message": "Code successfully resent", "user_id": user.user_id, "email": user.email})

    if user:
        uid = uuid.uuid4().hex
        token = UserTokens(user = user, token = sha256(uid.encode()).hexdigest(), expires_at = (datetime.datetime.now(tz = datetime.timezone.utc) + datetime.timedelta(days = 30)))
        await token.asave()

        user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
        await user.asave()

        settings: UserSettings = await UserSettings.objects.aget(user = user)

        return JsonResponse({"message": "User successfully logged in", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "merch": settings.merch, "token": uid})
    
    return JsonResponse({"error": "Email or password is incorrect"}, status = 400)

@request_type("GET")
async def get_permissions(request: HttpRequest):
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