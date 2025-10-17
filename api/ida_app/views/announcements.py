from django.http import HttpRequest, JsonResponse
from asgiref.sync import sync_to_async
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

@requires_roles(["admin", "comms"])
@request_type("POST")
async def send_announcement(request: HttpRequest):
    check = requires_fields(request.POST, {"title": "str", "body": "str"})
    if check:
        return JsonResponse(check, status = 400)

    title = request.POST.get("title")
    body = request.POST.get("body")
    everyone = request.POST.get("everyone") == "yes"

    if everyone:
        await send_topic_notification("ida-app-default", title, body)

    else:
        await send_topic_notification("ida-app-announcements", title, body)

    return JsonResponse({"message": "Announcement sent successfully"})

@requires_roles(["admin", "comms"])
@request_type("POST")
async def add_announcement(request: HttpRequest):
    check = requires_fields(request.POST, {"title": "str", "body": "str"})
    if check:
        return JsonResponse(check, status = 400)

    title = request.POST.get("title")
    body = request.POST.get("body")

    announcement = BannerAnnouncements(title = title, body = body)
    await announcement.asave()

    return JsonResponse({"message": "Announcement created successfully"})

@request_type("POST")
async def update_announcement(request: HttpRequest):
    check = requires_fields(request.POST, {"last_announcement": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user: UserCredentials = request.user

    last_announcement = int(request.POST.get("last_announcement"))
    
    user.last_announcement = last_announcement
    await user.asave()

    return JsonResponse({"message": "Last announcement updated successfully"})

@request_type("GET")
async def get_announcements(request: HttpRequest):
    user: UserCredentials = request.user

    last_announcement = user.last_announcement
    announcements = await sync_to_async(lambda: list(BannerAnnouncements.objects.filter(announcement_id__gt = last_announcement).values()))()

    return JsonResponse({"data": announcements})