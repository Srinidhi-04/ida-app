import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/notifications_manager.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/cart_button.dart';
import 'package:src/widgets/navigation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carousel_slider/carousel_slider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late int user_id;
  late String token;
  late String role;

  List<String> months = [
    "JAN",
    "FEB",
    "MAR",
    "APR",
    "MAY",
    "JUN",
    "JUL",
    "AUG",
    "SEP",
    "OCT",
    "NOV",
    "DEC",
  ];

  List<Map> events = [];

  Map<int, int> quantity = {};

  bool loaded = false;
  bool? loadingEvents;

  PageController dialog_controller = PageController();

  List<String> admin_roles = ["admin"];
  bool admin_access = false;

  String baseUrl = "https://ida-app-api-afb7906d4986.herokuapp.com/ida-app";

  Widget mainButton(Color color, String text, String path, bool external) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: TextButton(
        onPressed: () {
          if (external)
            launchUrl(Uri.parse(path), mode: LaunchMode.inAppBrowserView);
          else
            Navigator.of(context).pushNamed(path);
        },
        child: Text(
          text,
          style: Theme.of(
            context,
          ).typography.white.labelMedium!.apply(fontWeightDelta: 3),
        ),
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(color),
          foregroundColor: WidgetStatePropertyAll(Colors.white),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          minimumSize: WidgetStatePropertyAll(Size(100, 40)),
        ),
      ),
    );
  }

  Widget eventCard(
    int event_id,
    DateTime date,
    String title,
    String location,
    String image,
    String body,
    String ticket,
    double latitude,
    double longitude,
    bool featured,
    bool rsvp,
    bool past,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: Container(
        width: 300,
        height: 350,
        child: TextButton(
          style: ButtonStyle(
            padding: WidgetStatePropertyAll(EdgeInsets.zero),
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          onPressed: () {
            Navigator.pushNamed(
              context,
              "/event",
              arguments: {
                "image": image,
                "date": date,
                "location": location,
                "title": title,
                "body": body,
                "ticket": ticket,
                "event_id": event_id,
                "rsvp": rsvp,
                "latitude": latitude,
                "longitude": longitude,
                "featured": featured,
                "past": past,
              },
            ).then((_) {
              getEvents();
            });
          },
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.topLeft,
                    children: [
                      Container(
                        width: 280,
                        height: 160,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(image),
                            fit: BoxFit.cover,
                          ),
                          //color: Color(0xFFFFCD6C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Color(0xBBFFFFFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                date.day.toString(),
                                style: Theme.of(context)
                                    .typography
                                    .white
                                    .labelLarge!
                                    .apply(color: Color(0xFFFF6007)),
                              ),
                              Text(
                                months[date.month - 1],
                                style: Theme.of(
                                  context,
                                ).typography.white.labelSmall!.apply(
                                  color: Color(0xFFFF6007),
                                  fontSizeDelta: -2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 2.0),
                            child: Text(
                              title,
                              style: Theme.of(context)
                                  .typography
                                  .black
                                  .headlineSmall!
                                  .apply(fontWeightDelta: 3),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: Theme.of(context).primaryColor,
                              ),
                              Text(
                                location,
                                style: Theme.of(
                                  context,
                                ).typography.black.labelMedium!.apply(
                                  color: Theme.of(context).primaryColor,
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
    setState(() {
      if (loadingEvents == null) loadingEvents = true;
    });

    var response = await get(
      Uri.parse(baseUrl + "/get-events?completed=no&user_id=${user_id}"),
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

    List<Map> new_events = [];
    for (var event in all_events) {
      new_events.add({
        "event_id": event["event_id"],
        "date": DateTime.parse(event["date"]).toLocal(),
        "title": event["name"],
        "location": event["location"],
        "image": event["image"],
        "body": event["body"],
        "ticket": event["ticket"],
        "latitude": event["latitude"],
        "longitude": event["longitude"],
        "featured": event["essential"],
        "rsvp": event["rsvp"],
        "past": event["completed"],
      });
    }

    setState(() {
      events = new_events;
      loadingEvents = false;
    });
  }

  Future<void> getCart() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-cart?user_id=${user_id}"),
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

    List data = info["data"];

    Map<int, int> cart = {};
    for (var item in data) {
      cart[item["item_id"]] = item["quantity"];
    }

    setState(() {
      quantity = cart;
    });
  }

  Future<void> getPermissions() async {
    var response = await get(
      Uri.parse(
        baseUrl + "/get-permissions?category=announcements&user_id=${user_id}",
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
      admin_roles = info["data"]["roles"].cast<String>();
      admin_access = info["data"]["access"];
    });
  }

  Future<void> getAnnouncements() async {
    var response = await get(
      Uri.parse(baseUrl + "/get-announcements?user_id=${user_id}"),
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

    List data = info["data"];

    Map<int, List> announcements = {};
    int last_announcement = 0;
    for (var announcement in data) {
      announcements[announcement["announcement_id"]] = [
        announcement["title"],
        announcement["body"],
      ];
      if (announcement["announcement_id"] > last_announcement) {
        last_announcement = announcement["announcement_id"];
      }
    }

    if (data.isNotEmpty) {
      showDialog(
        context: context,
        builder: (dialogContext) {
          int page = 1;

          return StatefulBuilder(
            builder: (stateContext, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                actionsAlignment: MainAxisAlignment.spaceBetween,
                title: Text(
                  "Announcements",
                  style: Theme.of(context).typography.black.headlineMedium,
                ),
                content: Container(
                  height: MediaQuery.of(context).size.height * 0.2,
                  width: double.maxFinite,
                  child: PageView.builder(
                    controller: dialog_controller,
                    itemCount: data.length,
                    onPageChanged:
                        (value) => setDialogState(() {
                          page = value + 1;
                        }),
                    itemBuilder: (BuildContext pageContext, int index) {
                      return SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                data[index]["title"],
                                style: Theme.of(context)
                                    .typography
                                    .black
                                    .labelLarge!
                                    .apply(fontWeightDelta: 3),
                              ),
                            ),
                            Text(
                              data[index]["body"],
                              style: Theme.of(context)
                                  .typography
                                  .black
                                  .bodyMedium!
                                  .apply(fontSizeDelta: 2),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                actions: [
                  Text(
                    "${page} of ${data.length}",
                    style: Theme.of(
                      context,
                    ).typography.black.labelMedium!.apply(fontSizeDelta: 2),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    child: Text(
                      "Close",
                      style: Theme.of(
                        context,
                      ).typography.black.labelMedium!.apply(fontSizeDelta: 2),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ).then((value) async {
        await post(
          Uri.parse(baseUrl + "/update-announcement"),
          headers: {"Authorization": "Bearer ${token}"},
          body: {
            "user_id": user_id.toString(),
            "last_announcement": last_announcement.toString(),
          },
        );
      });
    }
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
    await Future.wait([
      getCart(),
      getEvents(),
      getAnnouncements(),
      getPermissions(),
    ]);
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
      appBar: AppBar(
        title: Image(image: AssetImage("assets/logo.png"), height: 40),
        actions: [CartButton(quantity: quantity, callback: () => getCart())],
        centerTitle: true,
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
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Column(
                      children: [
                        Image(
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.cover,
                          image: AssetImage("assets/pages/home_1.png"),
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          mainButton(
                            Theme.of(context).primaryColorDark,
                            "Tickets",
                            "https://www.gofevo.com/group/Illinidads",
                            true,
                          ),
                          mainButton(
                            Theme.of(context).primaryColorLight,
                            "Donate",
                            "/donate",
                            false,
                          ),
                          mainButton(
                            Theme.of(context).primaryColorDark,
                            "Shop",
                            "/shop",
                            false,
                          ),
                          mainButton(
                            Theme.of(context).primaryColorLight,
                            "About Us",
                            "/about",
                            false,
                          ),
                          mainButton(
                            Theme.of(context).primaryColorDark,
                            "Board",
                            "/board",
                            false,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upcoming Events",
                        style: Theme.of(context).typography.black.headlineSmall,
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, "/events");
                        },
                        label: Text(
                          "See All",
                          style: Theme.of(context).typography.black.labelMedium!
                              .apply(color: Theme.of(context).primaryColor),
                        ),
                        icon: Icon(Icons.arrow_right_rounded),
                        iconAlignment: IconAlignment.end,
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.transparent,
                          ),
                          foregroundColor: WidgetStatePropertyAll(
                            Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                (loadingEvents == null || loadingEvents!)
                    ? LoadingAnimationWidget.staggeredDotsWave(
                      color: Theme.of(context).primaryColorLight,
                      size: 50,
                    )
                    : events.isNotEmpty
                    ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children:
                            events
                                .map(
                                  (e) => eventCard(
                                    e["event_id"],
                                    e["date"],
                                    e["title"],
                                    e["location"],
                                    e["image"],
                                    e["body"],
                                    e["ticket"],
                                    e["latitude"],
                                    e["longitude"],
                                    e["featured"],
                                    e["rsvp"],
                                    e["past"],
                                  ),
                                )
                                .toList(),
                      ),
                    )
                    : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "No upcoming events",
                        style: Theme.of(context).typography.black.headlineSmall,
                      ),
                    ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Text(
                      "Image Gallery",
                      style: Theme.of(context).typography.black.headlineSmall,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: CarouselSlider.builder(
                    options: CarouselOptions(
                      height: 200,
                      enlargeCenterPage: true,
                      autoPlay: true,
                    ),
                    itemCount: 18,
                    itemBuilder:
                        (
                          BuildContext context,
                          int itemIndex,
                          int pageViewIndex,
                        ) => Image(
                          height: 400,
                          width: MediaQuery.of(context).size.width * 0.7,
                          fit: BoxFit.cover,
                          image: AssetImage(
                            "assets/gallery/image_${itemIndex + 1}.png",
                          ),
                        ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image(
                            image: AssetImage("assets/pages/home_2.jpeg"),
                            color: Color(0x88000000),
                            colorBlendMode: BlendMode.darken,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "DADS PLAZA",
                                  style: Theme.of(
                                    context,
                                  ).typography.white.labelLarge!.apply(
                                    color: Theme.of(context).primaryColorLight,
                                    fontWeightDelta: 3,
                                  ),
                                ),
                                SizedBox(height: 20),
                                TextButton(
                                  onPressed: () async {
                                    await launchUrl(
                                      Uri.parse(
                                        "https://www.illinidads.com/centennial-plaza",
                                      ),
                                      mode: LaunchMode.inAppBrowserView,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      5,
                                      0,
                                      5,
                                      0,
                                    ),
                                    child: Text(
                                      "Learn More",
                                      style: Theme.of(context)
                                          .typography
                                          .white
                                          .labelMedium!
                                          .apply(fontWeightDelta: 3),
                                    ),
                                  ),
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStatePropertyAll(
                                      Theme.of(context).primaryColorLight,
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
                            Container(
                              width: MediaQuery.of(context).size.width / 2.5,
                              child: Text(
                                "Illini Dads Centennial Plaza honors the role and impact that father figures have in the lives of their Illini students",
                                style: Theme.of(context)
                                    .typography
                                    .white
                                    .bodyMedium!
                                    .apply(fontSizeDelta: 2),
                                textAlign: TextAlign.center,
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
      floatingActionButton:
          (admin_roles.contains(role) || admin_access)
              ? FloatingActionButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed("/announcement").then((_) async => checkLogin());
                },
                child: Icon(Icons.campaign_outlined),
                backgroundColor: Theme.of(context).primaryColorDark,
                foregroundColor: Theme.of(context).primaryColorLight,
                shape: CircleBorder(),
              )
              : null,
      bottomNavigationBar: Navigation(selected: 0),
    );
  }
}
