import uuid
import datetime
import random as rd
from django.http import HttpRequest, JsonResponse, HttpResponse, QueryDict
from django.contrib.auth import authenticate
import stripe
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *

APP_VERSION = 11.4

def requires_fields(body: QueryDict, fields: dict):
    for field in fields:
        value = body.get(field)
        if not value:
            return JsonResponse({"error": f"'{field}' field is required"}, status = 400)
        
        if fields[field] == "int":
            try:
                int(value)
            except:
                return JsonResponse({"error": f"'{field}' field is required as an int"}, status = 400)
        
        if fields[field] == "float":
            try:
                float(value)
            except:
                return JsonResponse({"error": f"'{field}' field is required as a float"}, status = 400)

@auth_exempt
def index(request: HttpRequest):
    return HttpResponse("API is up and running")

@auth_exempt
@request_type("GET")
def check_update(request: HttpRequest):    
    check = requires_fields(request.GET, {"version": "float"})
    if check:
        return check

    version = float(request.GET.get("version"))
    
    if version < int(APP_VERSION):
        return JsonResponse({"message": "Hard update"})
    
    if version < APP_VERSION:
        return JsonResponse({"message": "Soft update"})
    
    return JsonResponse({"message": "Updated"})

@auth_exempt
@request_type("POST")
def signup(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "name": "str", "password": "str"})
    if check:
        return check

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
        return check

    user_id = int(request.POST.get("user_id"))
    code = int(request.POST.get("code"))

    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)

    if user.signup_code != code:
        return JsonResponse({"error": "The code is incorrect"}, status = 400)
    
    user.signup_code = None

    uid = uuid.uuid4()
    user.token = uid.hex

    user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
    user.save()

    settings = UserSettings(user = user, announcements = True, updates = True, merch = True, status = True, reminders = "2 hours before")
    settings.save()

    return JsonResponse({"message": "Code successfully verified", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "token": user.token})

@auth_exempt
@request_type("POST")
def send_code(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str"})
    if check:
        return check

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
        return check

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

    uid = uuid.uuid4()
    user.token = uid.hex

    user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
    user.save()

    settings: UserSettings = user.user_settings

    return JsonResponse({"message": "Password successfully reset", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "token": user.token})

@auth_exempt
@request_type("POST")
def login(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "password": "str"})
    if check:
        return check

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
        if datetime.datetime.now(tz = datetime.timezone.utc) - user.last_login.replace(tzinfo = datetime.timezone.utc) > datetime.timedelta(days = 30):
            uid = uuid.uuid4()
            user.token = uid.hex

        user.last_login = datetime.datetime.now(tz = datetime.timezone.utc)
        user.save()

        settings: UserSettings = user.user_settings

        return JsonResponse({"message": "User successfully logged in", "user_id": user.user_id, "email": user.email, "name": user.name, "avatar": user.avatar, "role": user.role, "reminders": settings.reminders, "announcements": settings.announcements, "token": user.token})
    
    return JsonResponse({"error": "Email or password is incorrect"}, status = 400)

@request_type("POST")
def delete_account(request: HttpRequest):
    user: UserCredentials = request.user

    try:
        user.delete()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)
    
    return JsonResponse({"message": "Account deleted successfully"})

@requires_roles(["admin"])
@request_type("POST")
def add_event(request: HttpRequest):
    check = requires_fields(request.POST, {"name": "str", "date": "str", "timezone": "str", "location": "str", "body": "str", "latitude": "float", "longitude": "float"})
    if check:
        return check

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

        event = Events(name = name, date = event_date, location = location, latitude = latitude, longitude = longitude, image = image, essential = essential, body = body, ticket = ticket)
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
        return check

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
        return check

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
        return check

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
        return check

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

@request_type("POST")
def change_settings(request: HttpRequest):
    check = requires_fields(request.POST, {"announcements": "str", "updates": "str", "merch": "str", "status": "str", "mailing": "str", "reminders": "str"})
    if check:
        return check

    user: UserCredentials = request.user
    announcements = request.POST.get("announcements") == "yes"
    updates = request.POST.get("updates") == "yes"
    merch = request.POST.get("merch") == "yes"
    status = request.POST.get("status") == "yes"
    mailing = request.POST.get("mailing") == "yes"
    reminders = request.POST.get("reminders")

    settings: UserSettings = user.user_settings
    settings.announcements = announcements
    settings.updates = updates
    settings.merch = merch
    settings.status = status
    settings.reminders = reminders
    settings.save()

    if mailing != user.mailing:
        user.mailing = mailing
        user.save()

        send_subscriber(user.name, user.email, mailing)

    return JsonResponse({"message": "Settings changed successfully"})

@request_type("GET")
def get_settings(request: HttpRequest):
    user: UserCredentials = request.user
    
    settings: dict = user.user_settings.__dict__
    settings.pop("_state")
    settings["mailing"] = user.mailing

    return JsonResponse({"data": settings})

@request_type("POST")
def edit_profile(request: HttpRequest):
    check = requires_fields(request.POST, {"name": "str", "avatar": "int"})
    if check:
        return check

    user: UserCredentials = request.user

    name = request.POST.get("name")
    avatar = int(request.POST.get("avatar"))
    user.name = name
    user.avatar = avatar
    user.save()

    return JsonResponse({"message": "Profile edited successfully"})

@requires_roles(["admin"])
@request_type("POST")
def add_item(request: HttpRequest):
    check = requires_fields(request.POST, {"name": "str", "price": "float"})
    if check:
        return check

    name = request.POST.get("name")
    price = float(request.POST.get("price"))
    image = request.POST.get("image")
    if not image or image == "":
        image = "https://i.imgur.com/Mw85Kfp.png"
    
    try:
        item = ShopItems(name = name, price = price, image = image)
        item.save()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)

    return JsonResponse({"message": "Item successfully added", "item_id": item.item_id})

