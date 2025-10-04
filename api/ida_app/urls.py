from django.urls import path
from ida_app.views.auth import *
from ida_app.views.events import *
from ida_app.views.shop import *
from ida_app.views.settings import *
from ida_app.views.announcements import *
from ida_app.views.payments import *
from ida_app.views.misc import *

urlpatterns = [
    path("", index),
    path("check-update", check_update),
    path("signup", signup),
    path("verify-code", verify_code),
    path("send-code", send_code),
    path("change-password", change_password),
    path("login", login),
    path("delete-account", delete_account),
    path("add-event", add_event),
    path("edit-event", edit_event),
    path("delete-event", delete_event),
    path("get-events", get_events),
    path("toggle-rsvp", toggle_rsvp),
    path("get-rsvp", get_rsvp),
    path("toggle-notification", toggle_notification),
    path("get-notifications", get_notifications),
    path("change-settings", change_settings),
    path("get-settings", get_settings),
    path("edit-profile", edit_profile),
    path("add-item", add_item),
    path("edit-item", edit_item),
    path("get-items", get_items),
    path("delete-item", delete_item),
    path("edit-cart", edit_cart),
    path("get-cart", get_cart),
    path("stripe-payment", stripe_payment),
    path("log-donation", log_donation),
    path("log-order", log_order),
    path("send-announcement", send_announcement),
    path("edit-role", edit_role),
    path("get-roles", get_roles),
    path("send-query", send_query),
    path("add-announcement", add_announcement),
    path("update-announcement", update_announcement),
    path("get-announcements", get_announcements),
    path("get-permissions", get_permissions),
    path("get-order", get_order),
    path("get-orders", get_orders),
    path("get-donations", get_donations),
    path("change-status", change_status),
    path("start-order", start_order),
    path("cancel-order", cancel_order),
    path("get-banner", get_banner),
]