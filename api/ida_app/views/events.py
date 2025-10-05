import datetime
from django.http import HttpRequest, JsonResponse
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

@requires_roles(["admin"])
@request_type("POST")
def add_event(request: HttpRequest):
    check = requires_fields(request.POST, {"name": "str", "date": "str", "timezone": "str", "location": "str", "body": "str", "latitude": "float", "longitude": "float"})
    if check:
        return JsonResponse(check, status = 400)

    name = request.POST.get("name")
    date = request.POST.get("date")
    timezone = request.POST.get("timezone")
    location = request.POST.get("location")
    body = request.POST.get("body")
    latitude = float(request.POST.get("latitude"))
    longitude = float(request.POST.get("longitude"))
    image = request.POST.get("image")
    if not image or image == "":
        image = "https://i.imgur.com/Mw85Kfp.png"

    essential = request.POST.get("essential") == "yes"

    ticket = request.POST.get("ticket")
    if not ticket:
        ticket = ""

    try:
        tz = datetime.timezone(offset=datetime.timedelta(hours=float(timezone.split(":")[0]), minutes=float(timezone.split(":")[1])))
        event_date = datetime.datetime.strptime(date, "%Y-%m-%d %H:%M:%S").replace(tzinfo=tz)

        event = Events(name = name, date = event_date, location = location, latitude = latitude, longitude = longitude, image = image, essential = essential, body = body, ticket = ticket, completed = (event_date.astimezone(tz = datetime.timezone.utc) <= datetime.datetime.now(tz = datetime.timezone.utc)))
        event.save()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)
    
    schedule_topic_notification(topic=f"ida-event-{event.event_id}", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=event_date)
    schedule_topic_notification(topic=f"ida-event-{event.event_id}-0", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=(event_date-datetime.timedelta(minutes=30)))
    schedule_topic_notification(topic=f"ida-event-{event.event_id}-1", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=(event_date-datetime.timedelta(hours=2)))
    schedule_topic_notification(topic=f"ida-event-{event.event_id}-2", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=(event_date-datetime.timedelta(hours=6)))

    return JsonResponse({"message": "Event successfully added", "event_id": event.event_id})

@requires_roles(["admin"])
@request_type("POST")
def edit_event(request: HttpRequest):
    check = requires_fields(request.POST, {"event_id": "int", "name": "str", "date": "str", "timezone": "str", "location": "str", "body": "str", "latitude": "float", "longitude": "float"})
    if check:
        return JsonResponse(check, status = 400)

    event_id = int(request.POST.get("event_id"))
    name = request.POST.get("name")
    date = request.POST.get("date")
    timezone = request.POST.get("timezone")
    location = request.POST.get("location")
    body = request.POST.get("body")
    latitude = float(request.POST.get("latitude"))
    longitude = float(request.POST.get("longitude"))

    image = request.POST.get("image")
    if not image or image == "":
        image = "https://i.imgur.com/Mw85Kfp.png"

    essential = request.POST.get("essential") == "yes"

    ticket = request.POST.get("ticket")
    if not ticket:
        ticket = ""

    try:
        tz = datetime.timezone(offset=datetime.timedelta(hours=float(timezone.split(":")[0]), minutes=float(timezone.split(":")[1])))
        event_date = datetime.datetime.strptime(date, "%Y-%m-%d %H:%M:%S").replace(tzinfo=tz)

        event = Events.objects.get(event_id = event_id)
    except:
        return JsonResponse({"error": "An event with that event ID does not exist"}, status = 400)
    
    delete_topic_notification(topic=f"ida-event-{event.event_id}")
    delete_topic_notification(topic=f"ida-event-{event.event_id}-0")
    delete_topic_notification(topic=f"ida-event-{event.event_id}-1")
    delete_topic_notification(topic=f"ida-event-{event.event_id}-2")

    event.name = name
    event.date = event_date
    event.location = location
    event.latitude = latitude
    event.longitude = longitude
    event.image = image
    event.essential = essential
    event.body = body
    event.ticket = ticket

    if event_date.astimezone(tz = datetime.timezone.utc) > datetime.datetime.now(tz = datetime.timezone.utc):
        event.completed = False
    else:
        event.completed = True

    event.save()
    
    schedule_topic_notification(topic=f"ida-event-{event.event_id}", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=event_date)
    schedule_topic_notification(topic=f"ida-event-{event.event_id}-0", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=(event_date-datetime.timedelta(minutes=30)))
    schedule_topic_notification(topic=f"ida-event-{event.event_id}-1", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=(event_date-datetime.timedelta(hours=2)))
    schedule_topic_notification(topic=f"ida-event-{event.event_id}-2", title="Event starting soon!", body=f"{name} is starting soon at {location} at {event_date.strftime("%I:%M")} {"AM" if event_date.hour < 12 else "PM"} on {event_date.strftime("%m/%d/%Y")}", run_time=(event_date-datetime.timedelta(hours=6)))

    return JsonResponse({"message": "Event successfully edited", "event_id": event.event_id})

