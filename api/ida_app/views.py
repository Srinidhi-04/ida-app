import datetime
from django.http import HttpRequest, JsonResponse, HttpResponse
from django.contrib.auth import authenticate
from ida_app.tasks import *
from ida_app.models import *

def index(request: HttpRequest):
    return HttpResponse("API is up and running")

def signup(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    email = request.POST.get("email")
    name = request.POST.get("name")
    password = request.POST.get("password")

    if not email:
        return JsonResponse({"error": "'email' field is required"}, status = 400)
    if not name:
        return JsonResponse({"error": "'name' field is required"}, status = 400)
    if not password:
        return JsonResponse({"error": "'password' field is required"}, status = 400)

    try:
        user: UserCredentials = UserCredentials.objects.create_user(email = email, name = name, password = password)
    except Exception:
        return JsonResponse({"error": "A user with that email already exists"}, status = 400)

    settings = UserSettings(user = user, announcements = True, updates = True, merch = True, status = True, reminders = True)
    settings.save()

    return JsonResponse({"message": "User successfully signed up", "user_id": user.user_id, "email": user.email, "name": user.name, "admin": user.admin})

def login(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    email = request.POST.get("email")
    password = request.POST.get("password")

    if not email:
        return JsonResponse({"error": "'email' field is required"}, status = 400)
    if not password:
        return JsonResponse({"error": "'password' field is required"}, status = 400)

    user: UserCredentials = authenticate(request, email = email, password = password)

    if user:
        return JsonResponse({"message": "User successfully logged in", "user_id": user.user_id, "email": user.email, "name": user.name, "admin": user.admin})
    
    return JsonResponse({"error": "Email or password is incorrect"}, status = 400)

def add_event(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)

    name = request.POST.get("name")
    date = request.POST.get("date")
    location = request.POST.get("location")
    body = request.POST.get("body")

    try:
        latitude = float(request.POST.get("latitude"))
    except:
        return JsonResponse({"error": "'latitude' field is required as a float"}, status = 400)
    
    try:
        longitude = float(request.POST.get("longitude"))
    except:
        return JsonResponse({"error": "'longitude' field is required as a float"}, status = 400)
    
    image = request.POST.get("image")
    if not image or image == "":
        image = "https://i.imgur.com/Mw85Kfp.png"

    essential = request.POST.get("essential")
    if not essential:
        essential = False
    else:
        essential = essential == "yes"

    if not name:
        return JsonResponse({"error": "'name' field is required"}, status = 400)
    if not date:
        return JsonResponse({"error": "'date' field is required"}, status = 400)
    if not location:
        return JsonResponse({"error": "'location' field is required"}, status = 400)
    if not body:
        return JsonResponse({"error": "'body' field is required"}, status = 400)
    
    try:
        event_date = datetime.datetime.strptime(date, "%Y-%m-%d %H:%M:%S")
        event = Events(name = name, date = event_date, location = location, latitude = latitude, longitude = longitude, image = image, essential = essential, body = body)
        event.save()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)
    
    schedule_topic_notification(topic=f"ida-event-{event.event_id}", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=event_date)

    return JsonResponse({"message": "Event successfully added", "event_id": event.event_id})

def edit_event(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)

    try:
        event_id = int(request.POST.get("event_id"))
    except:
        return JsonResponse({"error": "'event_id' field is required as an int"}, status = 400)

    name = request.POST.get("name")
    date = request.POST.get("date")
    location = request.POST.get("location")
    body = request.POST.get("body")

    try:
        latitude = float(request.POST.get("latitude"))
    except:
        return JsonResponse({"error": "'latitude' field is required as a float"}, status = 400)
    
    try:
        longitude = float(request.POST.get("longitude"))
    except:
        return JsonResponse({"error": "'longitude' field is required as a float"}, status = 400)
    
    image = request.POST.get("image")
    if not image or image == "":
        image = "https://i.imgur.com/Mw85Kfp.png"

    essential = request.POST.get("essential")
    if not essential:
        essential = False
    else:
        essential = essential == "yes"

    if not name:
        return JsonResponse({"error": "'name' field is required"}, status = 400)
    if not date:
        return JsonResponse({"error": "'date' field is required"}, status = 400)
    if not location:
        return JsonResponse({"error": "'location' field is required"}, status = 400)
    if not body:
        return JsonResponse({"error": "'body' field is required"}, status = 400)
    
    try:
        event_date = datetime.datetime.strptime(date, "%Y-%m-%d %H:%M:%S")
        event = Events.objects.get(event_id = event_id)
    except:
        return JsonResponse({"error": "An event with that event ID does not exist"}, status = 400)
    
    delete_topic_notification(topic=f"ida-event-{event.event_id}", run_time=event.date)

    event.name = name
    event.date = event_date
    event.location = location
    event.latitude = latitude
    event.longitude = longitude
    event.image = image
    event.essential = essential
    event.body = body

    if event_date > datetime.datetime.now():
        event.completed = False

    event.save()
    
    schedule_topic_notification(topic=f"ida-event-{event.event_id}", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=event_date)

    return JsonResponse({"message": "Event successfully edited", "event_id": event.event_id})

def delete_event(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        event_id = int(request.POST.get("event_id"))
    except:
        return JsonResponse({"error": "'event_id' field is required as an int"}, status = 400)
    
    try:
        event = Events.objects.get(event_id = event_id)
    except:
        return JsonResponse({"error": "An event with that event ID does not exist"}, status = 400)
    
    try:
        event.delete()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)
    
    return JsonResponse({"message": "Event deleted successfully"})

def get_events(request: HttpRequest):
    if request.method != "GET":
        return JsonResponse({"error": "This endpoint can only be accessed via GET"}, status = 400)
    
    completed = request.GET.get("completed")
    essential = request.GET.get("essential")

    Events.objects.filter(date__lte = datetime.datetime.now().astimezone(tz = datetime.timezone.utc)).update(completed = True)
    
    if not completed:
        events = list(Events.objects.all().values())
    else:
        events = Events.objects.filter(completed = completed == "yes").order_by("-essential")
        if completed != "yes" and essential:
            events = events.filter(essential = essential == "yes").order_by("-essential")
        events = list(events.values())

    return JsonResponse({"data": events})

def toggle_notification(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)

    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required as an int"}, status = 400)
    
    try:
        event_id = int(request.POST.get("event_id"))
    except:
        return JsonResponse({"error": "'event_id' field is required as an int"}, status = 400)

    try:
        user = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    try:
        event = Events.objects.get(event_id = event_id)
    except:
        return JsonResponse({"error": "An event with that event ID does not exist"}, status = 400)
    
    try:
        notif = UserNotifications.objects.get(user = user, event = event)
        notif.delete()
    except:
        notif = UserNotifications(user = user, event = event)
        notif.save()
    
    return JsonResponse({"message": "Notification successfully toggled"})

def get_notifications(request: HttpRequest):
    if request.method != "GET":
        return JsonResponse({"error": "This endpoint can only be accessed via GET"}, status = 400)

    try:
        user_id = int(request.GET.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required as an int"}, status = 400)

    try:
        user = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)

    notifs = UserNotifications.objects.filter(user = user).only("event_id")
    
    return JsonResponse({"data": [x["event_id"] for x in list(notifs.values("event_id"))]})

def change_settings(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required as an int"}, status = 400)
    
    announcements = request.POST.get("announcements")
    if not announcements:
        return JsonResponse({"error": "'announcements' field is required"}, status = 400)
    announcements = announcements == "yes"
    
    updates = request.POST.get("updates")
    if not updates:
        return JsonResponse({"error": "'updates' field is required"}, status = 400)
    updates = updates == "yes"
    
    merch = request.POST.get("merch")
    if not merch:
        return JsonResponse({"error": "'merch' field is required"}, status = 400)
    merch = merch == "yes"
    
    status = request.POST.get("status")
    if not status:
        return JsonResponse({"error": "'status' field is required"}, status = 400)
    status = status == "yes"

    reminders = request.POST.get("reminders")
    if not reminders:
        return JsonResponse({"error": "'reminders' field is required"}, status = 400)
    
    try:
        user = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    settings = UserSettings.objects.get(user = user)
    settings.announcements = announcements
    settings.updates = updates
    settings.merch = merch
    settings.status = status
    settings.reminders = reminders
    settings.save()

    return JsonResponse({"message": "Settings changed successfully"})

def get_settings(request: HttpRequest):
    if request.method != "GET":
        return JsonResponse({"error": "This endpoint can only be accessed via GET"}, status = 400)
    
    try:
        user_id = int(request.GET.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required as an int"}, status = 400)
    
    try:
        user = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    settings = UserSettings.objects.get(user = user).__dict__
    settings.pop("_state")

    return JsonResponse({"data": settings})

def change_name(request: HttpRequest):
    if request.method != "POST":
        return JsonResponse({"error": "This endpoint can only be accessed via POST"}, status = 400)
    
    try:
        user_id = int(request.POST.get("user_id"))
    except:
        return JsonResponse({"error": "'user_id' field is required as an int"}, status = 400)
    
    name = request.POST.get("name")
    if not name:
        return JsonResponse({"error": "'name' field is required"}, status = 400)
    
    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    user.name = name
    user.save()

    return JsonResponse({"message": "Name changed successfully"})