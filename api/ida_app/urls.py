from django.urls import path
from ida_app.views import *

urlpatterns = [
    path("", index),
    path("signup/", signup),
    path("verify-code/", verify_code),
    path("resend-code/", resend_code),
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
]