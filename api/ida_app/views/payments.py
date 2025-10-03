import stripe
from django.http import HttpRequest, JsonResponse
from django.db import transaction
from django.db.models import F
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *
import json
import os
# from dotenv import load_dotenv

# load_dotenv()

STRIPE_PUBLISH = os.getenv("STRIPE_PUBLISH_TEST")

def create_intent(amount: float):
    amount = int(amount * 100)
    if amount < 50:
        return {"error": "Amount must be at least $0.5"}

    payment_intent = stripe.PaymentIntent.create(
        amount = amount,
        currency = "usd",
        payment_method_types = ["card"]
    )

    return {"message": "Stripe payment sheet successfully created", "payment_intent": payment_intent.client_secret, "publishable_key": STRIPE_PUBLISH}

@request_type("POST")
def stripe_payment(request: HttpRequest):
    check = requires_fields(request.POST, {"amount": "float"})
    if check:
        return JsonResponse(check, status = 400)

    intent = create_intent(float(request.POST.get("amount")))
    if "error" in intent:
        return JsonResponse(intent, status = 400)
    
    return JsonResponse(intent)

@request_type("POST")
def start_order(request: HttpRequest):
    body = json.loads(request.body)

    check = requires_fields(body, {"cart": "list", "amount": "float"})
    if check:
        return JsonResponse(check, status = 400)

    cart = body.get("cart")

    try:
        with transaction.atomic():
            for x in cart:
                item_check = requires_fields(x, {"item_id": "int", "quantity": "int"})
                if item_check:
                    raise Exception(item_check["error"])

                try:
                    item = ShopItems.objects.select_for_update().get(item_id = x["item_id"])
                except:
                    raise Exception("An item with that item ID does not exist")
                
                if item.inventory < x["quantity"]:
                    raise Exception("Not enough items in inventory")
                
                item.inventory -= x["quantity"]
                item.save()
                
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

    intent = create_intent(float(body.get("amount")))
    if "error" in intent:
        return JsonResponse(intent, status = 400)
    
    return JsonResponse(intent)

@request_type("POST")
def cancel_order(request: HttpRequest):
    body = json.loads(request.body)

    check = requires_fields(body, {"cart": "list"})
    if check:
        return JsonResponse(check, status = 400)

    cart = body.get("cart")

    try:
        with transaction.atomic():
            for x in cart:
                item_check = requires_fields(x, {"item_id": "int", "quantity": "int"})
                if item_check:
                    raise Exception(item_check["error"])

                try:
                    item = ShopItems.objects.get(item_id = x["item_id"])
                except:
                    return JsonResponse({"error": "An item with that item ID does not exist"}, status = 400)
                
                item.inventory += x["quantity"]
                item.save()
                
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

    return JsonResponse({"message": "Order cancelled successfully"})

@request_type("POST")
def log_order(request: HttpRequest):
    check = requires_fields(json.loads(request.body), {"value": "float", "cart": "list"})
    if check:
        return JsonResponse(check, status = 400)
    
    user: UserCredentials = request.user
    value = json.loads(request.body).get("value")
    cart = json.loads(request.body).get("cart")

    try:
        with transaction.atomic():
            try:
                order = UserOrders(user = user, value = value)
                order.save()
            except:
                raise Exception("An unknown error occurred with the database")
            
            try:
                user.user_carts.all().delete()
            except:
                raise Exception("An unknown error occurred with the database")

            receipt = []
            for x in cart:
                item_check = requires_fields(x, {"item_id": "int", "quantity": "int", "amount": "float"})
                if item_check:
                    raise Exception(item_check["error"])

                try:
                    item = ShopItems.objects.get(item_id = x["item_id"])
                    receipt.append({"name": item.name, "quantity": x["quantity"], "price": item.price, "image": item.image, "amount": x["amount"]})
                except:
                    raise Exception("An item with that item ID does not exist")
                
                try:
                    order_item = OrderItems(order = order, item = item, quantity = x["quantity"], subtotal = x["amount"])
                    order_item.save()
                except:
                    raise Exception("An unknown error occurred with the database")
                
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

    send_order(user.name, user.email, value, receipt)

    return JsonResponse({"message": "Order placed successfully", "order_id": order.order_id, "date": order.created_at, "receipt": receipt, "status": order.status, "amount": order.value})

@request_type("GET")
def get_orders(request: HttpRequest):
    check = requires_fields(request.GET, {"user_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user = request.user
    
    return JsonResponse({"data": list(user.user_orders.values("order_id", "value", "status", "created_at").order_by("created_at"))})

@request_type("GET")
def get_order(request: HttpRequest):
    check = requires_fields(request.GET, {"user_id": "int", "order_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user_id = int(request.GET.get("user_id"))
    order_id = int(request.GET.get("order_id"))

    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    try:
        order: UserOrders = UserOrders.objects.get(order_id = order_id, user = user)
    except:
        return JsonResponse({"error": "Invalid order ID and user ID combination"}, status = 400)
    
    return JsonResponse({"data": {"order_id": order.order_id, "status": order.status, "amount": order.value, "items": list(order.order_items.annotate(name = F("item__name"), price = F("item__price"), image = F("item__image")).values("name", "price", "image", "quantity", "subtotal"))}})

@requires_roles(["admin"])
@request_type("POST")
def change_status(request: HttpRequest):
    check = requires_fields(request.POST, {"user_id": "int", "order_id": "int", "status": "str"})
    if check:
        return JsonResponse(check, status = 400)

    user_id = int(request.POST.get("user_id"))
    order_id = int(request.POST.get("order_id"))
    status = request.POST.get("status")

    try:
        user: UserCredentials = UserCredentials.objects.get(user_id = user_id)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    try:
        order: UserOrders = UserOrders.objects.get(order_id = order_id, user = user)
    except:
        return JsonResponse({"error": "Invalid order ID and user ID combination"}, status = 400)
    
    order.status = status
    order.save()
    
    return JsonResponse({"message": "Order status changed successfully"})

@request_type("POST")
def log_donation(request: HttpRequest):
    check = requires_fields(request.POST, {"name": "str", "email": "str", "amount": "float"})
    if check:
        return JsonResponse(check, status = 400)

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

@request_type("GET")
def get_donations(request: HttpRequest):
    check = requires_fields(request.GET, {"user_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user = request.user
    
    return JsonResponse({"data": list(user.user_donations.values("record_id", "name", "email", "amount", "created_at").order_by("created_at"))})