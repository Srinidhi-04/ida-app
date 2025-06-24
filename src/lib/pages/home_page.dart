import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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

  bool loadingEvents = false;

  String baseUrl = "https://0112-223-185-130-192.ngrok-free.app/ida-app";

  Widget mainButton(Color color, String text, String route) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      child: TextButton(
        onPressed: () {},
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
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Container(
        width: 240,
        height: 300,
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
                "event_id": event_id,
              },
            );
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
                        width: 220,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Color(0xFFFFCD6C),
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
      loadingEvents = true;
    });

    var response = await get(Uri.parse(baseUrl + "/get-events?completed=no"));
    Map info = jsonDecode(response.body);
    List all_events = info["data"];

    List<Map> new_events = [];
    for (var event in all_events) {
      new_events.add({
        "event_id": event["event_id"],
        "date": DateTime.parse(event["date"]),
        "title": event["name"],
        "location": event["location"],
        "image": event["image"],
        "body": event["body"],
      });
    }

    setState(() {
      events = new_events;
      loadingEvents = false;
    });
  }

  Future<void> checkLogin() async {
    Map<String, String> info = await SecureStorage.read();
    if (info["last_login"] != null) {
      DateTime date = DateTime.parse(info["last_login"]!);
      if (DateTime.now().subtract(Duration(days: 30)).compareTo(date) >= 0) {
        await SecureStorage.delete();
        await Navigator.popAndPushNamed(context, "/login");
        return;
      }
    }
    if (info["user_id"] == null)
      await Navigator.popAndPushNamed(context, "/login");
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    checkLogin();
    getEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {},
          icon: Icon(Icons.search, size: 28),
        ),
        title: Image(
          image: NetworkImage("https://i.imgur.com/0FHQKN4.png"),
          height: 40,
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.shopping_cart_outlined, size: 28),
          ),
        ],
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await getEvents();
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
                          image: NetworkImage(
                            "https://i.imgur.com/JE2eR3M.png",
                          ),
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
                            "/tickets",
                          ),
                          mainButton(
                            Theme.of(context).primaryColorLight,
                            "Donate",
                            "/donate",
                          ),
                          mainButton(
                            Theme.of(context).primaryColorDark,
                            "Shop",
                            "/shop",
                          ),
                          mainButton(
                            Theme.of(context).primaryColorLight,
                            "About Us",
                            "/about",
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
                loadingEvents ? LoadingAnimationWidget.staggeredDotsWave(color: Theme.of(context).primaryColorLight, size: 50) : events.isNotEmpty
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
                            image: NetworkImage(
                              "https://i.imgur.com/UGnaS5X.jpeg",
                            ),
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
                                  onPressed: () {},
                                  child: Text(
                                    "Learn More",
                                    style:
                                        Theme.of(
                                          context,
                                        ).typography.white.labelMedium,
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
      bottomNavigationBar: Navigation(selected: 0),
    );
  }
}
