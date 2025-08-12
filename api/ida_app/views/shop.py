from django.http import HttpRequest, JsonResponse
from ida_app.models import *
from ida_app.middleware import *

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