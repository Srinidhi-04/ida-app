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

DEBUG = False

if not DEBUG:
    STRIPE_PUBLISH = os.getenv("STRIPE_PUBLISH_LIVE")
else:
    STRIPE_PUBLISH = os.getenv("STRIPE_PUBLISH_TEST")

merch_roles = ["admin", "merch"]

async def create_intent(amount: float):
    try:
        amount = int(amount * 100)
        if amount < 50:
            return {"error": "Amount must be at least $0.5"}

        payment_intent = await sync_to_async(stripe.PaymentIntent.create)(
            amount = amount,
            currency = "usd",
            payment_method_types = ["card"]
        )

        return {"message": "Stripe payment sheet successfully created", "payment_intent": payment_intent.client_secret, "payment_id": payment_intent.id, "publishable_key": STRIPE_PUBLISH}
    except Exception as e:
        return {"error": str(e)}

@request_type("POST")
async def stripe_payment(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"amount": "float"})
        if check:
            return JsonResponse(check, status = 400)

        intent = await create_intent(float(request.POST.get("amount")))
        if "error" in intent:
            return JsonResponse(intent, status = 400)
        
        return JsonResponse(intent)
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def start_order(request: HttpRequest):
    try:
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
                        except ObjectDoesNotExist:
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
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def cancel_order(request: HttpRequest):
    try:
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
                        except ObjectDoesNotExist:
                            raise Exception("An item with that item ID does not exist")
                        
                        item.inventory += x["quantity"]
                        item.save()
                        
            except Exception as e:
                return JsonResponse({"error": str(e)}, status = 400)
        
        await sync_to_async(async_transaction)()

        return JsonResponse({"message": "Order cancelled successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def log_order(request: HttpRequest):
    try:
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
                    order = UserOrders(user = user, value = value, payment_intent = payment_intent)
                    order.save()
                    
                    UserCarts.objects.filter(user = user).delete()

                    receipt = []
                    for x in cart:
                        item_check = requires_fields(x, {"name": "str", "price": "float", "image": "str", "quantity": "int", "amount": "float"})
                        if item_check:
                            raise Exception(item_check["error"])

                        receipt.append({"name": x["name"], "quantity": x["quantity"], "price": x["price"], "amount": x["amount"], "image": x["image"]})
                        
                        order_item = OrderItems(order = order, name = x["name"], quantity = x["quantity"], price = x["price"], quantity = x["quantity"], subtotal = x["amount"])
                        order_item.save()
                        
                    return receipt, order
                        
            except Exception as e:
                return JsonResponse({"error": str(e)}, status = 400)
        
        ret = await sync_to_async(async_transaction)()
        if isinstance(ret, JsonResponse):
            return ret
        
        receipt, order = ret

        await send_order(user.name, user.email, value, receipt)

        return JsonResponse({"message": "Order placed successfully", "order_id": order.order_id, "date": order.created_at, "receipt": receipt, "status": order.status, "amount": order.value})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("GET")
async def get_orders(request: HttpRequest):
    try:
        check = requires_fields(request.GET, {"user_id": "int"})
        if check:
            return JsonResponse(check, status = 400)

        user = request.user
        
        return JsonResponse({"data": await sync_to_async(list)(UserOrders.objects.filter(user = user).values("order_id", "value", "status", "created_at").order_by("created_at"))})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("GET")
async def get_order(request: HttpRequest):
    try:
        check = requires_fields(request.GET, {"order_user": "int", "order_id": "int"})
        if check:
            return JsonResponse(check, status = 400)

        order_user = int(request.GET.get("order_user"))
        order_id = int(request.GET.get("order_id"))

        if (request.user.user_id != order_user and request.user.role not in merch_roles):
            return JsonResponse({"error": "Insufficient permissions"}, status = 400)

        try:
            user: UserCredentials = await UserCredentials.objects.prefetch_related("user_orders__order_items").aget(user_id = order_user)
        except ObjectDoesNotExist:
            raise Exception("A user with that user ID does not exist")
        
        try:
            order: UserOrders = await user.user_orders.aget(order_id = order_id)
        except ObjectDoesNotExist:
            raise Exception("Invalid order ID and user ID combination")
        
        return JsonResponse({"data": {"order_id": order.order_id, "status": order.status, "amount": order.value, "date": order.created_at, "items": await sync_to_async(list)(order.order_items.values("name", "price", "image", "quantity", "subtotal"))}})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@requires_roles(["admin", "merch"])
@request_type("POST")
async def change_status(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"order_user": "int", "order_id": "int", "status": "str"})
        if check:
            return JsonResponse(check, status = 400)

        order_user = int(request.POST.get("order_user"))
        order_id = int(request.POST.get("order_id"))
        status = request.POST.get("status")

        try:
            user: UserCredentials = await UserCredentials.objects.aget(user_id = order_user)
        except ObjectDoesNotExist:
            raise Exception("A user with that user ID does not exist")
        
        try:
            order: UserOrders = await UserOrders.objects.prefetch_related("order_items").aget(order_id = order_id, user = user)
        except ObjectDoesNotExist:
            raise Exception("Invalid order ID and user ID combination")
        
        order.status = status
        await order.asave()

        tokens = await sync_to_async(list)(UserTokens.objects.filter(user = user, type = "fcm"))

        settings: UserSettings = await UserSettings.objects.aget(user = user)
        if status == "Pending" and settings.status:
            await send_user_notification(user.user_id, tokens, "Order status changed", f"The order status for order #{order.order_id} has been changed to 'Pending'")
        elif status == "Delivered" and settings.status:
            await send_user_notification(user.user_id, tokens, "Order delivered!", f"Order #{order.order_id} has been delivered successfully!")
        else:
            refund = await asyncio.to_thread(lambda: stripe.Refund.create(payment_intent = order.payment_intent))
            if settings.status:
                await send_user_notification(user.user_id, tokens, "Order cancelled", f"Order #{order.order_id} has been cancelled and refunded successfully")

            receipt = []
            order_items = await sync_to_async(list)(order.order_items.all())
            for item in order_items:
                receipt.append({"name": item.name, "quantity": item.quantity, "price": item.price, "amount": item.subtotal})
            
            await send_refund(user.name, user.email, order.value, receipt)

            return JsonResponse({"message": "Order cancelled and refunded", "refund_id": refund.id})
        
        return JsonResponse({"message": "Order status changed successfully"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("POST")
async def log_donation(request: HttpRequest):
    try:
        check = requires_fields(request.POST, {"name": "str", "email": "str", "amount": "float", "payment_intent": "str"})
        if check:
            return JsonResponse(check, status = 400)

        user: UserCredentials = request.user
        name = request.POST.get("name")
        email = request.POST.get("email")
        amount = float(request.POST.get("amount"))
        payment_intent = request.POST.get("payment_intent")

        receipt: DonationReceipts = DonationReceipts(user = user, name = name, email = email, amount = amount, payment_intent = payment_intent)
        await receipt.asave()

        await send_donation(name, email, amount)

        return JsonResponse({"message": "Donation successfully logged"})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

@request_type("GET")
async def get_donations(request: HttpRequest):
    try:
        check = requires_fields(request.GET, {"user_id": "int"})
        if check:
            return JsonResponse(check, status = 400)

        user = request.user
        
        return JsonResponse({"data": await sync_to_async(list)(DonationReceipts.objects.filter(user = user).values("record_id", "name", "email", "amount", "created_at").order_by("created_at"))})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)