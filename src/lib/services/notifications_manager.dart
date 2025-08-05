import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart';

class NotificationsManager {
  static final alerts = [
    "Off",
    "30 minutes before",
    "2 hours before",
    "6 hours before",
  ];

  static final baseUrl =
      "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  static Future<void> subscribeAllNotifications(
    int user_id,
    String token,
    String reminders,
    bool announcements,
  ) async {
    try {
      FirebaseMessaging.instance.subscribeToTopic("ida-app-default");
      if (announcements) {
        FirebaseMessaging.instance.subscribeToTopic("ida-app-announcements");
      }

      var response = await get(
        Uri.parse(baseUrl + "/get-notifications?user_id=${user_id}"),
        headers: {"Authorization": "Bearer ${token}"},
      );
      Map info = jsonDecode(response.body);
      List notifs = info["data"];

      for (int event_id in notifs) {
        FirebaseMessaging.instance.subscribeToTopic("ida-event-${event_id}");

        FirebaseMessaging.instance.subscribeToTopic(
          "ida-event-${event_id}-${alerts.indexOf(reminders) - 1}",
        );
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<void> unsubscribeAllNotifications() async {
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (e) {
      print(e);
    }
  }

  static Future<void> subscribeNotification(
    int user_id,
    String token,
    int event_id,
    String reminders,
  ) async {
    try {
      post(
        Uri.parse(baseUrl + "/toggle-notification/"),
        headers: {"Authorization": "Bearer ${token}"},
        body: {"user_id": user_id.toString(), "event_id": event_id.toString()},
      );

      FirebaseMessaging.instance.subscribeToTopic("ida-event-${event_id}");

      if (reminders == "30 minutes before") {
        FirebaseMessaging.instance.subscribeToTopic("ida-event-${event_id}-0");
      } else if (reminders == "2 hours before") {
        FirebaseMessaging.instance.subscribeToTopic("ida-event-${event_id}-1");
      } else if (reminders == "6 hours before") {
        FirebaseMessaging.instance.subscribeToTopic("ida-event-${event_id}-2");
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<void> unsubscribeNotification(
    int user_id,
    String token,
    int event_id,
    String reminders,
  ) async {
    try {
      post(
        Uri.parse(baseUrl + "/toggle-notification/"),
        headers: {"Authorization": "Bearer ${token}"},
        body: {"user_id": user_id.toString(), "event_id": event_id.toString()},
      );

      FirebaseMessaging.instance.unsubscribeFromTopic("ida-event-${event_id}");

      if (reminders == "30 minutes before") {
        FirebaseMessaging.instance.unsubscribeFromTopic(
          "ida-event-${event_id}-0",
        );
      } else if (reminders == "2 hours before") {
        FirebaseMessaging.instance.unsubscribeFromTopic(
          "ida-event-${event_id}-1",
        );
      } else if (reminders == "6 hours before") {
        FirebaseMessaging.instance.unsubscribeFromTopic(
          "ida-event-${event_id}-2",
        );
      }
    } catch (e) {
      print(e);
    }
  }

  static Future<void> subscribeTopic(String topic) async {
    try {
      FirebaseMessaging.instance.subscribeToTopic(topic);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> unsubscribeTopic(String topic) async {
    try {
      FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    } catch (e) {
      print(e);
    }
  }

  static Future<void> changeInterval(
    int user_id,
    String token,
    String original_alert,
    String new_alert,
  ) async {
    try {
      var response = await get(
        Uri.parse(baseUrl + "/get-notifications?user_id=${user_id}"),
        headers: {"Authorization": "Bearer ${token}"},
      );
      Map info = jsonDecode(response.body);
      List notifs = info["data"];

      for (int event_id in notifs) {
        if (original_alert != "Off") {
          FirebaseMessaging.instance.unsubscribeFromTopic(
            "ida-event-${event_id}-${alerts.indexOf(original_alert) - 1}",
          );
        }

        if (new_alert != "Off") {
          FirebaseMessaging.instance.subscribeToTopic(
            "ida-event-${event_id}-${alerts.indexOf(new_alert) - 1}",
          );
        }
      }
    } catch (e) {
      print(e);
    }
  }
}
