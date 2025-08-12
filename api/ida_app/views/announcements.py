from django.http import HttpRequest, JsonResponse
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

@requires_roles(["admin"])
@request_type("POST")
def send_announcement(request: HttpRequest):
    check = requires_fields(request.POST, {"title": "str", "body": "str"})
    if check:
        return check

    title = request.POST.get("title")
    body = request.POST.get("body")
    everyone = request.POST.get("everyone") == "yes"

    if everyone:
        send_topic_notification("ida-app-default", title, body)

    else:
        send_topic_notification("ida-app-announcements", title, body)

    return JsonResponse({"message": "Announcement sent successfully"})

@requires_roles(["admin"])
@request_type("POST")
def add_announcement(request: HttpRequest):
    check = requires_fields(request.POST, {"title": "str", "body": "str"})
    if check:
        return check

    title = request.POST.get("title")
    body = request.POST.get("body")

    announcement = BannerAnnouncements(title = title, body = body)
    announcement.save()

    return JsonResponse({"message": "Announcement created successfully"})

@request_type("POST")
def update_announcement(request: HttpRequest):
    check = requires_fields(request.POST, {"last_announcement": "int"})
    if check:
        return check

    user: UserCredentials = request.user

    last_announcement = int(request.POST.get("last_announcement"))
    
    user.last_announcement = last_announcement
    user.save()

    return JsonResponse({"message": "Last announcement updated successfully"})

@request_type("GET")
def get_announcements(request: HttpRequest):
    user: UserCredentials = request.user

    last_announcement = user.last_announcement
    announcements = list(BannerAnnouncements.objects.filter(announcement_id__gt = last_announcement).values())

    return JsonResponse({"data": announcements})