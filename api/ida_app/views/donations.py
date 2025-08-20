import stripe
from django.http import HttpRequest, JsonResponse
from ida_app.tasks import *
from ida_app.models import *
from ida_app.middleware import *
import os
# from dotenv import load_dotenv

# load_dotenv()

STRIPE_PUBLISH = os.getenv("STRIPE_PUBLISH_TEST")

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

    return JsonResponse({"message": "Stripe payment sheet successfully created", "payment_intent": payment_intent.client_secret, "publishable_key": STRIPE_PUBLISH})

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