@requires_roles(["admin"])
@request_type("POST")
def delete_event(request: HttpRequest):
    check = requires_fields(request.POST, {"event_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    event_id = int(request.POST.get("event_id"))
    try:
        event = Events.objects.get(event_id = event_id)
    except:
        return JsonResponse({"error": "An event with that event ID does not exist"}, status = 400)
    
    delete_topic_notification(topic=f"ida-event-{event.event_id}")
    delete_topic_notification(topic=f"ida-event-{event.event_id}-0")
    delete_topic_notification(topic=f"ida-event-{event.event_id}-1")
    delete_topic_notification(topic=f"ida-event-{event.event_id}-2")

    try:
        event.delete()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)
    
    return JsonResponse({"message": "Event deleted successfully"})

@request_type("GET")
def get_events(request: HttpRequest):
    user: UserCredentials = request.user

    completed = request.GET.get("completed")
    essential = request.GET.get("essential")

    Events.objects.filter(date__lte = datetime.datetime.now(tz = datetime.timezone.utc)).update(completed = True)
    
    if not completed:
        events = list(Events.objects.order_by("date").values())
    else:
        events = Events.objects.filter(completed = completed == "yes").order_by("date")
        if completed != "yes" and essential:
            events = events.filter(essential = essential == "yes").order_by("date")
        events = list(events.values())
    
    rsvp = list(EventRsvp.objects.filter(user = user).values("event_id"))
    rsvp_ids = {x["event_id"] for x in rsvp}

    for i in range(len(events)):
        events[i]["rsvp"] = events[i]["event_id"] in rsvp_ids

    return JsonResponse({"data": events})

@request_type("POST")
def toggle_rsvp(request: HttpRequest):
    check = requires_fields(request.POST, {"event_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user: UserCredentials = request.user
    event_id = int(request.POST.get("event_id"))
    try:
        event = Events.objects.get(event_id = event_id)
    except:
        return JsonResponse({"error": "An event with that event ID does not exist"}, status = 400)
    
    try:
        rsvp: EventRsvp = user.user_rsvp.get(event = event)
        rsvp.delete()
    except:
        rsvp = EventRsvp(user = user, event = event)
        rsvp.save()
    
    return JsonResponse({"message": "Event successfully RSVPed"})

@request_type("GET")
def get_rsvp(request: HttpRequest):
    user: UserCredentials = request.user

    Events.objects.filter(date__lte = datetime.datetime.now(tz = datetime.timezone.utc)).update(completed = True)
    
    all_events = list(Events.objects.values())
    
    rsvp = list(EventRsvp.objects.filter(user = user).values("event_id"))
    rsvp_ids = {x["event_id"] for x in rsvp}

    events = []
    for event in all_events:
        if event["event_id"] in rsvp_ids:
            events.append(event)

    return JsonResponse({"data": events})

@request_type("POST")
def toggle_notification(request: HttpRequest):
    check = requires_fields(request.POST, {"event_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user: UserCredentials = request.user
    event_id = int(request.POST.get("event_id"))
    try:
        event = Events.objects.get(event_id = event_id)
    except:
        return JsonResponse({"error": "An event with that event ID does not exist"}, status = 400)
    
    try:
        notif: UserNotifications = user.user_notifications.get(event = event)
        notif.delete()
    except:
        notif = UserNotifications(user = user, event = event)
        notif.save()
    
    return JsonResponse({"message": "Notification successfully toggled"})

@request_type("GET")
def get_notifications(request: HttpRequest):
    user: UserCredentials = request.user

    notifs = list(user.user_notifications.values("event_id"))
    
    return JsonResponse({"data": [x["event_id"] for x in notifs]})