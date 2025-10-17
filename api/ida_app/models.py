from django.db import models
import asyncio
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
import random as rd

class UserManager(BaseUserManager):
    async def create_user(self, email, name, password, **kwargs):
        if not email:
            raise ValueError("'email' field is required")
        if not name:
            raise ValueError("'name' field is required")
        if not password:
            raise ValueError("'password' field is required")

        email = self.normalize_email(email).lower()

        while True:
            code = rd.randint(100000, 999999)
            try:
                await UserCredentials.objects.aget(signup_code = code)
            except:
                break

        user: UserCredentials = self.model(email = email, name = name, signup_code = code, **kwargs)
        user.set_password(password)

        try:
            await user.asave(using = self._db)
        except:
            raise Exception("A user with that email already exists")

        return user
    
    def create_superuser(self, email, name, password, **kwargs):
        kwargs.setdefault("role", "admin")
        kwargs.setdefault("is_superuser", True)

        try:
            loop = asyncio.get_running_loop()
        except:
            loop = None
        
        if loop and loop.is_running():
            return loop.run_until_complete(self.create_user(email, name, password, **kwargs))
        
        return asyncio.run(self.create_user(email, name, password, **kwargs))

    async def create_admin(self, email, name, password, **kwargs):
        kwargs.setdefault("role", "admin")
        return await self.create_user(email, name, password, **kwargs)


class UserCredentials(AbstractBaseUser, PermissionsMixin):
    user_id = models.AutoField(primary_key = True, unique = True, null = False)
    email = models.EmailField(unique = True, null = False)
    name = models.TextField(unique = False, null = False)
    avatar = models.IntegerField(unique = False, null = False)
    role = models.TextField(default = "user", null = False)
    mailing = models.BooleanField(default = True, null = False)
    last_announcement = models.IntegerField(default = 0, null = False)
    signup_code = models.IntegerField(unique = True, null = True)
    forgot_code = models.IntegerField(unique = True, null = True)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)

    USERNAME_FIELD = "email"

    objects: UserManager = UserManager()


class UserTokens(models.Model):
    token_id = models.AutoField(primary_key = True, unique = True, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user_tokens", on_delete = models.CASCADE, null = False)
    token = models.CharField(max_length = 64, unique = True, null = False)
    expires_at = models.DateTimeField(unique = False, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class Events(models.Model):
    event_id = models.AutoField(primary_key = True, unique = True, null = False)
    name = models.TextField(unique = False, null = False)
    date = models.DateTimeField(unique = False, null = False)
    location = models.TextField(unique = False, null = False)
    latitude = models.FloatField(unique = False, null = False)
    longitude = models.FloatField(unique = False, null = False)
    image = models.TextField(default = "https://i.imgur.com/Mw85Kfp.png", null = False)
    body = models.TextField(unique = False, null = False)
    completed = models.BooleanField(default = False, null = False)
    essential = models.BooleanField(default = False, null = False)
    ticket = models.TextField(unique = False, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class UserNotifications(models.Model):
    notification_id = models.AutoField(primary_key = True, unique = True, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user_notifications", on_delete = models.CASCADE, null = False)
    event = models.ForeignKey(Events, related_name = "event_notifications", on_delete = models.CASCADE, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class UserSettings(models.Model):
    user = models.OneToOneField(UserCredentials, related_name = "user_settings", on_delete = models.CASCADE, primary_key = True, null = False)
    announcements = models.BooleanField(default = True, null = False)
    updates = models.BooleanField(default = True, null = False)
    merch = models.BooleanField(default = True, null = False)
    status = models.BooleanField(default = True, null = False)
    reminders = models.TextField(choices = [("Off", "Off"), ("30 minutes before", "30 minutes before"), ("2 hours before", "2 hours before"), ("6 hours before", "6 hours before")], default = "30 minutes before", null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class ShopItems(models.Model):
    item_id = models.AutoField(primary_key = True, unique = True, null = False)
    name = models.TextField(unique = False, null = False)
    price = models.FloatField(unique = False, null = False)
    image = models.TextField(default = "https://i.imgur.com/Mw85Kfp.png", null = False)
    inventory = models.IntegerField(default = 0, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)

class UserCarts(models.Model):
    record_id = models.AutoField(primary_key = True, unique = True, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user_carts", on_delete = models.CASCADE, null = False)
    item = models.ForeignKey(ShopItems, related_name = "item_carts", on_delete = models.CASCADE, null = False)
    quantity = models.IntegerField(unique = False, null = True)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class EventRsvp(models.Model):
    record_id = models.AutoField(primary_key = True, unique = True, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user_rsvp", on_delete = models.CASCADE, null = False)
    event = models.ForeignKey(Events, related_name = "event_rsvp", on_delete = models.CASCADE, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class DonationReceipts(models.Model):
    record_id = models.AutoField(primary_key = True, unique = True, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user_donations", on_delete = models.CASCADE, null = False)
    name = models.TextField(unique = False, null = False)
    email = models.TextField(unique = False, null = False)
    amount = models.FloatField(unique = False, null = False)
    payment_intent = models.TextField(unique = True, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class BannerAnnouncements(models.Model):
    announcement_id = models.AutoField(primary_key = True, unique = True, null = False)
    title = models.TextField(unique = False, null = False)
    body = models.TextField(unique = False, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class UserOrders(models.Model):
    order_id = models.AutoField(primary_key = True, unique = True, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user_orders", on_delete = models.CASCADE, null = False)
    value = models.FloatField(unique = False, null = False)
    status = models.TextField(choices = [("Pending", "Pending"), ("Delivered", "Delivered"), ("Cancelled", "Cancelled")], default = "Pending", null = False)
    payment_intent = models.TextField(unique = True, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)


class OrderItems(models.Model):
    oitem_id = models.AutoField(primary_key = True, unique = True, null = False)
    order = models.ForeignKey(UserOrders, related_name = "order_items", on_delete = models.CASCADE, null = False)
    item = models.ForeignKey(ShopItems, related_name = "item_orders", on_delete = models.CASCADE, null = False)
    quantity = models.IntegerField(unique = False, null = True)
    subtotal = models.FloatField(unique = False, null = False)
    created_at = models.DateTimeField(auto_now_add = True)
    updated_at = models.DateTimeField(auto_now = True)