// ignore_for_file: must_be_immutable

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';
import 'package:url_launcher/url_launcher.dart';

class EventPage extends StatefulWidget {
  EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late int user_id;
  late String token;
  late String role;
  bool loaded = false;
  bool initialized = false;

  late int event_id;
  late String image;
  late DateTime date;
  late String location;
  late String title;
  late String body;
  late String ticket;
  late double latitude;
  late double longitude;
  late bool featured;
  late bool rsvp;
  late bool past;

  List<String> months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];

  List<String> admin_roles = ["admin"];
  bool admin_access = false;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Future<void> getPermissions() async {
    var response = await get(
      Uri.parse(
        baseUrl + "/get-permissions?category=events&user_id=${user_id}",
      ),
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
      admin_roles = info["data"]["roles"];
      admin_access = info["data"]["access"];
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
      role = info["role"]!;
      loaded = true;
    });
    await getPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!initialized) {
      Map args = ModalRoute.of(context)!.settings.arguments as Map;
      setState(() {
        event_id = args["event_id"];
        image = args["image"];
        date = args["date"];
        location = args["location"];
        title = args["title"];
        body = args["body"];
        ticket = args["ticket"];
        latitude = args["latitude"];
        longitude = args["longitude"];
        featured = args["featured"];
        rsvp = args["rsvp"];
        past = args["past"];
        initialized = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkLogin();
    });
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Event Details",
          style: Theme.of(
            context,
          ).typography.black.headlineMedium!.apply(color: Colors.white),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions:
            (admin_roles.contains(role) || admin_access)
                ? [
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert),
                    color: Theme.of(context).primaryColorLight,
                    itemBuilder:
                        (popupContext) => [
                          PopupMenuItem(
                            onTap: () {
                              Navigator.of(context)
                                  .pushNamed(
                                    "/manage",
                                    arguments: {
                                      "event_id": event_id,
                                      "name": title,
                                      "date": date,
                                      "location": location,
                                      "latitude": latitude,
                                      "longitude": longitude,
                                      "image": image,
                                      "body": body,
                                      "ticket": ticket,
                                      "featured": featured,
                                    },
                                  )
                                  .then((value) {
                                    if (value != null) {
                                      List args = value as List;
                                      setState(() {
                                        title = args[0];
                                        date = args[1];
                                        location = args[2];
                                        latitude = args[3];
                                        longitude = args[4];
                                        image = args[5];
                                        body = args[6];
                                        ticket = args[7];
                                        featured = args[8];
                                        past =
                                            (args[1].compareTo(
                                                  DateTime.now(),
                                                ) <=
                                                0);
                                      });
                                    }
                                  });
                            },
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  "Edit",
                                  style:
                                      Theme.of(
                                        context,
                                      ).typography.white.labelMedium,
                                ),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            onTap: () async {
                              var response = await post(
                                Uri.parse(baseUrl + "/delete-event"),
                                headers: {"Authorization": "Bearer ${token}"},
                                body: {
                                  "user_id": user_id.toString(),
                                  "event_id": event_id.toString(),
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

                              Navigator.pop(context);
                            },
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 5),
                                Text(
                                  "Delete",
                                  style:
                                      Theme.of(
                                        context,
                                      ).typography.white.labelMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ]
                : [],
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          RefreshIndicator(
            onRefresh: () async {
              await checkLogin();
            },
            color: Theme.of(context).primaryColorLight,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      kBottomNavigationBarHeight,
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: 0.3 * MediaQuery.of(context).size.height,
                          width: MediaQuery.of(context).size.width,
                          color: Theme.of(context).primaryColorDark,
                          child: Image(
                            image: NetworkImage(image),
                            fit: BoxFit.contain,
                          ),
                        ),
                        Container(
                          color: Theme.of(
                            context,
                          ).primaryColorDark.withAlpha(150),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.3,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 5,
                                            ),
                                            child: Icon(
                                              Icons.event_available_outlined,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "${date.day} ${months[date.month - 1]}, ${date.year}",
                                            style: Theme.of(context)
                                                .typography
                                                .white
                                                .labelMedium!
                                                .apply(fontWeightDelta: 3),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 5,
                                            ),
                                            child: Icon(
                                              Icons.alarm_outlined,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            "${(date.hour % 12 < 10 && date.hour % 12 > 0) ? "0" : ""}${(date.hour % 12 == 0) ? "12" : date.hour % 12}:${(date.minute < 10 ? "0" : "")}${date.minute} ${(date.hour < 12) ? "AM" : "PM"}",
                                            style: Theme.of(context)
                                                .typography
                                                .white
                                                .labelMedium!
                                                .apply(fontWeightDelta: 3),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      "/map",
                                      arguments: {
                                        "coordinates": LatLng(
                                          latitude,
                                          longitude,
                                        ),
                                      },
                                    );
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 5,
                                        ),
                                        child: Icon(
                                          Icons.location_on_outlined,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "${location}",
                                        style: Theme.of(context)
                                            .typography
                                            .white
                                            .labelMedium!
                                            .apply(fontWeightDelta: 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsets.all(20),
                      child: Container(
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context)
                                  .typography
                                  .black
                                  .headlineMedium!
                                  .apply(fontWeightDelta: 3),
                            ),
                            SizedBox(height: 20),
                            Text(
                              "About the event",
                              style: Theme.of(context)
                                  .typography
                                  .black
                                  .labelLarge!
                                  .apply(fontWeightDelta: 3),
                            ),
                            SizedBox(height: 20),
                            Text(
                              body,
                              style: Theme.of(context)
                                  .typography
                                  .black
                                  .bodyMedium!
                                  .apply(fontSizeDelta: 2),
                            ),
                            SizedBox(height: 50),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          (!past)
              ? (ticket == "")
                  ? Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          rsvp = !rsvp;
                        });

                        var response = await post(
                          Uri.parse(baseUrl + "/toggle-rsvp"),
                          headers: {"Authorization": "Bearer ${token}"},
                          body: {
                            "user_id": user_id.toString(),
                            "event_id": event_id.toString(),
                          },
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
                      },
                      child: Text(
                        (!rsvp) ? "RSVP" : "UNREGISTER",
                        style: Theme.of(context).typography.white.labelMedium!
                            .apply(fontSizeDelta: 2, fontWeightDelta: 3),
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStatePropertyAll(
                          (!rsvp)
                              ? Theme.of(context).primaryColorLight
                              : Theme.of(context).primaryColor,
                        ),
                        fixedSize: WidgetStatePropertyAll(
                          Size(0.6 * MediaQuery.of(context).size.width, 50),
                        ),
                        elevation: WidgetStatePropertyAll(10),
                      ),
                    ),
                  )
                  : Padding(
                    padding: const EdgeInsets.only(bottom: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: ElevatedButton(
                            onPressed: () async {
                              setState(() {
                                rsvp = !rsvp;
                              });

                              var response = await post(
                                Uri.parse(baseUrl + "/toggle-rsvp"),
                                headers: {"Authorization": "Bearer ${token}"},
                                body: {
                                  "user_id": user_id.toString(),
                                  "event_id": event_id.toString(),
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
                            },
                            child: Text(
                              (!rsvp) ? "RSVP" : "UNREGISTER",
                              style: Theme.of(context)
                                  .typography
                                  .white
                                  .labelMedium!
                                  .apply(fontSizeDelta: 2, fontWeightDelta: 3),
                            ),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                (!rsvp)
                                    ? Theme.of(context).primaryColorLight
                                    : Theme.of(context).primaryColor,
                              ),
                              fixedSize: WidgetStatePropertyAll(
                                Size(
                                  0.45 * MediaQuery.of(context).size.width,
                                  50,
                                ),
                              ),
                              elevation: WidgetStatePropertyAll(10),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: ElevatedButton(
                            onPressed: () {
                              launchUrl(
                                Uri.parse(ticket),
                                mode: LaunchMode.inAppBrowserView,
                              );
                            },
                            child: Text(
                              "BUY TICKET",
                              style: Theme.of(
                                context,
                              ).typography.white.labelMedium!.apply(
                                fontSizeDelta: 2,
                                fontWeightDelta: 3,
                                color: Theme.of(context).primaryColorLight,
                              ),
                            ),
                            style: ButtonStyle(
                              backgroundColor: WidgetStatePropertyAll(
                                Colors.white,
                              ),
                              fixedSize: WidgetStatePropertyAll(
                                Size(
                                  0.45 * MediaQuery.of(context).size.width,
                                  50,
                                ),
                              ),
                              elevation: WidgetStatePropertyAll(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
              : SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: Navigation(selected: 1),
    );
  }
}
