from django.urls import path
from ida_app.views import *

urlpatterns = [
    path("", index),
    path("signup/", signup),
    path("verify-code/", verify_code),
    path("send-code/", send_code),
    path("change-password/", change_password),
    path("login/", login),
    path("add-event/", add_event),
    path("edit-event/", edit_event),
    path("delete-event/", delete_event),
    path("get-events/", get_events),
    path("toggle-notification/", toggle_notification),
    path("get-notifications/", get_notifications),
    path("change-settings/", change_settings),
    path("get-settings/", get_settings),
    path("change-name/", change_name),
    path("add-item/", add_item),
    path("edit-item/", edit_item),
    path("get-items/", get_items),
    path("delete-item/", delete_item),
    path("edit-cart/", edit_cart),
    path("get-cart/", get_cart),
]