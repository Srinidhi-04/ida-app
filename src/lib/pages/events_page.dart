import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  late int user_id;
  late String token;
  late String role;
  late String reminders;
  List<bool> loaded = [false, false];

  int selected = 0;
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
  Map<String, List> upcoming = {"all": [], "essential": []};
  List<Map> past = [];
  List notifs = [];

  bool searching = false;
  String search = "";

  List<String> admin_roles = ["admin"];
  bool admin_access = false;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Widget switchOption(int index, String text) {
    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: TextButton(
        onPressed: () {
          setState(() {
            selected = index;
          });
        },
        child: Text(
          text,
          style: Theme.of(context).typography.black.labelMedium!.apply(
            fontWeightDelta: 3,
            color:
                (selected == index)
                    ? Theme.of(context).primaryColorLight
                    : Color(0xFF707372),
          ),
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            (selected == index) ? Colors.white : Colors.transparent,
          ),
          foregroundColor: WidgetStatePropertyAll(
            (selected == index)
                ? Theme.of(context).primaryColorLight
                : Color(0xFF707372),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          overlayColor: WidgetStatePropertyAll(Colors.transparent),
          minimumSize: WidgetStatePropertyAll(
            Size(MediaQuery.of(context).size.width * 0.3, 40),
          ),
        ),
      ),
    );
  }

  Widget eventCard(
    int index,
    int event_id,
    String name,
    String location,
    DateTime date,
    String image,
    String body,
    String ticket,
    LatLng coordinates,
    int type,
    bool featured,
    bool rsvp,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: Slidable(
          key: ValueKey(event_id),
          enabled: (admin_roles.contains(role) || admin_access),
          endActionPane: ActionPane(
            motion: BehindMotion(),
            dismissible: DismissiblePane(
              onDismissed: () async {
                setState(() {
                  if (type == 0) {
                    upcoming["all"]!.removeAt(index);
                  } else if (type == 1) {
                    upcoming["essential"]!.removeAt(index);
                  } else {
                    past.removeAt(index);
                  }
                });
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
                    info["error"] == "Invalid authorization token") {
                  await NotificationsManager.unsubscribeAllNotifications();
                  await SecureStorage.delete();
                  await Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil("/login", (route) => false);
                  return;
                }

                getEvents();
                getNotifications();
              },
            ),
            children: [
              CustomSlidableAction(
                onPressed: (slideContext) async {
                  Navigator.of(context)
                      .pushNamed(
                        "/manage",
                        arguments: {
                          "event_id": event_id,
                          "name": name,
                          "date": date,
                          "location": location,
                          "latitude": coordinates.latitude,
                          "longitude": coordinates.longitude,
                          "image": image,
                          "body": body,
                          "ticket": ticket,
                          "featured": featured,
                        },
                      )
                      .then((_) => checkLogin());
                },
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: Icon(Icons.edit_outlined, size: 50),
              ),
              CustomSlidableAction(
                onPressed: (slideContext) async {
                  setState(() {
                    if (type == 0) {
                      upcoming["all"]!.removeAt(index);
                    } else if (type == 1) {
                      upcoming["essential"]!.removeAt(index);
                    } else {
                      past.removeAt(index);
                    }
                  });
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
                      info["error"] == "Invalid authorization token") {
                    await NotificationsManager.unsubscribeAllNotifications();
                    await SecureStorage.delete();
                    await Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil("/login", (route) => false);
                    return;
                  }

                  getEvents();
                  getNotifications();
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                borderRadius: BorderRadius.circular(10),
                child: Icon(Icons.delete_outline, size: 50),
              ),
            ],
          ),
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
                    "past": (type == 2),
                  },
                ).then((_) => checkLogin());
              },
              style: ButtonStyle(
                padding: WidgetStatePropertyAll(EdgeInsets.zero),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        0.8 *
                                            MediaQuery.of(context).size.width -
                                        120,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 10.0,
                                        ),
                                        child: Text(
                                          "${days[date.weekday - 1]}, ${months[date.month - 1]} ${(date.day < 10) ? 0 : ""}${date.day} • ${(date.hour % 12 < 10 && date.hour % 12 != 0) ? 0 : ""}${(date.hour % 12 == 0) ? 12 : date.hour % 12}:${(date.minute < 10) ? 0 : ""}${date.minute} ${(date.hour >= 12) ? "PM" : "AM"}",
                                          style: Theme.of(
                                            context,
                                          ).typography.white.labelSmall!.apply(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).primaryColorLight,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        name,
                                        style: Theme.of(
                                          context,
                                        ).typography.black.labelLarge!.apply(
                                          color:
                                              Theme.of(
                                                context,
                                              ).primaryColorDark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                (type != 2)
                                    ? IconButton(
                                      onPressed: () async {
                                        setState(() {
                                          if (notifs.contains(event_id))
                                            notifs.remove(event_id);
                                          else
                                            notifs.add(event_id);
                                        });

                                        if (notifs.contains(event_id)) {
                                          NotificationsManager.subscribeNotification(
                                            user_id,
                                            token,
                                            event_id,
                                            reminders,
                                          );
                                        } else {
                                          NotificationsManager.unsubscribeNotification(
                                            user_id,
                                            token,
                                            event_id,
                                            reminders,
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        (notifs.contains(event_id))
                                            ? Icons.notifications_active
                                            : Icons.notification_add,
                                      ),
                                      color:
                                          (notifs.contains(event_id))
                                              ? Theme.of(
                                                context,
                                              ).primaryColorDark
                                              : Theme.of(
                                                context,
                                              ).primaryColorLight,
                                      iconSize: 30,
                                      style: ButtonStyle(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    )
                                    : SizedBox.shrink(),
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
                                            MediaQuery.of(context).size.width,
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
      ),
    );
  }

  Future<void> getEvents() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-events?user_id=${user_id}"),
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

    List<Map> all_past = [];
    List<Map> all_new = [];
    List<Map> essential = [];
    for (int i = 0; i < all_events.length; i++) {
      all_events[i]["coordinates"] = LatLng(
        all_events[i]["latitude"],
        all_events[i]["longitude"],
      );
      all_events[i]["date"] = DateTime.parse(all_events[i]["date"]).toLocal();

      if (all_events[i]["completed"])
        all_past.add(all_events[i]);
      else {
        all_new.add(all_events[i]);
        if (all_events[i]["essential"]) essential.add(all_events[i]);
      }
    }

    setState(() {
      past = all_past;
      upcoming = {"all": all_new, "essential": essential};
      loaded[0] = true;
    });
  }

  Future<void> getNotifications() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-notifications?user_id=${user_id}"),
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
      notifs = info["data"];
      loaded[1] = true;
    });
  }

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

    await SecureStorage.writeOne("role", info["data"]["role"]);

    setState(() {
      admin_roles = info["data"]["roles"].cast<String>();
      admin_access = info["data"]["access"];
      role = info["data"]["role"];
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
      reminders = info["reminders"]!;
    });
    await Future.wait([getNotifications(), getEvents(), getPermissions()]);
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
    if (loaded.contains(false))
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
          "Events",
          style: Theme.of(context).typography.black.headlineMedium!.apply(
            color: Theme.of(context).primaryColorDark,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                searching = !searching;
                if (!searching) {
                  search = "";
                }
              });
            },
            icon: Icon(
              Icons.search_outlined,
              color: Theme.of(context).primaryColorDark,
              size: 32,
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await checkLogin();
        },
        color: Theme.of(context).primaryColorLight,
        backgroundColor: Colors.white,
        child: Column(
          children: [
            (searching)
                ? Padding(
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 10),
                  child: TextFormField(
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        Icons.search_outlined,
                        color: Theme.of(context).primaryColor,
                      ),
                      hintText: "Search",
                    ),
                    cursorColor: Theme.of(context).primaryColor,
                    onChanged:
                        (value) => setState(() {
                          search = value.trim();
                        }),
                  ),
                )
                : SizedBox.shrink(),
            Expanded(
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight:
                        MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        MediaQuery.of(context).padding.top -
                        kBottomNavigationBarHeight,
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Color(0xFFC8C6C7),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              switchOption(0, "UPCOMING"),
                              switchOption(1, "PAST"),
                            ],
                          ),
                        ),
                      ),
                      ((selected == 0 &&
                                  upcoming["essential"]!.isNotEmpty &&
                                  !searching) ||
                              (selected == 0 &&
                                  searching &&
                                  upcoming["essential"]!
                                      .where(
                                        (e) => (e["name"]
                                            .toLowerCase()
                                            .contains(search.toLowerCase())),
                                      )
                                      .isNotEmpty))
                          ? Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Don't Miss These",
                                style: Theme.of(
                                  context,
                                ).typography.black.labelLarge!.apply(
                                  color: Theme.of(context).primaryColorDark,
                                  fontWeightDelta: 3,
                                ),
                              ),
                            ),
                          )
                          : SizedBox.shrink(),
                      (selected == 0 && upcoming["essential"]!.isNotEmpty)
                          ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children:
                                ((searching &&
                                        upcoming["essential"]!
                                            .where(
                                              (e) => (e["name"]
                                                  .toLowerCase()
                                                  .contains(
                                                    search.toLowerCase(),
                                                  )),
                                            )
                                            .isEmpty)
                                    ? [SizedBox.shrink()]
                                    : upcoming["essential"]!
                                        .where(
                                          (e) =>
                                              (!searching ||
                                                  e["name"]
                                                      .toLowerCase()
                                                      .contains(
                                                        search.toLowerCase(),
                                                      )),
                                        )
                                        .map(
                                          (e) => eventCard(
                                            upcoming["essential"]!.indexOf(e),
                                            e["event_id"],
                                            e["name"],
                                            e["location"],
                                            e["date"],
                                            e["image"],
                                            e["body"],
                                            e["ticket"],
                                            e["coordinates"],
                                            1,
                                            e["essential"],
                                            e["rsvp"],
                                          ),
                                        )
                                        .toList()),
                          )
                          : SizedBox.shrink(),
                      ((selected == 0 &&
                                  upcoming["all"]!.isNotEmpty &&
                                  !searching) ||
                              selected == 0 &&
                                  searching &&
                                  upcoming["all"]!
                                      .where(
                                        (e) => (e["name"]
                                            .toLowerCase()
                                            .contains(search.toLowerCase())),
                                      )
                                      .isNotEmpty)
                          ? Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "All Events",
                                style: Theme.of(
                                  context,
                                ).typography.black.labelLarge!.apply(
                                  color: Theme.of(context).primaryColorDark,
                                  fontWeightDelta: 3,
                                ),
                              ),
                            ),
                          )
                          : SizedBox.shrink(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children:
                            (selected == 0)
                                ? ((upcoming["all"]!.isEmpty)
                                    ? [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                          ),
                                          child: Text(
                                            "No upcoming events",
                                            style:
                                                Theme.of(context)
                                                    .typography
                                                    .black
                                                    .headlineLarge,
                                          ),
                                        ),
                                      ),
                                    ]
                                    : (searching &&
                                        upcoming["all"]!
                                            .where(
                                              (e) => (e["name"]
                                                  .toLowerCase()
                                                  .contains(
                                                    search.toLowerCase(),
                                                  )),
                                            )
                                            .isEmpty)
                                    ? [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                          ),
                                          child: Text(
                                            "No matching events",
                                            style:
                                                Theme.of(context)
                                                    .typography
                                                    .black
                                                    .headlineLarge,
                                          ),
                                        ),
                                      ),
                                    ]
                                    : upcoming["all"]!
                                        .where(
                                          (e) =>
                                              (!searching ||
                                                  e["name"]
                                                      .toLowerCase()
                                                      .contains(
                                                        search.toLowerCase(),
                                                      )),
                                        )
                                        .map(
                                          (e) => eventCard(
                                            upcoming["all"]!.indexOf(e),
                                            e["event_id"],
                                            e["name"],
                                            e["location"],
                                            e["date"],
                                            e["image"],
                                            e["body"],
                                            e["ticket"],
                                            e["coordinates"],
                                            0,
                                            e["essential"],
                                            e["rsvp"],
                                          ),
                                        )
                                        .toList())
                                : ((past.isEmpty)
                                    ? [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                          ),
                                          child: Text(
                                            "No past events",
                                            style:
                                                Theme.of(context)
                                                    .typography
                                                    .black
                                                    .headlineLarge,
                                          ),
                                        ),
                                      ),
                                    ]
                                    : (searching &&
                                        past
                                            .where(
                                              (e) => (e["name"]
                                                  .toLowerCase()
                                                  .contains(
                                                    search.toLowerCase(),
                                                  )),
                                            )
                                            .isEmpty)
                                    ? [
                                      Center(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 20,
                                          ),
                                          child: Text(
                                            "No matching events",
                                            style:
                                                Theme.of(context)
                                                    .typography
                                                    .black
                                                    .headlineLarge,
                                          ),
                                        ),
                                      ),
                                    ]
                                    : past
                                        .where(
                                          (e) =>
                                              (!searching ||
                                                  e["name"]
                                                      .toLowerCase()
                                                      .contains(
                                                        search.toLowerCase(),
                                                      )),
                                        )
                                        .map(
                                          (e) => eventCard(
                                            past.indexOf(e),
                                            e["event_id"],
                                            e["name"],
                                            e["location"],
                                            e["date"],
                                            e["image"],
                                            e["body"],
                                            e["ticket"],
                                            e["coordinates"],
                                            2,
                                            e["essential"],
                                            e["rsvp"],
                                          ),
                                        )
                                        .toList()),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          (admin_roles.contains(role) || admin_access)
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed("/manage").then((_) => checkLogin());
                },
                child: Icon(Icons.add_rounded),
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Theme.of(context).primaryColorLight,
                shape: CircleBorder(),
              )
              : null,
      bottomNavigationBar: Navigation(selected: 1),
    );
  }
}
