from django.http import HttpRequest, JsonResponse
from asgiref.sync import sync_to_async
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

@request_type("POST")
async def delete_account(request: HttpRequest):
    try:
        user: UserCredentials = request.user

        await user.adelete()
        
        return JsonResponse({"message": "Account deleted successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def change_settings(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"announcements": "str", "updates": "str", "merch": "str", "status": "str", "mailing": "str", "reminders": "str"})
        if check:
            return JsonResponse(check, status = 400)

        user: UserCredentials = request.user
        announcements = request.POST.get("announcements") == "yes"
        updates = request.POST.get("updates") == "yes"
        merch = request.POST.get("merch") == "yes"
        status = request.POST.get("status") == "yes"
        mailing = request.POST.get("mailing") == "yes"
        reminders = request.POST.get("reminders")

        settings: UserSettings = await UserSettings.objects.aget(user = user)
        settings.announcements = announcements
        settings.updates = updates
        settings.merch = merch
        settings.status = status
        settings.reminders = reminders
        await settings.asave()

        if mailing != user.mailing:
            user.mailing = mailing
            await user.asave()

            await send_subscriber(user.name, user.email, mailing)

        return JsonResponse({"message": "Settings changed successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("GET")
async def get_settings(request: HttpRequest):
    try:
        user: UserCredentials = request.user
        
        settings: UserSettings = await UserSettings.objects.aget(user = user)

        return JsonResponse({"data": {"announcements": settings.announcements, "updates": settings.updates, "merch": settings.merch, "status": settings.status, "reminders": settings.reminders, "mailing": user.mailing}})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def edit_profile(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"name": "str", "avatar": "int"})
        if check:
            return JsonResponse(check, status = 400)

        user: UserCredentials = request.user

        name = request.POST.get("name")
        avatar = int(request.POST.get("avatar"))
        user.name = name
        user.avatar = avatar
        await user.asave()

        return JsonResponse({"message": "Profile edited successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)


@requires_roles(["admin"])
@request_type("POST")
async def edit_role(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"email": "str", "role": "str"})
        if check:
            return JsonResponse(check, status = 400)

        email = request.POST.get("email")
        try:
            target: UserCredentials = await UserCredentials.objects.aget(email = email)
        except ObjectDoesNotExist:
            raise Exception("A user with that email does not exist")
        
        role = request.POST.get("role")

        target.role = role
        await target.asave()

        return JsonResponse({"message": "Role edited successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@requires_roles(["admin"])
@request_type("GET")
async def get_roles(request: HttpRequest):
    try:
        total_users = await UserCredentials.objects.acount()
        
        emails = await sync_to_async(list)(UserCredentials.objects.values("email", "role"))
        roles = sorted(list(set([x["role"] for x in emails])))

        return JsonResponse({"data": {"total_users": total_users, "emails": emails, "roles": roles}})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)