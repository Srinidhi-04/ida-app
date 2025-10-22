import stripe
from asgiref.sync import sync_to_async
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

STRIPE_PUBLISH = os.getenv("STRIPE_PUBLISH_LIVE")

async def create_intent(amount: float):
    amount = int(amount * 100)
    if amount < 50:
        return {"error": "Amount must be at least $0.5"}

    payment_intent = await sync_to_async(stripe.PaymentIntent.create)(
        amount = amount,
        currency = "usd",
        payment_method_types = ["card"]
    )

    return {"message": "Stripe payment sheet successfully created", "payment_intent": payment_intent.client_secret, "payment_id": payment_intent.id, "publishable_key": STRIPE_PUBLISH}

@request_type("POST")
async def stripe_payment(request: HttpRequest):
    check = requires_fields(request.POST, {"amount": "float"})
    if check:
        return JsonResponse(check, status = 400)

    intent = await create_intent(float(request.POST.get("amount")))
    if "error" in intent:
        return JsonResponse(intent, status = 400)
    
    return JsonResponse(intent)

@request_type("POST")
async def start_order(request: HttpRequest):
    body: dict = json.loads(request.body)

    check = requires_fields(body, {"cart": "list", "amount": "float"})
    if check:
        return JsonResponse(check, status = 400)

    cart = body.get("cart")

    def async_transaction():
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
    
    error = await sync_to_async(async_transaction)()
    if isinstance(error, JsonResponse):
        return error

    intent = await create_intent(float(body.get("amount")))
    if "error" in intent:
        return JsonResponse(intent, status = 400)
    
    return JsonResponse(intent)

@request_type("POST")
async def cancel_order(request: HttpRequest):
    body: dict = json.loads(request.body)

    check = requires_fields(body, {"cart": "list"})
    if check:
        return JsonResponse(check, status = 400)

    cart = body.get("cart")

    def async_transaction():
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
    
    await sync_to_async(async_transaction)()

    return JsonResponse({"message": "Order cancelled successfully"})

@request_type("POST")
async def log_order(request: HttpRequest):
    body: dict = json.loads(request.body)

    check = requires_fields(body, {"value": "float", "payment_intent": "str", "cart": "list"})
    if check:
        return JsonResponse(check, status = 400)
    
    user: UserCredentials = request.user
    value = body.get("value")
    cart = body.get("cart")
    payment_intent = body.get("payment_intent")

    def async_transaction():
        try:
            with transaction.atomic():
                try:
                    order = UserOrders(user = user, value = value, payment_intent = payment_intent)
                    order.save()
                except:
                    raise Exception("An unknown error occurred with the database")
                
                try:
                    UserCarts.objects.filter(user = user).delete()
                except:
                    raise Exception("An unknown error occurred with the database")

                receipt = []
                for x in cart:
                    item_check = requires_fields(x, {"item_id": "int", "quantity": "int", "amount": "float"})
                    if item_check:
                        raise Exception(item_check["error"])

                    try:
                        item = ShopItems.objects.get(item_id = x["item_id"])
                        receipt.append({"name": item.name, "quantity": x["quantity"], "price": item.price, "amount": x["amount"], "image": item.image})
                    except:
                        raise Exception("An item with that item ID does not exist")
                    
                    try:
                        order_item = OrderItems(order = order, item = item, quantity = x["quantity"], subtotal = x["amount"])
                        order_item.save()
                    except:
                        raise Exception("An unknown error occurred with the database")
                    
                    return receipt, order
                    
        except Exception as e:
            return JsonResponse({"error": str(e)}, status = 400)
    
    ret = await sync_to_async(async_transaction)()
    if isinstance(ret, JsonResponse):
        return ret
    
    receipt, order = ret

    await send_order(user.name, user.email, value, receipt)

    return JsonResponse({"message": "Order placed successfully", "order_id": order.order_id, "date": order.created_at, "receipt": receipt, "status": order.status, "amount": order.value})

