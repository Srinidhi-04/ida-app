import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late int user_id;
  late String token;
  bool loaded = false;

  Map notifs = {
    "announcements": true,
    "updates": true,
    "merch": true,
    "status": true,
  };

  Map<String, String> aliases = {
    "announcements": "General Announcements",
    "updates": "Ticket Updates",
    "merch": "New Merchandise",
    "status": "Order Status",
  };

  String alert = "Off";
  List<String> alerts = [
    "Off",
    "30 minutes before",
    "2 hours before",
    "6 hours before",
  ];

  late String original_alert;

  bool changed = false;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Widget notificationOption(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          aliases[name]!,
          style: Theme.of(context).typography.black.labelLarge,
        ),
        Switch(
          thumbColor: WidgetStatePropertyAll(Colors.white),
          activeTrackColor: Colors.green,
          inactiveTrackColor: Theme.of(context).primaryColor,
          value: notifs[name]!,
          onChanged:
              (value) => setState(() {
                notifs[name] = value;
                changed = true;
              }),
        ),
      ],
    );
  }

  Future<void> getSettings() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-settings?user_id=${user_id}"),
      headers: {"Authorization": "Bearer ${token}"},
    );
    Map info = jsonDecode(response.body);
    if (info.containsKey("error") &&
        info["error"] == "Invalid authorization token") {
      await NotificationsManager.unsubscribeAllNotifications();
      await SecureStorage.delete();
      await Navigator.of(
        context,
      ).pushNamedAndRemoveUntil("/login", (route) => false);
      return;
    }

    setState(() {
      alert = info["data"]!.remove("reminders");
      original_alert = alert;
      info["data"]!.remove("user_id");
      notifs = info["data"];
      loaded = true;
      changed = false;
    });
  }

  Future<void> checkLogin() async {
    Map<String, String> info = await SecureStorage.read();
    if (info["last_login"] != null) {
      DateTime date = DateTime.parse(info["last_login"]!);
      if (DateTime.now().subtract(Duration(days: 30)).compareTo(date) >= 0) {
        await NotificationsManager.unsubscribeAllNotifications();
        await SecureStorage.delete();
        await Navigator.of(
          context,
        ).pushNamedAndRemoveUntil("/login", (route) => false);
        return;
      }
    }
    if (info["user_id"] == null) {
      await Navigator.popAndPushNamed(context, "/login");
      return;
    }

    setState(() {
      user_id = int.parse(info["user_id"]!);
      token = info["token"]!;
    });
    await getSettings();
  }

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    if (!loaded)
      return Scaffold(
        body: Center(
          child: LoadingAnimationWidget.inkDrop(
            color: Theme.of(context).primaryColorLight,
            size: 100,
          ),
        ),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Manage Notifications",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await checkLogin();
        },
        color: Theme.of(context).primaryColorLight,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Container(
            constraints: BoxConstraints(
              minWidth: MediaQuery.of(context).size.width,
              minHeight:
                  MediaQuery.of(context).size.height -
                  kToolbarHeight -
                  kBottomNavigationBarHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(30, 0, 30, 0),
              child: Column(
                children: [
                  Divider(color: Theme.of(context).primaryColor),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children:
                        notifs.keys.map((e) => notificationOption(e)).toList(),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Event Reminders",
                        style: Theme.of(context).typography.black.labelLarge,
                      ),
                      DropdownButton(
                        value: alert,
                        icon: const Icon(Icons.swap_vert),
                        elevation: 16,
                        style: Theme.of(context).typography.black.labelMedium,
                        dropdownColor: Colors.white,
                        onChanged: (String? value) {
                          setState(() {
                            alert = value!;
                            changed = true;
                          });
                        },
                        items:
                            alerts.map<DropdownMenuItem<String>>((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  (changed)
                      ? Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: TextButton(
                          onPressed: () async {
                            setState(() {
                              changed = false;
                            });
                            var response = await post(
                              Uri.parse(baseUrl + "/change-settings/"),
                              headers: {"Authorization": "Bearer ${token}"},
                              body: {
                                "user_id": user_id.toString(),
                                "announcements":
                                    (notifs["announcements"]) ? "yes" : "no",
                                "updates": (notifs["updates"]) ? "yes" : "no",
                                "merch": (notifs["merch"]) ? "yes" : "no",
                                "status": (notifs["status"]) ? "yes" : "no",
                                "reminders": alert,
                              },
                            );
                            Map info = jsonDecode(response.body);
                            if (info.containsKey("error") &&
                                info["error"] ==
                                    "Invalid authorization token") {
                              await NotificationsManager.unsubscribeAllNotifications();
                              await SecureStorage.delete();
                              await Navigator.of(
                                context,
                              ).pushNamedAndRemoveUntil(
                                "/login",
                                (route) => false,
                              );
                              return;
                            }

                            if (notifs["announcements"]) {
                              NotificationsManager.subscribeTopic(
                                "ida-app-announcements",
                              );
                            } else {
                              NotificationsManager.unsubscribeTopic(
                                "ida-app-announcements",
                              );
                            }

                            if (alert != original_alert) {
                              SecureStorage.writeOne("reminders", alert);

                              NotificationsManager.changeInterval(
                                user_id,
                                token,
                                original_alert,
                                alert,
                              );
                            }
                          },
                          child: Text(
                            "Save",
                            style: Theme.of(context)
                                .typography
                                .white
                                .labelLarge!
                                .apply(fontSizeDelta: 2, fontWeightDelta: 3),
                          ),
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Theme.of(context).primaryColor,
                            ),
                            fixedSize: WidgetStatePropertyAll(
                              Size(0.6 * MediaQuery.of(context).size.width, 50),
                            ),
                            elevation: WidgetStatePropertyAll(10),
                          ),
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Navigation(selected: 4),
    );
  }
}