@requires_roles(["admin"])
@request_type("POST")
def edit_item(request: HttpRequest):
    check = requires_fields(request.POST, {"item_id": "int", "name": "str", "price": "float"})
    if check:
        return check

    item_id = int(request.POST.get("item_id"))
    name = request.POST.get("name")
    price = float(request.POST.get("price"))
    image = request.POST.get("image")
    if not image or image == "":
        image = "https://i.imgur.com/Mw85Kfp.png"

    try:
        item = ShopItems.objects.get(item_id = item_id)
    except:
        return JsonResponse({"error": "An item with that item ID does not exist"}, status = 400)

    item.name = name
    item.price = price
    item.image = image
    item.save()

    return JsonResponse({"message": "Item successfully edited", "item_id": item.item_id})

@request_type("GET")
def get_items(request: HttpRequest):
    items = list(ShopItems.objects.values())

    return JsonResponse({"data": items})

@requires_roles(["admin"])
@request_type("POST")
def delete_item(request: HttpRequest):
    check = requires_fields(request.POST, {"item_id": "int"})
    if check:
        return check

    item_id = int(request.POST.get("item_id"))

    try:
        item = ShopItems.objects.get(item_id = item_id)
    except:
        return JsonResponse({"error": "An item with that item ID does not exist"}, status = 400)

    try:
        item.delete()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)

    return JsonResponse({"message": "Item deleted successfully"})

@request_type("POST")
def edit_cart(request: HttpRequest):
    check = requires_fields(request.POST, {"item_id": "int", "quantity": "int"})
    if check:
        return check

    user: UserCredentials = request.user
    item_id = int(request.POST.get("item_id"))
    quantity = int(request.POST.get("quantity"))

    try:
        item = ShopItems.objects.get(item_id = item_id)
    except:
        return JsonResponse({"error": "An item with that item ID does not exist"}, status = 400)

    try:
        cart_item: UserCarts = user.user_carts.get(item = item)
        cart_item.quantity = quantity
    except:
        cart_item = UserCarts(user = user, item = item, quantity = quantity)
    
    try:
        if cart_item.quantity == 0:
            cart_item.delete()
        else:
            cart_item.save()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)

    return JsonResponse({"message": "Cart successfully edited"})

@request_type("GET")
def get_cart(request: HttpRequest):
    user: UserCredentials = request.user

    cart_item = list(user.user_carts.values("item_id", "quantity"))

    return JsonResponse({"data": cart_item})

@request_type("POST")
def stripe_payment(request: HttpRequest):
    check = requires_fields(request.POST, {"amount": "float"})
    if check:
        return check

    amount = int(float(request.POST.get("amount")) * 100)
    if amount < 50:
        return JsonResponse({"error": "Amount must be at least $0.5"}, status = 400)

    payment_intent = stripe.PaymentIntent.create(
        amount = amount,
        currency = "usd",
        payment_method_types = ["card"]
    )

    return JsonResponse({"message": "Stripe payment sheet successfully created", "payment_intent": payment_intent.client_secret, "publishable_key": "pk_test_51RnYlzQkArntKpGlapTuIf51Fvsi1CittiW7jyvqGN4mKEg9z5baV4kWtOKWHWiW14TzzRqxbSXHZQz01xRJeK8k00gJ2IaMpr"})

@request_type("POST")
def log_donation(request: HttpRequest):
    check = requires_fields(request.POST, {"name": "str", "email": "str", "amount": "float"})
    if check:
        return check

    user: UserCredentials = request.user
    name = request.POST.get("name")
    email = request.POST.get("email")
    amount = float(request.POST.get("amount"))

    try:
        receipt: DonationReceipts = DonationReceipts(user = user, name = name, email = email, amount = amount)
        receipt.save()

        send_donation(name, email, amount)
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)

    return JsonResponse({"message": "Donation successfully logged"})

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
def edit_role(request: HttpRequest):
    check = requires_fields(request.POST, {"email": "str", "role": "str"})
    if check:
        return check

    email = request.POST.get("email")
    try:
        target: UserCredentials = UserCredentials.objects.get(email = email)
    except:
        return JsonResponse({"error": "A user with that email does not exist"}, status = 400)
    
    role = request.POST.get("role")

    target.role = role
    target.save()

    return JsonResponse({"message": "Role edited successfully"})

@requires_roles(["admin"])
@request_type("GET")
def get_roles(request: HttpRequest):
    total_users = UserCredentials.objects.count()
    
    emails = list(UserCredentials.objects.values("email", "role"))
    roles = list(set([x["role"] for x in emails]))

    return JsonResponse({"data": {"total_users": total_users, "emails": emails, "roles": roles}})

@request_type("POST")
def send_query(request: HttpRequest):
    check = requires_fields(request.POST, {"query": "str"})
    if check:
        return check

    user: UserCredentials = request.user

    query = request.POST.get("query")

    send_question(user.name, user.email, query)

    return JsonResponse({"message": "Query sent successfully"})

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

@request_type("GET")
def get_permissions(request: HttpRequest):
    check = requires_fields(request.GET, {"category": "str"})
    if check:
        return check

    user: UserCredentials = request.user

    category = request.GET.get("category")

    if category == "announcements":
        roles = ["admin"]
    elif category == "events":
        roles = ["admin"]
    elif category == "shop":
        roles = ["admin"]
    elif category == "roles":
        roles = ["admin"]

    return JsonResponse({"data": {"roles": roles, "access": user.role in roles, "role": user.role}})