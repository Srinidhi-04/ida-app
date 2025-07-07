from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
import random as rd

class UserManager(BaseUserManager):
    def create_user(self, email, name, password, **kwargs):
        if not email:
            raise ValueError("'email' field is required")
        if not name:
            raise ValueError("'name' field is required")
        if not password:
            raise ValueError("'password' field is required")

        email = self.normalize_email(email)
        email.lower()

        while True:
            code = rd.randint(100000, 999999)
            try:
                UserCredentials.objects.get(signup_code = code)
            except:
                break

        user: UserCredentials = self.model(email = email, name = name, signup_code = code, **kwargs)
        user.set_password(password)

        try:
            user.save(using = self._db)
        except:
            raise Exception("A user with that email already exists")

        return user
    
    def create_superuser(self, email, name, password, **kwargs):
        kwargs.setdefault("admin", True)
        kwargs.setdefault("is_superuser", True)
        return self.create_user(email, name, password, **kwargs)
    
    def create_admin(self, email, name, password, **kwargs):
        kwargs.setdefault("admin", True)
        return self.create_user(email, name, password, **kwargs)


class UserCredentials(AbstractBaseUser, PermissionsMixin):
    user_id = models.AutoField(primary_key = True, unique = True, null = False)
    email = models.EmailField(unique = True, null = False)
    name = models.TextField(unique = False, null = False)
    admin = models.BooleanField(default = False, null = False)
    signup_code = models.IntegerField(unique = True, null = True)
    forgot_code = models.IntegerField(unique = True, null = True)
    token = models.CharField(max_length = 50, unique = True, null = True)

    USERNAME_FIELD = "email"

    objects: UserManager = UserManager()


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


class UserNotifications(models.Model):
    notification_id = models.AutoField(primary_key = True, unique = True, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user_notifications", on_delete = models.CASCADE, null = False)
    event = models.ForeignKey(Events, related_name = "event_notifications", on_delete = models.CASCADE, null = False)


class UserSettings(models.Model):
    user = models.OneToOneField(UserCredentials, related_name = "user_settings", on_delete = models.CASCADE, primary_key = True, null = False)
    announcements = models.BooleanField(default = True, null = False)
    updates = models.BooleanField(default = True, null = False)
    merch = models.BooleanField(default = True, null = False)
    status = models.BooleanField(default = True, null = False)
    reminders = models.TextField(choices = [("Off", "Off"), ("30 minutes before", "30 minutes before"), ("2 hours before", "2 hours before"), ("6 hours before", "6 hours before")], default = "30 minutes before", null = False)


class ShopItems(models.Model):
    item_id = models.AutoField(primary_key = True, unique = True, null = False)
    name = models.TextField(unique = False, null = False)
    price = models.FloatField(unique = False, null = False)
    image = models.TextField(default = "https://i.imgur.com/Mw85Kfp.png", null = False)

class UserCarts(models.Model):
    record_id = models.AutoField(primary_key = True, unique = True, null = False)
    user = models.ForeignKey(UserCredentials, related_name = "user_carts", on_delete = models.CASCADE, null = False)
    item = models.ForeignKey(ShopItems, related_name = "item_carts", on_delete = models.CASCADE, null = False)
    quantity = models.IntegerField(unique = False, null = True)