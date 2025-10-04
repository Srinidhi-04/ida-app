from django.http import HttpRequest, JsonResponse
from django.db import transaction
from django.db.models import F
from django.db.models.functions import Least
from ida_app.models import *
from ida_app.middleware import *

@requires_roles(["admin"])
@request_type("POST")
def add_item(request: HttpRequest):
    check = requires_fields(request.POST, {"name": "str", "price": "float", "inventory": "int"})
    if check:
        return JsonResponse(check, status = 400)

    name = request.POST.get("name")
    price = float(request.POST.get("price"))
    inventory = int(request.POST.get("inventory"))
    image = request.POST.get("image")
    if not image or image == "":
        image = "https://i.imgur.com/Mw85Kfp.png"
    
    try:
        item = ShopItems(name = name, price = price, image = image, inventory = inventory)
        item.save()
    except:
        return JsonResponse({"error": "An unknown error occurred with the database"}, status = 400)

    return JsonResponse({"message": "Item successfully added", "item_id": item.item_id})

@requires_roles(["admin"])
@request_type("POST")
def edit_item(request: HttpRequest):
    check = requires_fields(request.POST, {"item_id": "int", "name": "str", "price": "float", "inventory": "int"})
    if check:
        return JsonResponse(check, status = 400)

    item_id = int(request.POST.get("item_id"))
    name = request.POST.get("name")
    price = float(request.POST.get("price"))
    inventory = int(request.POST.get("inventory"))
    image = request.POST.get("image")
    if not image or image == "":
        image = "https://i.imgur.com/Mw85Kfp.png"

    try:
        with transaction.atomic():
            try:
                item = ShopItems.objects.select_for_update().get(item_id = item_id)
            except:
                raise Exception("An item with that item ID does not exist")

            item.name = name
            item.price = price
            item.image = image
            item.inventory = inventory
            item.save()

            item.item_carts.update(quantity = Least(F("quantity"), inventory))
    
    except Exception as e:
        return JsonResponse({"error": str(e)}, status = 400)

    return JsonResponse({"message": "Item successfully edited", "item_id": item.item_id})

@requires_roles(["admin"])
@request_type("POST")
def reduce_inventory(request: HttpRequest):
    check = requires_fields(request.POST, {"item_id": "int", "quantity": "int"})
    if check:
        return JsonResponse(check, status = 400)
    
    item_id = int(request.POST.get("item_id"))
    quantity = int(request.POST.get("quantity"))
    if quantity < 0:
        return JsonResponse({"error": "Quantity cannot be negative"}, status = 400)
    
    try:
        with transaction.atomic():
            try:
                item = ShopItems.objects.select_for_update().get(item_id = item_id)
            except:
                raise Exception("An item with that item ID does not exist")
            
            if item.inventory < quantity:
                ex = Exception("Not enough items in inventory to reduce")
                ex.inventory = item.inventory
                raise ex
            
            item.inventory -= quantity
            item.save()
                
    except Exception as e:
        err = {"error": str(e)}
        if hasattr(e, "inventory"):
            err["inventory"] = e.inventory

        return JsonResponse(err, status = 400)
    
    return JsonResponse({"message": "Inventory reduced successfully", "inventory": item.inventory})

@request_type("GET")
def get_items(request: HttpRequest):
    items = list(ShopItems.objects.values().order_by("item_id"))

    return JsonResponse({"data": items})

@requires_roles(["admin"])
@request_type("POST")
def delete_item(request: HttpRequest):
    check = requires_fields(request.POST, {"item_id": "int"})
    if check:
        return JsonResponse(check, status = 400)

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
        return JsonResponse(check, status = 400)

    user: UserCredentials = request.user
    item_id = int(request.POST.get("item_id"))
    quantity = int(request.POST.get("quantity"))

    try:
        item = ShopItems.objects.get(item_id = item_id)
    except:
        return JsonResponse({"error": "An item with that item ID does not exist"}, status = 400)

    if item.inventory < quantity:
        return JsonResponse({"error": "Not enough items in inventory"}, status = 400)

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

    cart = user.user_carts.all().select_related("item")
    cart_data = []
    for x in cart:
        if x.quantity > x.item.inventory:
            if x.item.inventory > 0:
                x.quantity = x.item.inventory
                x.save()
            else:
                x.delete()
        
        if x.quantity > 0:
            cart_data.append({"item_id": x.item.item_id, "quantity": x.quantity})

    return JsonResponse({"data": cart_data})

@request_type("GET")
def get_banner(request: HttpRequest):
    return JsonResponse({"message": "Order your Dads Weekend apparel now! Purchase your merch here: https://pogo.undergroundshirts.com/collections/illini-dads-weekend-2025"})