@request_type("GET")
async def get_orders(request: HttpRequest):
    check = requires_fields(request.GET, {"user_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user = request.user
    
    return JsonResponse({"data": await sync_to_async(list)(UserOrders.objects.filter(user = user).values("order_id", "value", "status", "created_at").order_by("created_at"))})

@request_type("GET")
async def get_order(request: HttpRequest):
    check = requires_fields(request.GET, {"order_user": "int", "order_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    order_user = int(request.GET.get("order_user"))
    order_id = int(request.GET.get("order_id"))

    if (request.user.user_id != order_user and request.user.role not in ["admin"]):
        return JsonResponse({"error": "Insufficient permissions"}, status = 400)

    try:
        user: UserCredentials = await UserCredentials.objects.prefetch_related("user_orders__order_items").aget(user_id = order_user)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    try:
        order: UserOrders = await user.user_orders.aget(order_id = order_id)
    except:
        return JsonResponse({"error": "Invalid order ID and user ID combination"}, status = 400)
    
    return JsonResponse({"data": {"order_id": order.order_id, "status": order.status, "amount": order.value, "date": order.created_at, "items": await sync_to_async(list)(order.order_items.annotate(name = F("item__name"), price = F("item__price"), image = F("item__image")).values("name", "price", "image", "quantity", "subtotal"))}})

@requires_roles(["admin", "merch"])
@request_type("POST")
async def change_status(request: HttpRequest):
    check = requires_fields(request.POST, {"order_user": "int", "order_id": "int", "status": "str"})
    if check:
        return JsonResponse(check, status = 400)

    order_user = int(request.POST.get("order_user"))
    order_id = int(request.POST.get("order_id"))
    status = request.POST.get("status")

    try:
        user: UserCredentials = await UserCredentials.objects.aget(user_id = order_user)
    except:
        return JsonResponse({"error": "A user with that user ID does not exist"}, status = 400)
    
    try:
        order: UserOrders = await UserOrders.objects.prefetch_related("order_items__item").aget(order_id = order_id, user = user)
    except:
        return JsonResponse({"error": "Invalid order ID and user ID combination"}, status = 400)
    
    order.status = status
    await order.asave()

    tokens = await sync_to_async(list)(UserTokens.objects.filter(user = user, type = "fcm"))

    if status == "Pending":
        await send_user_notification(user.user_id, tokens, "Order status changed", f"The order status for order #{order.order_id} has been changed to 'Pending'")
    elif status == "Delivered":
        await send_user_notification(user.user_id, tokens, "Order delivered!", f"Order #{order.order_id} has been delivered successfully!")
    else:
        refund = await asyncio.to_thread(lambda: stripe.Refund.create(payment_intent = order.payment_intent))
        await send_user_notification(user.user_id, tokens, "Order cancelled", f"Order #{order.order_id} has been cancelled and refunded  successfully")

        receipt = []
        order_items = await sync_to_async(list)(OrderItems.objects.filter(order = order).select_related("item"))
        for item in order_items:
            shop_item: ShopItems = item.item
            receipt.append({"name": shop_item.name, "quantity": item.quantity, "price": shop_item.price, "amount": item.subtotal})
        
        await send_refund(user.name, user.email, order.value, receipt)

        return JsonResponse({"message": "Order cancelled and refunded", "refund_id": refund.id})
    
    return JsonResponse({"message": "Order status changed successfully"})

@request_type("POST")
async def log_donation(request: HttpRequest):
    check = requires_fields(request.POST, {"name": "str", "email": "str", "amount": "float", "payment_intent": "str"})
    if check:
        return JsonResponse(check, status = 400)

    user: UserCredentials = request.user
    name = request.POST.get("name")
    email = request.POST.get("email")
    amount = float(request.POST.get("amount"))
    payment_intent = request.POST.get("payment_intent")

    try:
        receipt: DonationReceipts = DonationReceipts(user = user, name = name, email = email, amount = amount, payment_intent = payment_intent)
        await receipt.asave()

        await send_donation(name, email, amount)
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)

    return JsonResponse({"message": "Donation successfully logged"})

@request_type("GET")
async def get_donations(request: HttpRequest):
    check = requires_fields(request.GET, {"user_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

    user = request.user
    
    return JsonResponse({"data": await sync_to_async(list)(DonationReceipts.objects.filter(user = user).values("record_id", "name", "email", "amount", "created_at").order_by("created_at"))})