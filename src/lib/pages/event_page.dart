// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:src/services/secure_storage.dart';
import 'package:src/widgets/navigation.dart';

class EventPage extends StatefulWidget {
  EventPage({super.key});

  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  late bool admin;
  bool loaded = false;
  bool initialized = false;

  late int event_id;
  late String image;
  late DateTime date;
  late String location;
  late String title;
  late String body;
  late Function callback;
  late double latitude;
  late double longitude;
  late bool featured;

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

  String baseUrl = "https://0112-223-185-130-192.ngrok-free.app/ida-app";

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
    if (info["user_id"] == null) {
      await Navigator.popAndPushNamed(context, "/login");
      return;
    }

    setState(() {
      admin = bool.parse(info["admin"]!);
      loaded = true;
    });
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
        callback = args["callback"];
        latitude = args["latitude"];
        longitude = args["longitude"];
        featured = args["featured"];
        initialized = true;
      });
    }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          "Event Details",
          style: Theme.of(context).typography.white.headlineMedium!,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions:
            (admin)
                ? [
                  PopupMenuButton(
                    color: Theme.of(context).primaryColorLight,
                    itemBuilder:
                        (popupContext) => [
                          PopupMenuItem(
                            onTap: () {
                              Navigator.of(context).pushNamed(
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
                                  "featured": featured,
                                  "callback": (
                                    String new_name,
                                    DateTime new_date,
                                    String new_location,
                                    double new_latitude,
                                    double new_longitude,
                                    String new_image,
                                    String new_body,
                                    bool new_featured,
                                  ) {
                                    setState(() {
                                      title = new_name;
                                      date = new_date;
                                      location = new_location;
                                      latitude = new_latitude;
                                      longitude = new_longitude;
                                      image = new_image;
                                      body = new_body;
                                      featured = new_featured;
                                    });
                                    callback();
                                  },
                                },
                              );
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
                              await post(
                                Uri.parse(baseUrl + "/delete-event/"),
                                body: {"event_id": event_id.toString()},
                              );
                              callback();
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
      body: RefreshIndicator(
        onRefresh: () async {},
        color: Theme.of(context).primaryColorLight,
        backgroundColor: Colors.white,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SingleChildScrollView(
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
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width * 0.3,
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 5),
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
                            ],
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
                                  .headlineLarge!
                                  .apply(fontWeightDelta: 3),
                            ),
                            SizedBox(height: 30),
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
                              style:
                                  Theme.of(context).typography.black.bodyLarge,
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
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextButton(
                onPressed: () {},
                child: Text(
                  "RSVP",
                  style: Theme.of(context).typography.white.labelLarge!.apply(
                    fontSizeDelta: 2,
                    fontWeightDelta: 3,
                  ),
                ),
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).primaryColorLight,
                  ),
                  fixedSize: WidgetStatePropertyAll(
                    Size(0.6 * MediaQuery.of(context).size.width, 50),
                  ),
                  elevation: WidgetStatePropertyAll(10),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Navigation(selected: 1),
    );
  }
}
