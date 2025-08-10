import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';
import 'package:src/widgets/submit_overlay.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late int user_id;
  late String token;
  late String role;
  late String name;
  late int avatar;
  late String email;
  late String reminders;
  late bool announcements;

  bool loaded = false;
  bool submitted = false;

  List registered = [];
  List past = [];

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
  List<String> days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

  List<String> admin_roles = ["admin"];
  bool admin_access = false;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Widget profileButton(String name, String route) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      child: TextButton(
        style: ButtonStyle(visualDensity: VisualDensity.compact),
        onPressed: () {
          Navigator.pushNamed(context, route).then((_) => checkLogin());
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: Theme.of(context).typography.black.labelMedium!.apply(),
            ),
            Icon(Icons.keyboard_arrow_right_outlined, color: Colors.black),
          ],
        ),
      ),
    );
  }

  Widget eventCard(
    int event_id,
    String name,
    String location,
    DateTime date,
    String image,
    String body,
    String ticket,
    LatLng coordinates,
    bool featured,
    bool rsvp,
    bool past,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Card(
          elevation: 5,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                "/event",
                arguments: {
                  "image": image,
                  "date": date,
                  "location": location,
                  "title": name,
                  "body": body,
                  "ticket": ticket,
                  "event_id": event_id,
                  "rsvp": rsvp,
                  "latitude": coordinates.latitude,
                  "longitude": coordinates.longitude,
                  "featured": featured,
                  "past": past,
                },
              ).then((_) => checkLogin());
            },
            style: ButtonStyle(
              padding: WidgetStatePropertyAll(EdgeInsets.zero),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image(
                      width: MediaQuery.of(context).size.width * 0.2,
                      height: 200,
                      image: NetworkImage(image),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  "${days[date.weekday - 1]}, ${months[date.month - 1]} ${(date.day < 10) ? 0 : ""}${date.day} • ${(date.hour % 12 < 10 && date.hour % 12 != 0) ? 0 : ""}${(date.hour % 12 == 0) ? 12 : date.hour % 12}:${(date.minute < 10) ? 0 : ""}${date.minute} ${(date.hour >= 12) ? "PM" : "AM"}",
                                  style: Theme.of(
                                    context,
                                  ).typography.white.labelSmall!.apply(
                                    color: Theme.of(context).primaryColorLight,
                                  ),
                                ),
                              ),
                              Text(
                                name,
                                style: Theme.of(
                                  context,
                                ).typography.black.labelLarge!.apply(
                                  color: Theme.of(context).primaryColorDark,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  Container(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          0.3 *
                                              MediaQuery.of(
                                                context,
                                              ).size.width -
                                          20,
                                    ),
                                    child: Text(
                                      location,
                                      style: Theme.of(
                                        context,
                                      ).typography.black.labelSmall!.apply(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    "/map",
                                    arguments: {"coordinates": coordinates},
                                  );
                                },
                                child: Text(
                                  "View on map",
                                  style:
                                      Theme.of(
                                        context,
                                      ).typography.white.labelSmall,
                                ),
                                style: ButtonStyle(
                                  backgroundColor: WidgetStatePropertyAll(
                                    Theme.of(context).primaryColorDark,
                                  ),
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> getEvents() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-rsvp?user_id=${user_id}"),
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

    List all_events = info["data"];

    List upcoming = [];
    List old = [];

    for (int i = 0; i < all_events.length; i++) {
      all_events[i]["coordinates"] = LatLng(
        all_events[i]["latitude"],
        all_events[i]["longitude"],
      );
      all_events[i]["date"] = DateTime.parse(all_events[i]["date"]).toLocal();

      if (all_events[i]["completed"]) {
        old.add(all_events[i]);
      } else {
        upcoming.add(all_events[i]);
      }
    }

    setState(() {
      registered = upcoming;
      past = old;
      loaded = true;
    });
  }

  Future<void> getPermissions() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-permissions?category=roles&user_id=${user_id}"),
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
      admin_roles = info["data"]["roles"].cast<String>();
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
      email = info["email"]!;
      name = info["name"]!;
      avatar = int.parse(info["avatar"]!);
      role = info["role"]!;
      reminders = info["reminders"]!;
      announcements = bool.parse(info["announcements"]!);
    });
    await Future.wait([getEvents(), getPermissions()]);
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

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              "Profile",
              style: Theme.of(
                context,
              ).typography.white.headlineMedium!.apply(fontWeightDelta: 3),
            ),
            backgroundColor: Theme.of(context).primaryColorDark,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          backgroundColor: Theme.of(context).primaryColorDark,
          body: RefreshIndicator(
            onRefresh: () async {
              await checkLogin();
            },
            color: Theme.of(context).primaryColorLight,
            backgroundColor: Colors.white,
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                color: Colors.white,
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                  minHeight:
                      MediaQuery.of(context).size.height -
                      kToolbarHeight -
                      MediaQuery.of(context).padding.top -
                      kBottomNavigationBarHeight,
                ),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Column(
                          children: [
                            Container(
                              color: Theme.of(context).primaryColorDark,
                              width: MediaQuery.of(context).size.width,
                              height: 100,
                            ),
                            Container(
                              color: Colors.white,
                              width: MediaQuery.of(context).size.width,
                              height: 75,
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap:
                              () => Navigator.pushNamed(
                                context,
                                "/settings",
                              ).then((_) => checkLogin()),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            width: 150,
                            height: 150,
                            child: Padding(
                              padding: const EdgeInsets.all(5.0),
                              child: Image(
                                image: AssetImage(
                                  "assets/avatars/avatar_${avatar}.png",
                                ),
                                width: 140,
                                height: 140,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    (role != "user")
                        ? Padding(
                          padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                          child: Text(
                            role.substring(0, 1).toUpperCase() +
                                role.substring(1),
                            style:
                                Theme.of(context).typography.black.labelSmall,
                          ),
                        )
                        : SizedBox.shrink(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
                      child: Text(
                        name,
                        style: Theme.of(context).typography.black.labelMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
                      child: Text(
                        email,
                        style: Theme.of(context).typography.black.labelMedium,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          (registered.isNotEmpty || past.isNotEmpty)
                              ? Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  0,
                                  10,
                                  0,
                                  10,
                                ),
                                child: Text(
                                  "Event Participation",
                                  style: Theme.of(context)
                                      .typography
                                      .black
                                      .labelLarge!
                                      .apply(fontWeightDelta: 3),
                                ),
                              )
                              : SizedBox.shrink(),
                          (registered.isNotEmpty)
                              ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      5,
                                      0,
                                      0,
                                      5,
                                    ),
                                    child: Text(
                                      "Registered",
                                      style:
                                          Theme.of(
                                            context,
                                          ).typography.black.labelMedium,
                                    ),
                                  ),
                                  Column(
                                    children:
                                        registered
                                            .map(
                                              (e) => eventCard(
                                                e["event_id"],
                                                e["name"],
                                                e["location"],
                                                e["date"],
                                                e["image"],
                                                e["body"],
                                                e["ticket"],
                                                e["coordinates"],
                                                e["essential"],
                                                true,
                                                e["completed"],
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              )
                              : SizedBox.shrink(),

                          (past.isNotEmpty)
                              ? Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      5,
                                      0,
                                      0,
                                      5,
                                    ),
                                    child: Text(
                                      "Past",
                                      style:
                                          Theme.of(
                                            context,
                                          ).typography.black.labelMedium,
                                    ),
                                  ),
                                  Column(
                                    children:
                                        past
                                            .map(
                                              (e) => eventCard(
                                                e["event_id"],
                                                e["name"],
                                                e["location"],
                                                e["date"],
                                                e["image"],
                                                e["body"],
                                                e["ticket"],
                                                e["coordinates"],
                                                e["essential"],
                                                true,
                                                e["completed"],
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ],
                              )
                              : SizedBox.shrink(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          profileButton(
                            "Notification Settings",
                            "/notifications",
                          ),
                          Divider(
                            color: Theme.of(context).primaryColor,
                            indent: 20,
                            endIndent: 20,
                          ),
                          profileButton("Profile Settings", "/settings"),
                          (admin_roles.contains(role) || admin_access)
                              ? Divider(
                                color: Theme.of(context).primaryColor,
                                indent: 20,
                                endIndent: 20,
                              )
                              : SizedBox.shrink(),
                          (admin_roles.contains(role) || admin_access)
                              ? profileButton("Assign Roles", "/roles")
                              : SizedBox.shrink(),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: TextButton(
                        onPressed: () async {
                          setState(() {
                            submitted = true;
                          });

                          await NotificationsManager.unsubscribeAllNotifications();
                          await SecureStorage.delete();
                          await Navigator.of(
                            context,
                          ).pushNamedAndRemoveUntil("/login", (route) => false);
                        },
                        child: Text(
                          "LOG OUT",
                          style: Theme.of(context).typography.white.labelLarge!
                              .apply(fontSizeDelta: 2, fontWeightDelta: 3),
                        ),
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Theme.of(context).primaryColor,
                          ),
                          fixedSize: WidgetStatePropertyAll(
                            Size(0.7 * MediaQuery.of(context).size.width, 50),
                          ),
                          elevation: WidgetStatePropertyAll(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).pushNamed("/help");
            },
            child: Icon(Icons.help_outline),
            backgroundColor: Theme.of(context).primaryColorDark,
            foregroundColor: Theme.of(context).primaryColorLight,
            shape: CircleBorder(),
          ),
          bottomNavigationBar: Navigation(selected: 4),
        ),
        SubmitOverlay(submitted: submitted),
      ],
    );
  }
}
